const builtin = @import("builtin");
const std = @import("std");
const telegram = @import("telegram.zig");


pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    var bot = telegram.Bot.init(.{
        .allocator = allocator,
        .token = "[REDACTED]"
    });
    // var response = try bot.sendPhoto(.{
    //     .chat_id = 116797709,
    //     .photo = telegram.types.UploadFile{ .blob = .{ .filename = "fake.jpg", .content = @embedFile("fake.jpg") } },
    //     .reply_to_message_id = 5934
    // });
    // var response = try bot.sendMessage(.{
    //     .chat_id = 116797709,
    //     .text = "No <b>AHAHA</b> HA <i>HAH</i>",
    //     .parse_mode = "HTML"
    // });
    var response = try bot.getMe();
    defer bot.release(response);

    try std.io.getStdOut().writer().print("{s}\n", .{response});
}
