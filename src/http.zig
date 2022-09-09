const std = @import("std");
const uri = @import("uri.zig");
const tls = @import("tls.zig");
pub usingnamespace @import("form.zig");

pub const Method = enum {
    GET,
    HEAD,
    POST,
    PUT,
    DELETE,
    CONNECT,
    OPTIONS,
    TRACE,
    PATCH,

    /// Returns true if a request of this method is allowed to have a body
    /// Actual behavior from servers may vary and should still be checked
    pub fn requestHasBody(self: Method) bool {
        return switch (self) {
            .POST, .PUT, .PATCH => true,
            .GET, .HEAD, .DELETE, .CONNECT, .OPTIONS, .TRACE => false,
        };
    }

    /// Returns true if a response to this method is allowed to have a body
    /// Actual behavior from clients may vary and should still be checked
    pub fn responseHasBody(self: Method) bool {
        return switch (self) {
            .GET, .POST, .DELETE, .CONNECT, .OPTIONS, .PATCH => true,
            .HEAD, .PUT, .TRACE => false,
        };
    }

    /// An HTTP method is safe if it doesn't alter the state of the server.
    /// https://developer.mozilla.org/en-US/docs/Glossary/Safe/HTTP
    /// https://datatracker.ietf.org/doc/html/rfc7231#section-4.2.1
    pub fn safe(self: Method) bool {
        return switch (self) {
            .GET, .HEAD, .OPTIONS, .TRACE => true,
            .POST, .PUT, .DELETE, .CONNECT, .PATCH => false,
        };
    }

    /// An HTTP method is idempotent if an identical request can be made once or several times in a row with the same effect while leaving the server in the same state.
    /// https://developer.mozilla.org/en-US/docs/Glossary/Idempotent
    /// https://datatracker.ietf.org/doc/html/rfc7231#section-4.2.2
    pub fn idempotent(self: Method) bool {
        return switch (self) {
            .GET, .HEAD, .PUT, .DELETE, .OPTIONS, .TRACE => true,
            .CONNECT, .POST, .PATCH => false,
        };
    }

    /// A cacheable response is an HTTP response that can be cached, that is stored to be retrieved and used later, saving a new request to the server.
    /// https://developer.mozilla.org/en-US/docs/Glossary/cacheable
    /// https://datatracker.ietf.org/doc/html/rfc7231#section-4.2.3
    pub fn cacheable(self: Method) bool {
        return switch (self) {
            .GET, .HEAD => true,
            .POST, .PUT, .DELETE, .CONNECT, .OPTIONS, .TRACE, .PATCH => false,
        };
    }
};


pub const Status = enum(u10) {
    @"continue" = 100, // RFC7231, Section 6.2.1
    switching_protcols = 101, // RFC7231, Section 6.2.2
    processing = 102, // RFC2518
    early_hints = 103, // RFC8297

    ok = 200, // RFC7231, Section 6.3.1
    created = 201, // RFC7231, Section 6.3.2
    accepted = 202, // RFC7231, Section 6.3.3
    non_authoritative_info = 203, // RFC7231, Section 6.3.4
    no_content = 204, // RFC7231, Section 6.3.5
    reset_content = 205, // RFC7231, Section 6.3.6
    partial_content = 206, // RFC7233, Section 4.1
    multi_status = 207, // RFC4918
    already_reported = 208, // RFC5842
    im_used = 226, // RFC3229

    multiple_choice = 300, // RFC7231, Section 6.4.1
    moved_permanently = 301, // RFC7231, Section 6.4.2
    found = 302, // RFC7231, Section 6.4.3
    see_other = 303, // RFC7231, Section 6.4.4
    not_modified = 304, // RFC7232, Section 4.1
    use_proxy = 305, // RFC7231, Section 6.4.5
    temporary_redirect = 307, // RFC7231, Section 6.4.7
    permanent_redirect = 308, // RFC7538

    bad_request = 400, // RFC7231, Section 6.5.1
    unauthorized = 401, // RFC7235, Section 3.1
    payment_required = 402, // RFC7231, Section 6.5.2
    forbidden = 403, // RFC7231, Section 6.5.3
    not_found = 404, // RFC7231, Section 6.5.4
    method_not_allowed = 405, // RFC7231, Section 6.5.5
    not_acceptable = 406, // RFC7231, Section 6.5.6
    proxy_auth_required = 407, // RFC7235, Section 3.2
    request_timeout = 408, // RFC7231, Section 6.5.7
    conflict = 409, // RFC7231, Section 6.5.8
    gone = 410, // RFC7231, Section 6.5.9
    length_required = 411, // RFC7231, Section 6.5.10
    precondition_failed = 412, // RFC7232, Section 4.2][RFC8144, Section 3.2
    payload_too_large = 413, // RFC7231, Section 6.5.11
    uri_too_long = 414, // RFC7231, Section 6.5.12
    unsupported_media_type = 415, // RFC7231, Section 6.5.13][RFC7694, Section 3
    range_not_satisfiable = 416, // RFC7233, Section 4.4
    expectation_failed = 417, // RFC7231, Section 6.5.14
    teapot = 418, // RFC 7168, 2.3.3
    misdirected_request = 421, // RFC7540, Section 9.1.2
    unprocessable_entity = 422, // RFC4918
    locked = 423, // RFC4918
    failed_dependency = 424, // RFC4918
    too_early = 425, // RFC8470
    upgrade_required = 426, // RFC7231, Section 6.5.15
    precondition_required = 428, // RFC6585
    too_many_requests = 429, // RFC6585
    header_fields_too_large = 431, // RFC6585
    unavailable_for_legal_reasons = 451, // RFC7725

    internal_server_error = 500, // RFC7231, Section 6.6.1
    not_implemented = 501, // RFC7231, Section 6.6.2
    bad_gateway = 502, // RFC7231, Section 6.6.3
    service_unavailable = 503, // RFC7231, Section 6.6.4
    gateway_timeout = 504, // RFC7231, Section 6.6.5
    http_version_not_supported = 505, // RFC7231, Section 6.6.6
    variant_also_negotiates = 506, // RFC2295
    insufficient_storage = 507, // RFC4918
    loop_detected = 508, // RFC5842
    not_extended = 510, // RFC2774
    network_authentication_required = 511, // RFC6585

    _,

    pub fn phrase(self: Status) ?[]const u8 {
        return switch (self) {
            // 1xx statuses
            .@"continue" => "Continue",
            .switching_protcols => "Switching Protocols",
            .processing => "Processing",
            .early_hints => "Early Hints",

            // 2xx statuses
            .ok => "OK",
            .created => "Created",
            .accepted => "Accepted",
            .non_authoritative_info => "Non-Authoritative Information",
            .no_content => "No Content",
            .reset_content => "Reset Content",
            .partial_content => "Partial Content",
            .multi_status => "Multi-Status",
            .already_reported => "Already Reported",
            .im_used => "IM Used",

            // 3xx statuses
            .multiple_choice => "Multiple Choice",
            .moved_permanently => "Moved Permanently",
            .found => "Found",
            .see_other => "See Other",
            .not_modified => "Not Modified",
            .use_proxy => "Use Proxy",
            .temporary_redirect => "Temporary Redirect",
            .permanent_redirect => "Permanent Redirect",

            // 4xx statuses
            .bad_request => "Bad Request",
            .unauthorized => "Unauthorized",
            .payment_required => "Payment Required",
            .forbidden => "Forbidden",
            .not_found => "Not Found",
            .method_not_allowed => "Method Not Allowed",
            .not_acceptable => "Not Acceptable",
            .proxy_auth_required => "Proxy Authentication Required",
            .request_timeout => "Request Timeout",
            .conflict => "Conflict",
            .gone => "Gone",
            .length_required => "Length Required",
            .precondition_failed => "Precondition Failed",
            .payload_too_large => "Payload Too Large",
            .uri_too_long => "URI Too Long",
            .unsupported_media_type => "Unsupported Media Type",
            .range_not_satisfiable => "Range Not Satisfiable",
            .expectation_failed => "Expectation Failed",
            .teapot => "I'm a teapot",
            .misdirected_request => "Misdirected Request",
            .unprocessable_entity => "Unprocessable Entity",
            .locked => "Locked",
            .failed_dependency => "Failed Dependency",
            .too_early => "Too Early",
            .upgrade_required => "Upgrade Required",
            .precondition_required => "Precondition Required",
            .too_many_requests => "Too Many Requests",
            .header_fields_too_large => "Request Header Fields Too Large",
            .unavailable_for_legal_reasons => "Unavailable For Legal Reasons",

            // 5xx statuses
            .internal_server_error => "Internal Server Error",
            .not_implemented => "Not Implemented",
            .bad_gateway => "Bad Gateway",
            .service_unavailable => "Service Unavailable",
            .gateway_timeout => "Gateway Timeout",
            .http_version_not_supported => "HTTP Version Not Supported",
            .variant_also_negotiates => "Variant Also Negotiates",
            .insufficient_storage => "Insufficient Storage",
            .loop_detected => "Loop Detected",
            .not_extended => "Not Extended",
            .network_authentication_required => "Network Authentication Required",

            else => return null,
        };
    }

    pub const Class = enum {
        informational,
        success,
        redirect,
        client_error,
        server_error,
    };

    pub fn class(self: Status) ?Class {
        return switch (@enumToInt(self)) {
            100...199 => .informational,
            200...299 => .success,
            300...399 => .redirect,
            400...499 => .client_error,
            500...599 => .server_error,
            else => null,
        };
    }
};

pub const Header = struct { key: []const u8, val: []const u8 };

const Request = struct {
    method: Method = .GET,
    path: []const u8 = "/",
    headers: []const Header = &.{},
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
    body: ?[]const u8
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

    var path_enc = if (uri_comps.path.len == 0) "/" else uri_comps.path;

    if (uri_comps.query) |query| {
        var query_enc = try uri.escapeString(allocator, query);
        defer allocator.free(query_enc);
        path_enc = try std.mem.concat(allocator, u8, &[_][]const u8{path_enc, "?", query_enc});
    }
    defer if (uri_comps.query != null) allocator.free(path_enc);

    var request = Request{ 
        .method = options.method,
        .headers = request_headers.items,
        .path = path_enc,
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

const HTTPClient = Client(std.net.Stream);
const HTTPSClient = Client(*tls.Stream);

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
