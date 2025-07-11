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

    return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s} {s}", .{ key_color, key, ascii.Reset, kernel_info.kernel_name, kernel_info.kernel_release });
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
    return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {} days, {} hours, {} minutes ", .{ key_color, key, ascii.Reset, uptime.days, uptime.hours, uptime.minutes });
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
    return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s} ({}) @ {d:.2} GHz", .{ key_color, key, ascii.Reset, cpu_info.cpu_name, cpu_info.cpu_cores, cpu_info.cpu_max_freq });
}

pub fn getDefaultFormattedGpuInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedGpuInfo(allocator, "Gpu", ascii.Yellow);
}

pub fn getFormattedGpuInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    const gpu_info = try detection.hardware.getGpuInfo(allocator);
    defer allocator.free(gpu_info.gpu_name);
    return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s} ({}) @ {d:.2} GHz", .{ key_color, key, ascii.Reset, gpu_info.gpu_name, gpu_info.gpu_cores, gpu_info.gpu_freq });
}

pub fn getDefaultFormattedRamInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedRamInfo(allocator, "Ram", ascii.Yellow);
}

pub fn getFormattedRamInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    const ram_info = if (builtin.os.tag == .macos) try detection.hardware.getRamInfo() else if (builtin.os.tag == .linux) try detection.hardware.getRamInfo(allocator);
    return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {d:.2} / {d:.2} GiB ({}%)", .{ key_color, key, ascii.Reset, ram_info.ram_usage, ram_info.ram_size, ram_info.ram_usage_percentage });
}

pub fn getDefaultFormattedSwapInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedSwapInfo(allocator, "Swap", ascii.Yellow);
}

pub fn getFormattedSwapInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    const swap_info = if (builtin.os.tag == .macos) try detection.hardware.getSwapInfo() else if (builtin.os.tag == .linux) try detection.hardware.getSwapInfo(allocator);
    if (swap_info) |s| {
        return try std.fmt.allocPrint(allocator, "{s}{s}:{s} {d:.2} / {d:.2} GiB ({}%)", .{ key_color, key, ascii.Reset, s.swap_usage, s.swap_size, s.swap_usage_percentage });
    } else {
        return try std.fmt.allocPrint(allocator, "{s}{s}:{s} Disabled", .{ key_color, key, ascii.Reset });
    }
}

pub fn getDefaultFormattedDiskInfo(allocator: std.mem.Allocator) ![]u8 {
    return try getFormattedDiskInfo(allocator, "Disk", ascii.Yellow);
}

pub fn getFormattedDiskInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) ![]u8 {
    const disk_info = try detection.hardware.getDiskSize("/");
    return try std.fmt.allocPrint(allocator, "{s}{s} ({s}):{s} {d:.2} / {d:.2} GB ({}%)", .{ key_color, key, disk_info.disk_path, ascii.Reset, disk_info.disk_usage, disk_info.disk_size, disk_info.disk_usage_percentage });
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

    var net_info_list = try detection.network.getNetInfo(allocator);
    for (net_info_list.items) |n| {
        try formatted_net_info_list.append(try std.fmt.allocPrint(allocator, "{s}{s} ({s}):{s} {s}", .{ key_color, key, n.interface_name, ascii.Reset, n.ipv4_addr }));
        allocator.free(n.interface_name);
        allocator.free(n.ipv4_addr);
    }
    net_info_list.deinit();

    return formatted_net_info_list;
}
