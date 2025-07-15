const std = @import("std");
const builtin = @import("builtin");
const ascii = @import("ascii.zig");

pub const Module = struct {
    type: []u8,
    key: []u8,
    key_color: []u8,
};

pub const Config = struct {
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
    terminal,
    locale,
};

pub fn getModulesTypes(allocator: std.mem.Allocator, config: ?std.json.Parsed(Config)) !std.ArrayList(ModuleType) {
    var modules_list = std.ArrayList(ModuleType).init(allocator);

    if (config) |c| {
        for (c.value.modules) |module| {
            const module_enum = std.meta.stringToEnum(ModuleType, module.type);
            if (module_enum) |m| {
                try modules_list.append(m);
            } else {
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

    const file = std.fs.openFileAbsolute(config_abs_path, .{ .mode = .read_only }) catch |err| switch (err) {
        error.FileNotFound => return null,
        else => return err,
    };
    defer file.close();

    const data = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(data);

    return try std.json.parseFromSlice(Config, allocator, data, .{ .allocate = .alloc_always });
}
