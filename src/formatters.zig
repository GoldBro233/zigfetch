const builtin = @import("builtin");
const std = @import("std");
const ascii = @import("ascii.zig");
const detection = @import("detection.zig").os_module;

pub const formatters = [_]*const fn (allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) anyerror![]u8{
    &getFormattedOsInfo,
    &getFormattedKernelInfo,
    &getFormattedUptimeInfo,
    &getFormattedPackagesInfo,
    &getFormattedShellInfo,
    &getFormattedCpuInfo,
    &getFormattedGpuInfo,
    &getFormattedRamInfo,
    &getFormattedSwapInfo,
    &getFormattedDiskInfo,
    &getFormattedTerminalNameInfo,
    &getFormattedLocaleInfo,
};

pub const default_formatters = [_]*const fn (allocator: std.mem.Allocator) anyerror![]u8{
    &getDefaultFormattedOsInfo,
    &getDefaultFormattedKernelInfo,
    &getDefaultFormattedUptimeInfo,
    &getDefaultFormattedPackagesInfo,
    &getDefaultFormattedShellInfo,
    &getDefaultFormattedCpuInfo,
    &getDefaultFormattedGpuInfo,
    &getDefaultFormattedRamInfo,
    &getDefaultFormattedSwapInfo,
    &getDefaultFormattedDiskInfo,
    &getDefaultFormattedTerminalNameInfo,
    &getDefaultFormattedLocaleInfo,
};

pub fn getDefaultFormattedKernelInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedKernelInfo(allocator, "Kernel", ascii.Yellow);
}

pub fn getFormattedKernelInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    const kernel_info = try detection.system.getKernelInfo(allocator);
    defer allocator.free(kernel_info.kernel_name);
    defer allocator.free(kernel_info.kernel_release);

    var buf: [1024]u8 = undefined;

    return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s}", .{ key_color, key, ascii.Reset, try kernel_info.toStr(&buf) });
}

pub fn getDefaultFormattedOsInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedOsInfo(allocator, "OS", ascii.Yellow);
}

pub fn getFormattedOsInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    const os_info = try detection.system.getOsInfo(allocator);
    defer allocator.free(os_info);
    return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s}", .{ key_color, key, ascii.Reset, os_info });
}

pub fn getDefaultFormattedLocaleInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedLocaleInfo(allocator, "Locale", ascii.Yellow);
}

pub fn getFormattedLocaleInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    const locale = try detection.system.getLocale(allocator);
    defer allocator.free(locale);
    return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s}", .{ key_color, key, ascii.Reset, locale });
}

pub fn getDefaultFormattedUptimeInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedUptimeInfo(allocator, "Uptime", ascii.Yellow);
}

pub fn getFormattedUptimeInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    const uptime = try detection.system.getSystemUptime();
    var buf: [1024]u8 = undefined;
    return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s}", .{ key_color, key, ascii.Reset, try uptime.toStr(&buf) });
}

pub fn getDefaultFormattedPackagesInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedPackagesInfo(allocator, "Packages", ascii.Yellow);
}

pub fn getFormattedPackagesInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    if (builtin.os.tag == .macos) {
        const packages_info = try detection.packages.getPackagesInfo(allocator);
        defer allocator.free(packages_info);
        return try std.fmt.allocPrint(allocator, "{s}{s}:{s}{s}", .{ key_color, key, ascii.Reset, packages_info });
    } else if (builtin.os.tag == .linux) {
        return try std.fmt.allocPrint(allocator, "{s}{s}:{s} WIP", .{ key_color, key, ascii.Reset });
    }
}

pub fn getDefaultFormattedShellInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedShellInfo(allocator, "Shell", ascii.Yellow);
}

pub fn getFormattedShellInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    const shell = try detection.user.getShell(allocator);
    defer allocator.free(shell);
    return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s}", .{ key_color, key, ascii.Reset, shell[0..(shell.len - 1)] });
}

pub fn getDefaultFormattedCpuInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedCpuInfo(allocator, "Cpu", ascii.Yellow);
}

pub fn getFormattedCpuInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    const cpu_info = try detection.hardware.getCpuInfo(allocator);
    defer allocator.free(cpu_info.cpu_name);

    var buf: [1024]u8 = undefined;

    return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s}", .{ key_color, key, ascii.Reset, try cpu_info.toStr(&buf) });
}

pub fn getDefaultFormattedGpuInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedGpuInfo(allocator, "Gpu", ascii.Yellow);
}

pub fn getFormattedGpuInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    if (builtin.os.tag == .macos) {
        const gpu_info = try detection.hardware.getGpuInfo(allocator);
        defer allocator.free(gpu_info.gpu_name);

        var buf: [1024]u8 = undefined;

        return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s}", .{ key_color, key, ascii.Reset, try gpu_info.toStr(&buf) });
    } else if (builtin.os.tag == .linux) {
        return try std.fmt.allocPrint(allocator, "{s}{s}:{s} WIP", .{ key_color, key, ascii.Reset });
    }
}

pub fn getDefaultFormattedRamInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedRamInfo(allocator, "Ram", ascii.Yellow);
}

pub fn getFormattedRamInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    var ram_info = detection.hardware.RamInfo{
        .ram_size = 0.0,
        .ram_usage = 0.0,
        .ram_usage_percentage = 0,
    };
    if (builtin.os.tag == .macos) {
        ram_info = try detection.hardware.getRamInfo();
    } else if (builtin.os.tag == .linux) {
        ram_info = try detection.hardware.getRamInfo(allocator);
    }

    var buf: [1024]u8 = undefined;

    return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s}", .{ key_color, key, ascii.Reset, try ram_info.toStr(&buf) });
}

pub fn getDefaultFormattedSwapInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedSwapInfo(allocator, "Swap", ascii.Yellow);
}

pub fn getFormattedSwapInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    var buf: [1024]u8 = undefined;
    const swap_info = if (builtin.os.tag == .macos) try detection.hardware.getSwapInfo() else if (builtin.os.tag == .linux) try detection.hardware.getSwapInfo(allocator);
    if (swap_info) |s| {
        return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s}", .{ key_color, key, ascii.Reset, try s.toStr(&buf) });
    } else {
        return try std.fmt.allocPrint(allocator, "{s}{s}:{s} Disabled", .{ key_color, key, ascii.Reset });
    }
}

pub fn getDefaultFormattedDiskInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedDiskInfo(allocator, "Disk", ascii.Yellow);
}

pub fn getFormattedDiskInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    const disk_info = try detection.hardware.getDiskSize("/");

    var buf: [1024]u8 = undefined;

    return try std.fmt.allocPrint(allocator, "{s}{s}{s} {s}", .{ key_color, key, ascii.Reset, try disk_info.toStr(&buf) });
}

pub fn getDefaultFormattedTerminalNameInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedTerminalNameInfo(allocator, "Terminal", ascii.Yellow);
}

pub fn getFormattedTerminalNameInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    const terminal_name = try detection.user.getTerminalName(allocator);
    defer allocator.free(terminal_name);
    return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s}", .{ key_color, key, ascii.Reset, terminal_name });
}

pub fn getDefaultFormattedNetInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedNetInfo(allocator, "Local IP", ascii.Yellow);
}

pub fn getFormattedNetInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) !std.ArrayList([]u8) {
    var formatted_net_info_list = std.ArrayList([]u8).init(allocator);

    var buf: [1024]u8 = undefined;

    var net_info_list = try detection.network.getNetInfo(allocator);
    for (net_info_list.items) |n| {
        try formatted_net_info_list.append(try std.fmt.allocPrint(allocator, "{s}{s} {s}{s}", .{ key_color, key, ascii.Reset, try n.toStr(&buf) }));
        allocator.free(n.interface_name);
        allocator.free(n.ipv4_addr);
        @memset(&buf, 0);
    }
    net_info_list.deinit();

    return formatted_net_info_list;
}
