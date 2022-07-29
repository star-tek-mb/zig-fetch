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

    var formData = web.FormData.init(allocator);
    defer formData.deinit();

    formData.add("chat_id", "116797709");
    formData.addBlob("document", @embedFile("cacert.pem"), "cacert.pem");

    var response = try web.fetch("https://api.telegram.org/bot[TOKEN REDACTED]/sendDocument", .{
        .allocator = allocator,
        .method = .POST,
        .headers = &[_]web.Header{formData.contentType()},
        .body = try formData.toString()
    });
    defer response.close();

    try std.io.getStdOut().writer().print("{s}\n", .{response.body});
}
