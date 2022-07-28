const std = @import("std");
const uri = @import("uri.zig");
const tls = @import("tls.zig");

pub const Method = std.http.Method;
pub const Status = std.http.Status;

pub const Header = struct { key: []const u8, val: []const u8 };

const Request = struct {
    method: Method = .GET,
    path: []const u8 = "/",
    headers: []const Header = .{},
    body: ?[]const u8 = null,

    pub fn toString(self: *Request, allocator: std.mem.Allocator) ![]u8 {
        var buf = std.ArrayList(u8).init(allocator);
        const writer = buf.writer();
        try writer.print("{s} {s} HTTP/1.1\r\n", .{ @tagName(self.method), self.path });
        for (self.headers) |header| {
            try writer.print("{s}: {s}\r\n", .{ header.key, header.val });
        }
        if (self.body) |body| {
            try writer.print("\r\n{s}", .{body});
        }
        try writer.print("\r\n", .{});
        return buf.toOwnedSlice();
    }
};

pub const Response = struct {
    allocator: std.mem.Allocator,
    status: Status,
    headers: []Header,
    body: []u8,

    pub fn close(self: *Response) void {
        for (self.headers) |header| {
            self.allocator.free(header.key);
            self.allocator.free(header.val);
        }
        self.allocator.free(self.headers);
        self.allocator.free(self.body);
    }
};

pub const FetchOptions = struct {
    allocator: std.mem.Allocator,
    method: Method = .GET,
    headers: []const Header = &[_]Header{},
    body: ?[]const u8 = null
};

pub fn fetch(url: []const u8, options: FetchOptions) !Response {
    var allocator = options.allocator;
    var uri_comps = try uri.parse(url);
    uri_comps.scheme = if (uri_comps.scheme) |scheme| scheme else "https";
    uri_comps.port = if (std.mem.eql(u8, uri_comps.scheme.?, "https")) 443 else 80;

    if (options.body != null and !options.method.requestHasBody()) {
        return error.BodyNotAllowed;
    }

    var content_length: []u8 = undefined;
    var request_headers = std.ArrayList(Header).init(allocator);
    try request_headers.appendSlice(options.headers);
    try request_headers.append(.{ .key = "Host", .val = uri_comps.host.? });
    try request_headers.append(.{ .key = "Connection", .val = "close" });
    try request_headers.append(.{ .key = "User-Agent", .val = "zig-fetch" });
    if (options.body) |body| {
        content_length = try std.fmt.allocPrint(allocator, "{}", .{body.len});
        try request_headers.append(.{ .key = "Content-Length", .val = content_length });
    }
    defer request_headers.deinit();
    defer if (options.body != null) allocator.free(content_length);

    var request = Request{ 
        .method = options.method,
        .headers = request_headers.items,
        .path = if (uri_comps.path.len == 0) "/" else uri_comps.path,
        .body = options.body
    };

    var stream = try std.net.tcpConnectToHost(allocator, uri_comps.host.?, uri_comps.port.?);
    defer stream.close();

    if (uri_comps.port.? == 443) {
        var tls_stream = try tls.Stream.init(allocator);
        defer tls_stream.deinit();
        try tls_stream.wrap(stream);
        try tls_stream.set_hostname(uri_comps.host.?);
        try tls_stream.handshake();

        var client = HTTPSClient.init(allocator, tls_stream);
        return try client.request(&request);
    } else {
        var client = HTTPClient.init(allocator, stream);
        return try client.request(&request);
    }
}

pub const HTTPClient = Client(std.net.Stream);
pub const HTTPSClient = Client(*tls.Stream);

fn Client(comptime StreamType: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        stream: StreamType,

        pub fn init(allocator: std.mem.Allocator, stream: StreamType) Self {
            return .{ .allocator = allocator, .stream = stream };
        }

        pub fn request(self: *Self, req: *Request) !Response {
            var response = std.ArrayList(u8).init(self.allocator);
            const writer = self.stream.writer();
            const reader = self.stream.reader();

            var request_string = try req.toString(self.allocator);
            defer self.allocator.free(request_string);
            try writer.writeAll(request_string);

            var line_buffer: [5 * 1024]u8 = undefined; // at least 1024 for key and 4096 for value (cookie size)
            var content_length: u32 = 0;
            var chunked = false;

            var line = try readLine(reader, &line_buffer);
            if (line.len < 12) { // HTTP/1.1 XXX"
                return error.BadResponse;
            }
            var status_code = try std.fmt.parseInt(u16, line[9..12], 10);
            var status = @intToEnum(Status, status_code);

            var headers = std.ArrayList(Header).init(self.allocator);
            line = try readLine(reader, &line_buffer);
            while (line.len > 0) : (line = try readLine(reader, &line_buffer)) {
                var key_end = std.mem.indexOf(u8, line, ":").?;
                var key = line[0..key_end];
                var val = std.mem.trimLeft(u8, line[key_end + 1 .. line.len], " ");

                try headers.append(.{ .key = try self.allocator.dupe(u8, key), .val = try self.allocator.dupe(u8, val) });

                if (std.mem.eql(u8, key, "Content-Length")) {
                    content_length = try std.fmt.parseInt(u32, val, 10);
                }
                if (std.mem.eql(u8, key, "Transfer-Encoding") and std.mem.eql(u8, val, "chunked")) {
                    chunked = true;
                }
            }

            if (chunked) {
                line = try readLine(reader, &line_buffer);
                while (line.len > 0) : (line = try readLine(reader, &line_buffer)) {
                    var chunk_length = try std.fmt.parseInt(u32, line, 16);
                    if (chunk_length == 0) {
                        try reader.skipBytes(2, .{});
                        break;
                    }
                    try response.resize(response.items.len + chunk_length);
                    _ = try reader.readAll(response.items[response.items.len - chunk_length .. response.items.len]);
                    try reader.skipBytes(2, .{});
                }
            } else {
                try response.resize(content_length);
                _ = try reader.readAll(response.items);
                response.shrinkAndFree(content_length);
            }

            return Response{ .allocator = self.allocator, .status = status, .headers = headers.toOwnedSlice(), .body = response.toOwnedSlice() };
        }
    };
}

fn readLine(self: anytype, buf: []u8) ![]u8 {
    var index: usize = 0;
    while (true) {
        if (index >= buf.len) return error.StreamTooLong;
        const byte = try self.readByte();
        buf[index] = byte;
        if (byte == '\r') {
            const nextByte = try self.readByte();
            if (nextByte == '\n') {
                return buf[0..index];
            }
            index += 1;
        }
        index += 1;
    }
}
