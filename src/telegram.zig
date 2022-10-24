const std = @import("std");
const json = @import("json.zig");
const http = @import("http.zig");
pub const types = @import("telegram/types.zig");

pub const BotOptions = struct {
    allocator: std.mem.Allocator,
    token: []const u8,
};

pub const Bot = struct {
    allocator: std.mem.Allocator,
    token: []const u8,

    pub fn init(options: BotOptions) Bot {
        return Bot{ .allocator = options.allocator, .token = options.token };
    }

    pub fn request(self: *Bot, method: []const u8, parameters: anytype, comptime T: type) !types.APIResponse(T) {
        const type_info = @typeInfo(@TypeOf(parameters));
        if (type_info != .Struct) @compileError("send request accepts struct");

        var formdata = http.FormData.init(self.allocator);
        defer formdata.deinit();

        inline for (type_info.Struct.fields) |field| {
            switch (@typeInfo(field.field_type)) {
                .Int, .ComptimeInt, .Float, .ComptimeFloat => {
                    var val = try std.fmt.allocPrint(self.allocator, "{}", .{@field(parameters, field.name)});
                    formdata.add(field.name, val);
                },
                .Pointer => |ptr_info| {
                    if (ptr_info.size == .Slice and ptr_info.child == u8) {
                        var val = try self.allocator.dupe(u8, @field(parameters, field.name));
                        formdata.add(field.name, val);
                    }
                },
                .Union => {
                    const val = @field(parameters, field.name);
                    switch (val) {
                        .blob => {
                            formdata.addBlob(field.name, val.blob.content, val.blob.filename);
                        },
                        .filepath => {
                            formdata.addFile(field.name, val.filepath);
                        },
                    }
                },
                else => {},
            }
        }

        defer {
            for (formdata.parameters.items) |parameter| {
                switch (parameter.val) {
                    .string => self.allocator.free(parameter.val.string),
                    else => {},
                }
            }
        }

        var url = try std.fmt.allocPrint(self.allocator, "https://api.telegram.org/bot{s}/{s}", .{ self.token, method });
        defer self.allocator.free(url);
        var response = try http.fetch(url, .{
            .allocator = self.allocator,
            .method = .POST,
            .headers = &[_]http.Header{formdata.contentType()},
            .body = try formdata.toString(),
        });
        defer response.close();

        @setEvalBranchQuota(2000000);
        var json_stream = json.TokenStream.init(response.body);
        var ret = try json.parse(types.APIResponse(T), &json_stream, .{
            .allocator = self.allocator,
            .ignore_unknown_fields = true,
        });
        errdefer json.parseFree(types.APIResponse(T), ret, .{
            .allocator = self.allocator,
            .ignore_unknown_fields = true,
        });
        try std.io.getStdOut().writer().print("{any}\n", .{parameters});
        try std.io.getStdOut().writer().print("{?s}\n", .{ret.description});
        if (!ret.ok) {
            return error.ApiError;
        }

        return ret;
    }

    pub fn getUpdates(self: *Bot, parameters: anytype) ![]types.Update {
        return (try self.request("getUpdates", parameters, []types.Update)).result.?;
    }

    pub fn getMe(self: *Bot) !types.User {
        return (try self.request("getMe", .{}, types.User)).result.?;
    }

    pub fn logOut(self: *Bot) !bool {
        return (try self.request("logOut", .{}, bool)).result.?;
    }

    pub fn close(self: *Bot) !bool {
        return (try self.request("close", .{}, bool)).result.?;
    }

    pub fn sendMessage(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("sendMessage", parameters, types.Message)).result.?;
    }

    pub fn forwardMessage(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("forwardMessage", parameters, types.Message)).result.?;
    }

    pub fn copyMessage(self: *Bot, parameters: anytype) !types.MessageId {
        return (try self.request("copyMessage", parameters, types.MessageId)).result.?;
    }

    pub fn sendPhoto(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("sendPhoto", parameters, types.Message)).result.?;
    }

    pub fn sendAudio(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("sendAudio", parameters, types.Message)).result.?;
    }

    pub fn sendDocument(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("sendDocument", parameters, types.Message)).result.?;
    }

    pub fn sendVideo(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("sendVideo", parameters, types.Message)).result.?;
    }

    pub fn sendAnimation(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("sendAnimation", parameters, types.Message)).result.?;
    }

    pub fn sendVoice(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("sendVoice", parameters, types.Message)).result.?;
    }

    pub fn sendVideoNote(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("sendVideoNote", parameters, types.Message)).result.?;
    }

    // TODO: handle media array
    pub fn sendMediaGroup(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("sendMediaGroup", parameters, types.Message)).result.?;
    }

    pub fn sendLocation(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("sendLocation", parameters, types.Message)).result.?;
    }

    // TODO: handle Message or bool
    // On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned.
    pub fn editMessageLiveLocation(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("editMessageLiveLocation", parameters, types.Message)).result.?;
    }

    // TODO: handle Message or bool
    // On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned.
    pub fn stopMessageLiveLocation(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("stopMessageLiveLocation", parameters, types.Message)).result.?;
    }

    pub fn sendVenue(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("sendVenue", parameters, types.Message)).result.?;
    }

    pub fn sendContact(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("sendContact", parameters, types.Message)).result.?;
    }

    pub fn sendPoll(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("sendPoll", parameters, types.Message)).result.?;
    }

    pub fn sendDice(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("sendDice", parameters, types.Message)).result.?;
    }

    pub fn sendChatAction(self: *Bot, parameters: anytype) !types.Message {
        return (try self.request("sendChatAction", parameters, types.Message)).result.?;
    }

    pub fn getUserProfilePhotos(self: *Bot, parameters: anytype) !types.UserProfilePhotos {
        return (try self.request("getUserProfilePhotos", parameters, types.UserProfilePhotos)).result.?;
    }

    pub fn getFile(self: *Bot, parameters: anytype) !types.File {
        return (try self.request("getFile", parameters, types.File)).result.?;
    }

    pub fn banChatMember(self: *Bot, parameters: anytype) !bool {
        return (try self.request("banChatMember", parameters, bool)).result.?;
    }

    pub fn unbanChatMember(self: *Bot, parameters: anytype) !bool {
        return (try self.request("unbanChatMember", parameters, bool)).result.?;
    }

    pub fn restrictChatMember(self: *Bot, parameters: anytype) !bool {
        return (try self.request("restrictChatMember", parameters, bool)).result.?;
    }

    pub fn promoteChatMember(self: *Bot, parameters: anytype) !bool {
        return (try self.request("promoteChatMember", parameters, bool)).result.?;
    }

    pub fn setChatAdministratorCustomTitle(self: *Bot, parameters: anytype) !bool {
        return (try self.request("setChatAdministratorCustomTitle", parameters, bool)).result.?;
    }

    pub fn banChatSenderChat(self: *Bot, parameters: anytype) !bool {
        return (try self.request("banChatSenderChat", parameters, bool)).result.?;
    }

    pub fn unbanChatSenderChat(self: *Bot, parameters: anytype) !bool {
        return (try self.request("unbanChatSenderChat", parameters, bool)).result.?;
    }

    pub fn setChatPermissions(self: *Bot, parameters: anytype) !bool {
        return (try self.request("setChatPermissions", parameters, bool)).result.?;
    }

    // TODO: is it working?
    pub fn exportChatInviteLink(self: *Bot, parameters: anytype) ![]const u8 {
        return (try self.request("exportChatInviteLink", parameters, []const u8)).result.?;
    }

    pub fn createChatInviteLink(self: *Bot, parameters: anytype) !types.ChatInviteLink {
        return (try self.request("createChatInviteLink", parameters, types.ChatInviteLink)).result.?;
    }

    pub fn release(self: *Bot, data: anytype) void {
        json.parseFree(@TypeOf(data), data, .{
            .allocator = self.allocator,
            .ignore_unknown_fields = true,
        });
    }
};
