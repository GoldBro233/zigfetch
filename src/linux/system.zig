const std = @import("std");
const c_sysinfo = @cImport(@cInclude("sys/sysinfo.h"));
const c_utsname = @cImport(@cInclude("sys/utsname.h"));

/// Struct representing system uptime in days, hours, and minutes.
pub const SystemUptime = struct {
    days: i8,
    hours: i8,
    minutes: i8,
};

/// Struct representing Kernel informations
pub const KernelInfo = struct {
    kernel_name: []u8,
    kernel_release: []u8,
};

pub fn getHostname(allocator: std.mem.Allocator) ![]u8 {
    var buf: [std.posix.HOST_NAME_MAX]u8 = undefined;
    const hostnameEnv = try std.posix.gethostname(&buf);

    const hostname = try allocator.dupe(u8, hostnameEnv);

    return hostname;
}

pub fn getLocale(allocator: std.mem.Allocator) ![]u8 {
    const locale = std.process.getEnvVarOwned(allocator, "LANG") catch |err| if (err == error.EnvironmentVariableNotFound) {
        return allocator.dupe(u8, "Unknown");
    } else return err;
    return locale;
}

/// Returns the system uptime.
///
/// Uses `sysinfo` to fetch the system uptime and calculates the elapsed time.
pub fn getSystemUptime() !SystemUptime {
    const seconds_per_day: f64 = 86400.0;
    const hours_per_day: f64 = 24.0;
    const seconds_per_hour: f64 = 3600.0;
    const seconds_per_minute: f64 = 60.0;

    var info: c_sysinfo.struct_sysinfo = undefined;
    if (c_sysinfo.sysinfo(&info) != 0) {
        return error.SysinfoFailed;
    }

    const uptime_seconds: f64 = @as(f64, @floatFromInt(info.uptime));

    var remainig_seconds: f64 = uptime_seconds;
    const days: f64 = @floor(remainig_seconds / seconds_per_day);

    remainig_seconds = (remainig_seconds / seconds_per_day) - days;
    const hours = @floor(remainig_seconds * hours_per_day);

    remainig_seconds = (remainig_seconds * hours_per_day) - hours;
    const minutes = @floor((remainig_seconds * seconds_per_hour) / seconds_per_minute);

    return SystemUptime{
        .days = @as(i8, @intFromFloat(days)),
        .hours = @as(i8, @intFromFloat(hours)),
        .minutes = @as(i8, @intFromFloat(minutes)),
    };
}

pub fn getKernelInfo(allocator: std.mem.Allocator) !KernelInfo {
    var uts: c_utsname.struct_utsname = undefined;
    if (c_utsname.uname(&uts) != 0) {
        return error.UnameFailed;
    }

    return KernelInfo{
        .kernel_name = try allocator.dupe(u8, std.mem.sliceTo(&uts.sysname, 0)),
        .kernel_release = try allocator.dupe(u8, std.mem.sliceTo(&uts.release, 0)),
    };
}

pub fn getOsInfo(allocator: std.mem.Allocator) ![]u8 {
    const os_release_path = "/etc/os-release";
    const file = try std.fs.cwd().openFile(os_release_path, .{});
    defer file.close();
    const os_release_data = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
    defer allocator.free(os_release_data);

    var pretty_name: ?[]const u8 = null;

    var lines = std.mem.splitScalar(u8, os_release_data, '\n');
    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "PRETTY_NAME")) {
            var parts = std.mem.splitScalar(u8, line, '=');
            _ = parts.next(); // discard the key
            if (parts.next()) |value| {
                pretty_name = std.mem.trim(u8, value, "\"");
                break;
            }
        }
    }

    return try allocator.dupe(u8, pretty_name orelse "Unknown");
}

pub fn getWindowManagerInfo(allocator: std.mem.Allocator) ![]const u8 {
    var dir = try std.fs.cwd().openDir("/proc/", .{ .iterate = true });
    defer dir.close();

    var wm_name: ?[]const u8 = null;

    var iter = dir.iterate();
    wm_name = outer: {
        while (try iter.next()) |entry| {
            if (entry.kind != .directory) continue;

            // Check if the entry name is numeric
            _ = std.fmt.parseInt(i32, entry.name, 10) catch continue;

            var buf: [1024]u8 = undefined;
            const file_name = try std.fmt.bufPrint(&buf, "/proc/{s}/comm", .{entry.name});
            const file = try std.fs.cwd().openFile(file_name, .{ .mode = .read_only });
            defer file.close();

            // NOTE: https://stackoverflow.com/questions/23534263/what-is-the-maximum-allowed-limit-on-the-length-of-a-process-name
            var file_buf: [16]u8 = undefined;
            var reader = std.fs.File.Reader.init(file, &file_buf);
            const read = try reader.read(&file_buf);
            const proc_name = file_buf[0..read];

            const proc_name_trimmed = std.mem.trim(u8, proc_name, "\n");

            const supported_wms: [9][]const u8 = .{
                "i3", // https://i3wm.org/
                // "i3gaps", // TODO: find a way to recognize i3gaps
                "sway", // https://swaywm.org/
                // "swayfx", // TODO: find a way to recognize swayfx
                "niri", // https://github.com/YaLTeR/niri
                "dwm", // https://dwm.suckless.org/
                // "qtile", // TODO: find a way to recognize qtile
                "awesome", // https://awesomewm.org/
                "river", // https://codeberg.org/river/river
                "hyprland", // https://hypr.land/
                "bspwm", // https://github.com/baskerville/bspwm
                "openbox", // https://openbox.org/
            };

            inline for (supported_wms) |wm| {
                if (std.ascii.eqlIgnoreCase(wm, proc_name_trimmed)) {
                    break :outer try allocator.dupe(u8, proc_name_trimmed);
                }
            }
        }

        break :outer null;
    };

    return wm_name orelse allocator.dupe(u8, "Unknown");
}
