const std = @import("std");

pub const ID = union(enum) {
    integer: i64,
    string: []const u8
};

pub const UploadFile = union(enum) {
    filepath: []const u8,
    blob: struct {
        filename: []const u8,
        content: []const u8   
    }
};

pub fn APIResponse(comptime T: type) type {
    return struct {
        ok: bool,
        result: ?*T = null,
        error_code: u16,
        description: ?[]const u8
    };
}

pub const User = struct {
    id: i64,
    is_bot: bool,
    first_name: []const u8,
    last_name: ?[]const u8,
    username: ?[]const u8,
    language_code: ?[]const u8,
    is_premium: ?bool,
    added_to_attachment_menu: ?bool,
    can_join_groups: ?bool,
    can_read_all_group_messages: ?bool,
    supports_inline_queries: ?bool
};

pub const ChatType = enum {
    private,
    group,
    supergroup,
    channel
};

pub const Chat = struct {
    id: i64,
    @"type": ChatType,
    title: ?[]const u8,
    username: ?[]const u8,
    first_name: ?[]const u8,
    last_name: ?[]const u8,
    // TODO: fill more
};

pub const Message = struct {
    message_id: i64,
    from: ?*User = null,
    sender_chat: ?*Chat = null,
    date: u64,
    chat: *Chat,
    forward_from: ?*User = null,
    forward_from_chat: ?*Chat = null,
    forward_from_message_id: ?i64,
    forward_signature: ?[]const u8,
    forward_sender_name: ?[]const u8,
    forward_date: ?u64,
    is_automatic_forward: ?bool,
    reply_to_message: ?*Message = null,
    via_bot: ?*User = null,
    edit_date: ?u64,
    has_protected_content: ?bool,
    media_group_id: ?[]const u8,
    author_signature: ?[]const u8,
    text: ?[]const u8,
    // TODO: fill more
};
