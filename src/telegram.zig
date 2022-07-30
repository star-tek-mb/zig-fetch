const std = @import("std");
const json = @import("json.zig");
const http = @import("http.zig");
pub const types = @import("telegram/types.zig");

pub const BotOptions = struct {
    allocator: std.mem.Allocator,
    token: []const u8
};

pub const Bot = struct {
    allocator: std.mem.Allocator,
    token: []const u8,

    pub fn init(options: BotOptions) Bot {
        return Bot{
            .allocator = options.allocator,
            .token = options.token
        };
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
                    if (@typeInfo(ptr_info.child) == .Array and @typeInfo(ptr_info.child).Array.child == u8) {
                        var val = try self.allocator.dupe(u8, @field(parameters, field.name));
                        formdata.add(field.name, val);
                    }
                },
                .Union => {
                    const val = @field(parameters, field.name);
                    if (@TypeOf(val) == types.UploadFile) {
                        const uploadType = std.meta.activeTag(val);
                        if (uploadType == types.UploadFile.blob) {
                            formdata.addBlob(field.name, val.blob.content, val.blob.filename);
                        } else if (uploadType == types.UploadFile.filepath) {
                            formdata.addFile(field.name, val.filepath);
                        }
                    }
                },
                else => {}
            }
        }

        defer {
            for (formdata.parameters.items) |parameter| {
                switch (parameter.val) {
                    .string => self.allocator.free(parameter.val.string),
                    else => {}
                }
            }
        }

        var url = try std.fmt.allocPrint(self.allocator, "https://api.telegram.org/bot{s}/{s}", .{self.token, method});
        defer self.allocator.free(url);
        var response = try http.fetch(url, .{
            .allocator = self.allocator,
            .method = .POST,
            .headers = &[_]http.Header{formdata.contentType()},
            .body = try formdata.toString()
        });
        defer response.close();

        @setEvalBranchQuota(2000000);
        var json_stream = json.TokenStream.init(response.body);
        var ret = try json.parse(types.APIResponse(T), &json_stream, .{
            .allocator = self.allocator,
            .ignore_unknown_fields = true
        });
        errdefer json.parseFree(types.APIResponse(T), ret, .{
            .allocator = self.allocator,
            .ignore_unknown_fields = true
        });

        if (!ret.ok) {
            std.log.debug("error_code: {}, description {s}", .{ret.error_code, ret.description});
            return error.ApiError;
        }

        return ret;
    }

    pub fn sendMessage(self: *Bot, parameters: anytype) !*types.Message {
        return (try self.request("sendMessage", parameters, types.Message)).result.?;
    }

    pub fn sendPhoto(self: *Bot, parameters: anytype) !*types.Message {
        return (try self.request("sendPhoto", parameters, types.Message)).result.?;
    }

    pub fn release(self: *Bot, pointer: anytype) void {
        var response = @fieldParentPtr(types.APIResponse(@TypeOf(pointer.*)), "result", &@ptrCast(?@TypeOf(pointer), pointer));
        json.parseFree(types.APIResponse(@TypeOf(pointer.*)), response.*, .{
            .allocator = self.allocator,
            .ignore_unknown_fields = true
        });
    }
};
