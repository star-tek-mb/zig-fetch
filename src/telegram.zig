const std = @import("std");
const http = @import("http.zig");
pub usingnamespace @import("telegram/types.zig");

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

    pub fn request(self: *Bot, method: []const u8, parameters: anytype) !http.Response {
        const T = @TypeOf(parameters);
        const info = @typeInfo(T);
        if (info != .Struct) {
            @compileError("send request accepts struct");
        }

        var formdata = http.FormData.init(self.allocator);
        defer formdata.deinit();

        inline for (info.Struct.fields) |field| {
            switch (@typeInfo(field.field_type)) {
                .Int, .ComptimeInt => {
                    var val = try std.fmt.allocPrint(self.allocator, "{}", .{@field(parameters, field.name)});
                    formdata.add(field.name, val);
                },
                .Pointer => |ptr_info| {
                    if (@typeInfo(ptr_info.child) == .Array and @typeInfo(ptr_info.child).Array.child == u8) {
                        var val = try self.allocator.dupe(u8, @field(parameters, field.name));
                        formdata.add(field.name, val);
                    }
                },
                else => {},
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
        return response;
    }
};
