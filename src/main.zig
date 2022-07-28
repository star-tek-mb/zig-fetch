const builtin = @import("builtin");
const std = @import("std");
const web = @import("web.zig");


pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    if (builtin.os.tag == .windows) {
        _ = try std.os.windows.WSAStartup(2, 2);
    }

    var response = try web.fetch("https://ziglang.org", .{
        .allocator = allocator
    });
    defer response.close();

    try std.io.getStdOut().writer().print("{s}\n", .{response.body});
}
