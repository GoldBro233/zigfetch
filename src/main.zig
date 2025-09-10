const std = @import("std");
const builtin = @import("builtin");
const detection = @import("detection.zig").os_module;
const ascii = @import("ascii.zig");
const config = @import("config.zig");
const formatters = @import("formatters.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var sys_info_list = std.array_list.Managed([]u8).init(allocator);
    defer sys_info_list.deinit();

    errdefer {
        for (sys_info_list.items) |info| {
            allocator.free(info);
        }
    }

    const conf = try config.readConfigFile(allocator);
    defer if (conf) |c| c.deinit();

    const modules_types = try config.getModulesTypes(allocator, conf);
    defer modules_types.deinit();

    const username = try detection.user.getUsername(allocator);
    const hostname = try detection.system.getHostname(allocator);
    try sys_info_list.append(try std.fmt.allocPrint(allocator, "{s}{s}{s}@{s}{s}{s}", .{
        ascii.Yellow,
        username,
        ascii.Reset,
        ascii.Yellow,
        hostname,
        ascii.Reset,
    }));
    allocator.free(hostname);
    allocator.free(username);

    const separtor_buffer = try allocator.alloc(u8, username.len + hostname.len + 1);
    @memset(separtor_buffer, '-');
    try sys_info_list.append(separtor_buffer);

    if (modules_types.items.len == 0) {
        inline for (0..formatters.default_formatters.len) |i| {
            const result = try formatters.default_formatters[i](allocator);
            switch (result) {
                .string => |r| try sys_info_list.append(r),
                .string_arraylist => |r| {
                    defer r.deinit();
                    try sys_info_list.appendSlice(r.items);
                },
            }
        }
    } else if (conf) |c| {
        for (modules_types.items, c.value.modules) |module_type, module| {
            var buf: [32]u8 = undefined;
            const rgb = try ascii.hexColorToRgb(module.key_color);
            const key_color = try std.fmt.bufPrint(&buf, "\x1b[38;2;{d};{d};{d}m", .{ rgb.r, rgb.g, rgb.b });

            const result = try formatters.formatters[@intFromEnum(module_type)](allocator, module.key, key_color);
            switch (result) {
                .string => |r| try sys_info_list.append(r),
                .string_arraylist => |r| {
                    defer r.deinit();
                    try sys_info_list.appendSlice(r.items);
                },
            }
        }
    }

    try ascii.printAscii(allocator, config.getAsciiPath(conf), sys_info_list);
}
