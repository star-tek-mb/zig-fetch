const builtin = @import("builtin");
const std = @import("std");
const telegram = @import("telegram.zig");


pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var bot = telegram.Bot.init(.{
        .allocator = allocator,
        .token = "[TOKEN]"
    });
    var response = try bot.request("sendMessage", .{
        .chat_id = 116797709,
        .text = "Hello world"
    });
    defer response.close();

    try std.io.getStdOut().writer().print("{s}\n", .{response.body});
}
