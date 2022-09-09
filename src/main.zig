const builtin = @import("builtin");
const std = @import("std");
const telegram = @import("telegram.zig");

pub fn processUpdate(bot: *telegram.Bot, update: *telegram.types.Update) !void {
    if (update.message) |message| {
        _ = try bot.sendMessage(.{ .chat_id = message.chat.id, .text = message.text.? });
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    var bot = telegram.Bot.init(.{ .allocator = allocator, .token = "" });
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
    var offset: i64 = 0;
    while (true) {
        var updates = try bot.getUpdates(.{ .offset = offset });
        defer bot.release(updates);
        for (updates) |*update| {
            try processUpdate(&bot, update);
        }
        try std.io.getStdOut().writer().print("{any}\n", .{updates});
        if (updates.len > 0) {
            offset = updates[updates.len - 1].update_id + 1;
        }
    }
}
