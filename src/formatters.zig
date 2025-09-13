const builtin = @import("builtin");
const std = @import("std");
const ascii = @import("ascii.zig");
const detection = @import("detection.zig").os_module;

const Result = union(enum) {
    string: []u8,
    string_arraylist: std.array_list.Managed([]u8),
};

pub const formatters = [_]*const fn (allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) anyerror!Result{
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
    &getFormattedNetInfo,
    &getFormattedTerminalNameInfo,
    &getFormattedLocaleInfo,
    &getFormattedCustom,
};

pub const default_formatters = [_]*const fn (allocator: std.mem.Allocator) anyerror!Result{
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
    &getDefaultFormattedNetInfo,
    &getDefaultFormattedTerminalNameInfo,
    &getDefaultFormattedLocaleInfo,
};

pub fn getFormattedUsernameHostname(allocator: std.mem.Allocator, color: []const u8, username: []const u8, hostname: []const u8) ![]u8 {
    return try std.fmt.allocPrint(allocator, "{s}{s}{s}@{s}{s}{s}", .{
        color,
        username,
        ascii.Reset,
        color,
        hostname,
        ascii.Reset,
    });
}

pub fn getDefaultFormattedKernelInfo(allocator: std.mem.Allocator) !Result {
    return try getFormattedKernelInfo(allocator, "Kernel", ascii.Yellow);
}

pub fn getFormattedKernelInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) !Result {
    const kernel_info = try detection.system.getKernelInfo(allocator);
    defer allocator.free(kernel_info.kernel_name);
    defer allocator.free(kernel_info.kernel_release);

    return Result{ .string = try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s} {s}", .{ key_color, key, ascii.Reset, kernel_info.kernel_name, kernel_info.kernel_release }) };
}

pub fn getDefaultFormattedOsInfo(allocator: std.mem.Allocator) !Result {
    return try getFormattedOsInfo(allocator, "OS", ascii.Yellow);
}

pub fn getFormattedOsInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) !Result {
    const os_info = try detection.system.getOsInfo(allocator);
    defer allocator.free(os_info);
    return Result{ .string = try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s}", .{ key_color, key, ascii.Reset, os_info }) };
}

pub fn getDefaultFormattedLocaleInfo(allocator: std.mem.Allocator) !Result {
    return try getFormattedLocaleInfo(allocator, "Locale", ascii.Yellow);
}

pub fn getFormattedLocaleInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) !Result {
    const locale = try detection.system.getLocale(allocator);
    defer allocator.free(locale);
    return Result{ .string = try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s}", .{ key_color, key, ascii.Reset, locale }) };
}

pub fn getDefaultFormattedUptimeInfo(allocator: std.mem.Allocator) !Result {
    return try getFormattedUptimeInfo(allocator, "Uptime", ascii.Yellow);
}

pub fn getFormattedUptimeInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) !Result {
    const uptime = try detection.system.getSystemUptime();
    return Result{ .string = try std.fmt.allocPrint(allocator, "{s}{s}:{s} {} days, {} hours, {} minutes", .{ key_color, key, ascii.Reset, uptime.days, uptime.hours, uptime.minutes }) };
}

pub fn getDefaultFormattedPackagesInfo(allocator: std.mem.Allocator) !Result {
    return try getFormattedPackagesInfo(allocator, "Packages", ascii.Yellow);
}

pub fn getFormattedPackagesInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) !Result {
    if (builtin.os.tag == .macos) {
        const packages_info = try detection.packages.getPackagesInfo(allocator);
        defer allocator.free(packages_info);
        return Result{ .string = try std.fmt.allocPrint(allocator, "{s}{s}:{s}{s}", .{ key_color, key, ascii.Reset, packages_info }) };
    } else if (builtin.os.tag == .linux) {
        return Result{ .string = try std.fmt.allocPrint(allocator, "{s}{s}:{s} WIP", .{ key_color, key, ascii.Reset }) };
    }
}

pub fn getDefaultFormattedShellInfo(allocator: std.mem.Allocator) !Result {
    return try getFormattedShellInfo(allocator, "Shell", ascii.Yellow);
}

pub fn getFormattedShellInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) !Result {
    const shell = try detection.user.getShell(allocator);
    defer allocator.free(shell);
    return Result{ .string = try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s}", .{ key_color, key, ascii.Reset, shell[0..(shell.len - 1)] }) };
}

pub fn getDefaultFormattedCpuInfo(allocator: std.mem.Allocator) !Result {
    return try getFormattedCpuInfo(allocator, "Cpu", ascii.Yellow);
}

pub fn getFormattedCpuInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) !Result {
    const cpu_info = try detection.hardware.getCpuInfo(allocator);
    defer allocator.free(cpu_info.cpu_name);
    return Result{ .string = try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s} ({}) @ {d:.2} GHz", .{ key_color, key, ascii.Reset, cpu_info.cpu_name, cpu_info.cpu_cores, cpu_info.cpu_max_freq }) };
}

pub fn getDefaultFormattedGpuInfo(allocator: std.mem.Allocator) !Result {
    if (builtin.os.tag == .macos) {
        return try getFormattedGpuInfo(allocator, "Gpu", ascii.Yellow);
    } else if (builtin.os.tag == .linux) {
        return try getFormattedGpuInfo(allocator, "Gpu", ascii.Yellow);
    }
}

pub fn getFormattedGpuInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) !Result {
    if (builtin.os.tag == .macos) {
        const gpu_info = try detection.hardware.getGpuInfo(allocator);
        defer allocator.free(gpu_info.gpu_name);
        return Result{ .string = try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s} ({}) @ {d:.2} GHz", .{ key_color, key, ascii.Reset, gpu_info.gpu_name, gpu_info.gpu_cores, gpu_info.gpu_freq }) };
    } else if (builtin.os.tag == .linux) {
        var formatted_gpu_info_list = std.array_list.Managed([]u8).init(allocator);

        const gpu_info_list = try detection.hardware.getGpuInfo(allocator);

        for (gpu_info_list.items) |g| {
            var formatted_gpu_info: []u8 = undefined;
            if ((g.gpu_cores == 0) or (g.gpu_freq == 0.0)) {
                formatted_gpu_info = try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s}", .{ key_color, key, ascii.Reset, g.gpu_name });
            } else {
                formatted_gpu_info = try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s} ({}) @ {d:.2} GHz", .{ key_color, key, ascii.Reset, g.gpu_name, g.gpu_cores, g.gpu_freq });
            }
            try formatted_gpu_info_list.append(formatted_gpu_info);
            allocator.free(g.gpu_name);
        }
        gpu_info_list.deinit();

        return Result{ .string_arraylist = formatted_gpu_info_list };
    }
}

pub fn getDefaultFormattedRamInfo(allocator: std.mem.Allocator) !Result {
    return try getFormattedRamInfo(allocator, "Ram", ascii.Yellow);
}

pub fn getFormattedRamInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) !Result {
    const ram_info = if (builtin.os.tag == .macos) try detection.hardware.getRamInfo() else if (builtin.os.tag == .linux) try detection.hardware.getRamInfo(allocator);
    return Result{ .string = try std.fmt.allocPrint(allocator, "{s}{s}:{s} {d:.2} / {d:.2} GiB ({}%)", .{ key_color, key, ascii.Reset, ram_info.ram_usage, ram_info.ram_size, ram_info.ram_usage_percentage }) };
}

pub fn getDefaultFormattedSwapInfo(allocator: std.mem.Allocator) !Result {
    return try getFormattedSwapInfo(allocator, "Swap", ascii.Yellow);
}

pub fn getFormattedSwapInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) !Result {
    const swap_info = if (builtin.os.tag == .macos) try detection.hardware.getSwapInfo() else if (builtin.os.tag == .linux) try detection.hardware.getSwapInfo(allocator);
    if (swap_info) |s| {
        return Result{ .string = try std.fmt.allocPrint(allocator, "{s}{s}:{s} {d:.2} / {d:.2} GiB ({}%)", .{ key_color, key, ascii.Reset, s.swap_usage, s.swap_size, s.swap_usage_percentage }) };
    } else {
        return Result{ .string = try std.fmt.allocPrint(allocator, "{s}{s}:{s} Disabled", .{ key_color, key, ascii.Reset }) };
    }
}

pub fn getDefaultFormattedDiskInfo(allocator: std.mem.Allocator) !Result {
    return try getFormattedDiskInfo(allocator, "Disk", ascii.Yellow);
}

pub fn getFormattedDiskInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) !Result {
    const disk_info = try detection.hardware.getDiskSize("/");
    return Result{ .string = try std.fmt.allocPrint(allocator, "{s}{s} ({s}):{s} {d:.2} / {d:.2} GB ({}%)", .{ key_color, key, disk_info.disk_path, ascii.Reset, disk_info.disk_usage, disk_info.disk_size, disk_info.disk_usage_percentage }) };
}

pub fn getDefaultFormattedTerminalNameInfo(allocator: std.mem.Allocator) !Result {
    return try getFormattedTerminalNameInfo(allocator, "Terminal", ascii.Yellow);
}

pub fn getFormattedTerminalNameInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) !Result {
    const terminal_name = try detection.user.getTerminalName(allocator);
    defer allocator.free(terminal_name);
    return Result{ .string = try std.fmt.allocPrint(allocator, "{s}{s}:{s} {s}", .{ key_color, key, ascii.Reset, terminal_name }) };
}

pub fn getDefaultFormattedNetInfo(allocator: std.mem.Allocator) !Result {
    return try getFormattedNetInfo(allocator, "Local IP", ascii.Yellow);
}

pub fn getFormattedNetInfo(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) !Result {
    var formatted_net_info_list = std.array_list.Managed([]u8).init(allocator);

    var net_info_list = try detection.network.getNetInfo(allocator);
    for (net_info_list.items) |n| {
        try formatted_net_info_list.append(try std.fmt.allocPrint(allocator, "{s}{s} ({s}):{s} {s}", .{ key_color, key, n.interface_name, ascii.Reset, n.ipv4_addr }));
        allocator.free(n.interface_name);
        allocator.free(n.ipv4_addr);
    }
    net_info_list.deinit();

    return Result{ .string_arraylist = formatted_net_info_list };
}

pub fn getFormattedCustom(allocator: std.mem.Allocator, key: []const u8, key_color: []const u8) !Result {
    return Result{ .string = try std.fmt.allocPrint(allocator, "{s}{s}{s}", .{ key_color, key, ascii.Reset }) };
}
