const std = @import("std");
const http = @import("http.zig");

pub const FormBlob = struct {
    filename: []const u8,
    content: []const u8
};

pub const FormParameterValue = union(enum) {
    string: []const u8,
    file: []const u8,
    blob: FormBlob
};

pub const FormParameter = struct {
    key: []const u8,
    val: FormParameterValue
};

pub const FormData = struct {
    allocator: std.mem.Allocator,
    boundary: u32,
    parameters: std.ArrayList(FormParameter),
    body: std.ArrayList(u8),
    header: http.Header,

    pub fn init(allocator: std.mem.Allocator) FormData {
        var randomGenerator = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp()));
        var boundary = randomGenerator.random().intRangeAtMost(u32, 10000000, 99999999);
        var boundary_string = std.fmt.allocPrint(allocator, "multipart/form-data; boundary=fetch{}", .{boundary}) catch unreachable;
        var header = http.Header{ .key = "Content-Type", .val = boundary_string};
        return .{
            .allocator = allocator,
            .boundary = boundary,
            .parameters = std.ArrayList(FormParameter).init(allocator),
            .body = std.ArrayList(u8).init(allocator),
            .header = header
        };
    }

    pub fn deinit(self: *FormData) void {
        self.allocator.free(self.header.val);
        self.parameters.clearAndFree();
        self.body.clearAndFree();
    }

    pub fn add(self: *FormData, key: []const u8, val: []const u8) void {
        self.parameters.append(.{.key = key, .val = .{ .string = val }}) catch unreachable;
    }

    pub fn addFile(self: *FormData, key: []const u8, path: []const u8) void {
        self.parameters.append(.{.key = key, .val = .{ .file = path }}) catch unreachable;
    }

    pub fn addBlob(self: *FormData, key: []const u8, content: []const u8, filename: []const u8) void {
        self.parameters.append(.{ .key = key, .val = .{ .blob = .{ .filename = filename, .content = content } }}) catch unreachable;
    }

    pub fn contentType(self: *FormData) http.Header {
        return self.header;
    }

    pub fn toString(self: *FormData) ![]u8 {
        self.body.clearRetainingCapacity();
        const writer = self.body.writer();

        for (self.parameters.items) |parameter| {
            try writer.print("--fetch{}\r\n", .{ self.boundary });
            switch (parameter.val) {
                .string => try writer.print("Content-Disposition: form-data; name=\"{s}\"\r\n\r\n{s}\r\n", .{ parameter.key, parameter.val.string }),
                .file => {
                    try writer.print("Content-Disposition: form-data; name=\"{s}\"; filename=\"{s}\"\r\nContent-Type: {s}\r\n\r\n",
                        .{ parameter.key, std.fs.path.basename(parameter.val.file), "application/octet-stream" });

                    var file = try std.fs.cwd().openFile(parameter.val.file, .{});
                    defer file.close();

                    var copy_buf : [4096]u8 = undefined;
                    var readed = try file.readAll(&copy_buf);
                    while (readed != 0) : (readed = try file.readAll(&copy_buf)) {
                        try writer.writeAll(copy_buf[0..readed]);
                    }
                    try writer.print("\r\n", .{});
                },
                .blob => {
                    try writer.print("Content-Disposition: form-data; name=\"{s}\"; filename=\"{s}\"\r\nContent-Type: {s}\r\n\r\n",
                        .{ parameter.key, parameter.val.blob.filename, "application/octet-stream" });
                    try writer.writeAll(parameter.val.blob.content);
                    try writer.print("\r\n", .{});
                }
            }
        }
        try writer.print("\r\n--fetch{}--\r\n", .{ self.boundary });
        return self.body.items;
    }
};