const std = @import("std");
const display = @import("display.zig");
const utils = @import("utils.zig");

pub const Module = struct {
    type: []u8,
    key: []u8,
    key_color: []u8,
};

pub const Image = struct {
    abs_path: []const u8,
    height: ?u8 = null,
    width: ?u8 = null,
};

pub const Config = struct {
    ascii_abs_path: ?[]u8 = null,
    images: ?[]Image = null,
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

pub fn getImages(config: ?std.json.Parsed(Config)) ?[]Image {
    if (config) |c| {
        return c.value.images;
    } else return null;
}

pub fn getUsernameHostnameColor(config: ?std.json.Parsed(Config)) ?[]u8 {
    if (config) |c| {
        return c.value.username_hostname_color;
    } else return null;
}

pub fn getModulesTypes(gpa: std.mem.Allocator, config: ?std.json.Parsed(Config)) !std.array_list.Managed(ModuleType) {
    var modules_list = std.array_list.Managed(ModuleType).init(gpa);

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

pub fn readConfigFile(gpa: std.mem.Allocator, io: std.Io, environ: std.process.Environ) !?std.json.Parsed(Config) {
    const home = try std.process.Environ.getAlloc(environ, gpa, "HOME");
    defer gpa.free(home);

    const config_abs_path = try std.mem.concat(gpa, u8, &.{ home, "/.config/zigfetch/config.json" });
    defer gpa.free(config_abs_path);

    const config_file = std.Io.Dir.openFileAbsolute(io, config_abs_path, .{ .mode = .read_only }) catch |err| switch (err) {
        error.FileNotFound => return null,
        else => return err,
    };
    defer config_file.close(io);

    const file_size = (try config_file.stat(io)).size;

    const config_data = try utils.readFile(gpa, io, config_file, file_size);
    defer gpa.free(config_data);

    return try std.json.parseFromSlice(Config, gpa, config_data, .{ .allocate = .alloc_always });
}
