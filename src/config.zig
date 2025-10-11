const std = @import("std");
const ascii = @import("ascii.zig");
const utils = @import("utils.zig");

pub const Module = struct {
    type: []u8,
    key: []u8,
    key_color: []u8,
};

pub const Config = struct {
    ascii_abs_path: ?[]u8 = null,
    username_hostname_color: ?[]u8 = null,
    modules: []Module,
};

pub const ModuleType = enum {
    os,
    kernel,
    uptime,
    packages,
    shell,
    cpu,
    gpu,
    ram,
    swap,
    disk,
    net,
    wm,
    terminal,
    locale,
    custom,
};

pub fn getAsciiPath(config: ?std.json.Parsed(Config)) ?[]u8 {
    if (config) |c| {
        return c.value.ascii_abs_path;
    } else return null;
}

pub fn getUsernameHostnameColor(config: ?std.json.Parsed(Config)) ?[]u8 {
    if (config) |c| {
        return c.value.username_hostname_color;
    } else return null;
}

pub fn getModulesTypes(allocator: std.mem.Allocator, config: ?std.json.Parsed(Config)) !std.array_list.Managed(ModuleType) {
    var modules_list = std.array_list.Managed(ModuleType).init(allocator);

    if (config) |c| {
        for (c.value.modules) |module| {
            const module_enum = std.meta.stringToEnum(ModuleType, module.type);
            if (module_enum) |m| {
                try modules_list.append(m);
            } else {
                modules_list.deinit();
                return error.InvalidModule;
            }
        }
    }

    return modules_list;
}

pub fn readConfigFile(allocator: std.mem.Allocator) !?std.json.Parsed(Config) {
    const home = try std.process.getEnvVarOwned(allocator, "HOME");
    defer allocator.free(home);

    const config_abs_path = try std.mem.concat(allocator, u8, &.{ home, "/.config/zigfetch/config.json" });
    defer allocator.free(config_abs_path);

    const config_file = std.fs.openFileAbsolute(config_abs_path, .{ .mode = .read_only }) catch |err| switch (err) {
        error.FileNotFound => return null,
        else => return err,
    };
    defer config_file.close();

    const file_size = (try config_file.stat()).size;

    const config_data = try utils.readFile(allocator, config_file, file_size);
    defer allocator.free(config_data);

    return try std.json.parseFromSlice(Config, allocator, config_data, .{ .allocate = .alloc_always });
}
