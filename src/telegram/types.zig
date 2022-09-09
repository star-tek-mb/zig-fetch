// TODO: change void types
// add more types
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
        result: ?T,
        error_code: ?u16,
        description: ?[]const u8 = null
    };
}

pub const Update = struct {
    update_id: i64,
    message: ?*Message = null,
    edited_message: ?*Message = null,
    channel_post: ?*Message = null,
    edited_channel_post: ?*Message = null,
    //inline_query: ?void,
    //chosen_inline_result: ?void,
    callback_query: ?*CallbackQuery = null,
    //shipping_query: ?void
    //precheckout_query: ?void,
    poll: ?*Poll = null,
    poll_answer: ?*PollAnswer = null,
    my_chat_member: ?*ChatMemberUpdated = null,
    chat_member: ?*ChatMemberUpdated = null,
    chat_join_request: ?*ChatJoinRequest = null
};

pub const User = struct {
    id: i64,
    is_bot: bool,
    first_name: []const u8,
    last_name: ?[]const u8 = null,
    username: ?[]const u8 = null,
    language_code: ?[]const u8 = null,
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
    title: ?[]const u8 = null,
    username: ?[]const u8 = null,
    first_name: ?[]const u8 = null,
    last_name: ?[]const u8 = null,
    photo: ?*ChatPhoto = null,
    bio: ?[]const u8 = null,
    has_private_forwards: ?bool,
    join_to_send_messages: ?bool,
    join_by_request: ?bool,
    description: ?[]const u8 = null,
    invite_link: ?[]const u8 = null,
    pinned_message: ?*Message = null,
    permissions: ?*ChatPermissions = null,
    slow_mode_delay: ?u64,
    message_auto_delete_time: ?u64,
    has_protected_content: ?bool,
    sticker_set_name: ?[]const u8 = null,
    can_set_sticker_set: ?bool,
    linked_chat_id: ?i64,
    location: ?*ChatLocation = null
};

pub const Message = struct {
    message_id: i64,
    from: ?*User = null,
    sender_chat: ?*Chat = null,
    date: i64,
    chat: *Chat,
    forward_from: ?*User = null,
    forward_from_chat: ?*Chat = null,
    forward_from_message_id: ?i64,
    forward_signature: ?[]const u8 = null,
    forward_sender_name: ?[]const u8 = null,
    forward_date: ?i64,
    is_automatic_forward: ?bool,
    reply_to_message: ?*Message = null,
    via_bot: ?*User = null,
    edit_date: ?i64,
    has_protected_content: ?bool,
    media_group_id: ?[]const u8 = null,
    author_signature: ?[]const u8 = null,
    text: ?[]const u8 = null,
    entities: ?[]MessageEntity = null,
    animation: ?*Animation = null,
    audio: ?*Audio = null,
    document: ?*Document = null,
    photo: ?[]PhotoSize = null,
    //sticker: ?void,
    video: ?*Video = null,
    video_note: ?*VideoNote = null,
    voice: ?*Voice = null,
    caption: ?[]const u8 = null,
    caption_entities: ?[]MessageEntity = null,
    contact: ?*Contact = null,
    dice: ?*Dice = null,
    //game: ?void,
    poll: ?*Poll = null,
    venue: ?*Venue = null,
    location: ?*Location = null,
    new_chat_members: ?[]User = null,
    left_chat_member: ?*User = null,
    new_chat_title: ?[]const u8 = null,
    new_chat_photo: ?[]PhotoSize = null,
    delete_chat_photo: ?bool,
    group_chat_created: ?bool,
    supergroup_chat_created: ?bool,
    channel_chat_created: ?bool,
    message_auto_delete_timer_changed: ?*MessageAutoDeleteTimerChanged = null,
    migrate_to_chat_id: ?i64,
    migrate_from_chat_id: ?i64,
    pinned_message: ?*Message = null,
    //invoice: ?void,
    //successful_payment: ?void,
    connected_website: ?[]const u8 = null,
    //passport_data: ?void,
    proximity_alert_triggered: ?*ProximityAlertTriggered = null,
    video_chat_scheduled: ?*VideoChatScheduled = null,
    video_chat_started: ?*VideoChatStarted = null,
    video_chat_ended: ?*VideoChatEnded = null,
    video_chat_participants_invited: ?*VideoChatParticipantsInvited = null,
    web_app_data: ?*WebAppData = null,
    reply_markup: ?*InlineKeyboardMarkup = null
};

pub const MessageId = struct {
    message_id: i64
};

pub const MessageEntityType = enum {
    mention,
    hashtag,
    cashtag,
    bot_command,
    url,
    email,
    phone_number,
    bold,
    italic,
    underline,
    strikethrough,
    spoiler,
    code,
    pre,
    text_link,
    text_mention
};

pub const MessageEntity = struct {
    @"type": MessageEntityType,
    offset: usize,
    length: usize,
    url: ?[]const u8 = null,
    user: ?*User = null,
    language: ?[]const u8 = null
};

pub const PhotoSize = struct {
    file_id: []const u8,
    file_unique_id: []const u8,
    width: usize,
    height: usize,
    file_size: ?usize
};

pub const Animation = struct {
    file_id: []const u8,
    file_unique_id: []const u8,
    width: usize,
    height: usize,
    duration: usize,
    thumb: ?*PhotoSize = null,
    file_name: ?[]const u8 = null,
    mime_type: ?[]const u8 = null,
    file_size: ?usize
};

pub const Audio = struct {
    file_id: []const u8,
    file_unique_id: []const u8,
    duration: usize,
    performer: ?[]const u8 = null,
    title: ?[]const u8 = null,
    file_name: ?[]const u8 = null,
    mime_type: ?[]const u8 = null,
    file_size: ?usize,
    thumb: ?*PhotoSize = null,
};

pub const Document = struct {
    file_id: []const u8,
    file_unique_id: []const u8,
    thumb: ?*PhotoSize = null,
    file_name: ?[]const u8 = null,
    mime_type: ?[]const u8 = null,
    file_size: ?usize,
};

pub const Video = struct {
    file_id: []const u8,
    file_unique_id: []const u8,
    width: usize,
    height: usize,
    duration: usize,
    thumb: ?*PhotoSize = null,
    file_name: ?[]const u8 = null,
    mime_type: ?[]const u8 = null,
    file_size: ?usize
};

pub const VideoNote = struct {
    file_id: []const u8,
    file_unique_id: []const u8,
    length: usize,
    duration: usize,
    thumb: ?*PhotoSize = null,
    file_size: ?usize,
};

pub const Voice = struct {
    file_id: []const u8,
    file_unique_id: []const u8,
    duration: usize,
    mime_type: ?[]const u8 = null,
    file_size: ?usize
};

pub const Contact = struct {
    phone_number: []const u8,
    first_name: []const u8,
    last_name: ?[]const u8 = null,
    user_id: ?i64,
    vcard: []const u8
};

pub const Dice = struct {
    emoji: []const u8,
    value: u8
};

pub const PollOption = struct {
    text: []const u8,
    voter_count: usize
};

pub const PollAnswer = struct {
    poll_id: []const u8,
    user: *User,
    option_ids: []i64
};

pub const PollType = enum {
    regular,
    quiz
};

pub const Poll = struct {
    id: []const u8,
    question: []const u8,
    options: []PollOption,
    total_voter_count: usize,
    is_closed: bool,
    is_anonymous: bool,
    @"type": PollType,
    allows_multiple_answers: bool,
    correct_option_id: ?i64,
    explanation: ?[]const u8 = null,
    explanation_entities: ?[]MessageEntity = null,
    open_period: ?usize,
    close_date: ?i64
};

pub const Location = struct {
    longitude: f32,
    latitude: f32,
    horizontal_accuracy: ?f32,
    live_period: ?usize,
    heading: ?u16,
    proximity_alert_radius: ?usize
};

pub const Venue = struct {
    location: *Location,
    title: []const u8,
    address: []const u8,
    foursquare_id: ?[]const u8 = null,
    foursquare_type: ?[]const u8 = null,
    google_place_id: ?[]const u8 = null,
    google_place_type: ?[]const u8 = null
};

pub const WebAppData = struct {
    data: []const u8,
    button_text: []const u8
};

pub const ProximityAlertTriggered = struct {
    traveler: *User,
    watcher: *User,
    distance: usize
};

pub const MessageAutoDeleteTimerChanged = struct {
    message_auto_delete_time: usize
};

pub const VideoChatScheduled = struct {
    start_date: i64
};

pub const VideoChatStarted = struct {};

pub const VideoChatEnded = struct {
    duration: usize
};

pub const VideoChatParticipantsInvited = struct {
    users: []User
};

pub const UserProfilePhotos = struct {
    total_count: usize,
    photos: [][]PhotoSize
};

pub const File = struct {
    file_id: []const u8,
    file_unique_id: []const u8,
    file_size: ?usize,
    file_path: ?[]const u8 = null
};

pub const WebAppInfo = struct {
    url: []const u8
};

pub const ReplyKeyboardMarkup = struct {
    keyboard: [][]KeyboardButton,
    resize_keyboard: ?bool,
    one_time_keyboard: ?bool,
    input_field_placeholder: ?[]const u8 = null,
    selective: ?bool
};

pub const KeyboardButton = struct {
    text: []const u8,
    request_contact: ?bool,
    request_location: ?bool,
    request_poll: ?KeyboardButtonPollType,
    web_app: ?*WebAppInfo = null
};

pub const KeyboardButtonPollType = struct {
    @"type": ?PollType
};

pub const ReplyKeyboardRemove = struct {
    remove_keyboard: bool,
    selective: ?bool
};

pub const InlineKeyboardMarkup = struct {
    inline_keyboard: [][]InlineKeyboardButton
};

pub const InlineKeyboardButton = struct {
    text: []const u8,
    url: ?[]const u8 = null,
    callback_data: ?[]const u8 = null,
    web_app: ?*WebAppInfo = null,
    login_url: ?*LoginUrl = null,
    switch_inline_query: ?[]const u8 = null,
    switch_inline_query_current_chat: ?[]const u8 = null,
    //callback_game: ?void,
    pay: ?bool
};

pub const LoginUrl = struct {
    url: []const u8,
    forward_text: ?[]const u8 = null,
    bot_username: ?[]const u8 = null,
    request_write_access: ?bool
};

pub const CallbackQuery = struct {
    id: []const u8,
    from: *User,
    message: ?*Message = null,
    inline_message_id: ?[]const u8 = null,
    chat_instance: ?[]const u8 = null,
    data: ?[]const u8 = null,
    game_short_name: ?[]const u8 = null
};

pub const ForceReply = struct {
    force_reply: bool,
    input_field_placeholder: ?[]const u8 = null,
    selective: ?bool
};

pub const ChatPhoto = struct {
    small_file_id: []const u8,
    small_file_unique_id: []const u8,
    big_file_id: []const u8,
    big_file_unique_id: []const u8,
};

pub const ChatInviteLink = struct {
    invite_link: []const u8,
    creator: *User,
    creates_join_request: bool,
    is_primary: bool,
    is_revoked: bool,
    name: ?[]const u8 = null,
    expire_date: ?i64,
    member_limit: ?u32,
    pending_join_request_count: ?usize
};

pub const ChatAdministratorRights = struct {
    is_anonymous: bool,
    can_manage_chat: bool,
    can_delete_messages: bool,
    can_manage_video_chats: bool,
    can_restrict_members: bool,
    can_promote_members: bool,
    can_change_info: bool,
    can_invite_users: bool,
    can_post_messages: ?bool,
    can_edit_messages: ?bool,
    can_pin_messages: ?bool,
};

pub const ChatMemberType = enum {
    creator,
    administrator,
    member,
    restricted,
    left,
    banned
};

pub const ChatMember = union(ChatMemberType) {
    creator: *ChatMemberOwner,
    administrator: *ChatMemberAdministrator,
    member: *ChatMemberMember,
    restricted: *ChatMemberRestricted,
    left: *ChatMemberLeft,
    banned: *ChatMemberBanned
};

pub const ChatMemberOwner = struct {
    status: ChatMemberType,
    user: *User,
    is_anonymous: bool,
    custom_title: ?[]const u8 = null
};

pub const ChatMemberAdministrator = struct {
    status: ChatMemberType,
    user: *User,
    can_be_edited: bool,
    is_anonymous: bool,
    can_manage_chat: bool,
    can_delete_messages: bool,
    can_manage_video_chats: bool,
    can_restrict_members: bool,
    can_promote_members: bool,
    can_change_info: bool,
    can_invite_users: bool,
    can_post_messages: ?bool,
    can_edit_messages: ?bool,
    can_pin_messages: ?bool,
    custom_title: ?[]const u8 = null
};

pub const ChatMemberMember = struct {
    status: ChatMemberType,
    user: *User
};

pub const ChatMemberRestricted = struct {
    status: ChatMemberType,
    user: *User,
    is_member: bool,
    can_change_info: bool,
    can_invite_users: bool,
    can_pin_messages: bool,
    can_send_messages: bool,
    can_send_media_messages: bool,
    can_send_polls: bool,
    can_send_other_messages: bool,
    can_add_web_page_previews: bool,
    until_date: i64
};

pub const ChatMemberLeft = struct {
    status: ChatMemberType,
    user: *User
};

pub const ChatMemberBanned = struct {
    status: ChatMemberType,
    user: *User,
    until_date: i64
};

pub const ChatMemberUpdated = struct {
    chat: *Chat,
    from: *User,
    date: i64,
    old_chat_member: *ChatMember,
    new_chat_member: *ChatMember,
    invite_link: ?*ChatInviteLink = null
};

pub const ChatJoinRequest = struct {
    chat: *Chat,
    from: *User,
    date: i64,
    bio: ?[]const u8 = null,
    invite_link: ?*ChatInviteLink = null
};

pub const ChatPermissions = struct {
    can_send_messages: ?bool,
    can_send_media_messages: ?bool,
    can_send_polls: ?bool,
    can_send_other_messages: ?bool,
    can_add_web_page_previews: ?bool,
    can_change_info: ?bool,
    can_invite_users: ?bool,
    can_pin_messages: ?bool
};

pub const ChatLocation = struct {
    location: *Location,
    address: []const u8
};

// TODO
