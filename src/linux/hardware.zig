const std = @import("std");
const utils = @import("../utils.zig");
const c = @import("c");

/// Struct representing CPU informations
pub const CpuInfo = struct {
    cpu_name: []u8,
    cpu_cores: i32,
    cpu_max_freq: f32,
};

/// Struct representing GPU informations
pub const GpuInfo = struct {
    gpu_name: []u8,
    gpu_cores: i32,
    gpu_freq: f64,
};

/// Struct representing RAM usage informations
pub const RamInfo = struct {
    ram_size: f64,
    ram_usage: f64,
    ram_usage_percentage: u8,
};

/// Struct representing Swap usage informations
pub const SwapInfo = struct {
    swap_size: f64,
    swap_usage: f64,
    swap_usage_percentage: u8,
};

/// Struct representing Disk usage informations
pub const DiskInfo = struct {
    disk_path: []const u8,
    disk_size: f64,
    disk_usage: f64,
    disk_usage_percentage: u8,
};

pub fn getCpuInfo(gpa: std.mem.Allocator, io: std.Io) !CpuInfo {
    const cpu_cores = c.sysconf(c._SC_NPROCESSORS_ONLN);

    // Reads /proc/cpuinfo
    const cpuinfo_path = "/proc/cpuinfo";
    const cpuinfo_file = try std.Io.Dir.cwd().openFile(io, cpuinfo_path, .{ .mode = .read_only });
    defer cpuinfo_file.close(io);

    // NOTE: procfs is a pseudo-filesystem, so it is not possible to determine the size of a file
    // https://docs.kernel.org/filesystems/proc.html
    // https://en.wikipedia.org/wiki/Procfs
    //
    // Only the first section (core 0) will be parsed
    // 512 is more than enough
    const cpuinfo_data = try utils.readFile(gpa, io, cpuinfo_file, 512);
    defer gpa.free(cpuinfo_data);

    // Parsing /proc/cpuinfo
    var model_name: ?[]const u8 = null;
    var cpu_max_freq_mhz_str: ?[]const u8 = null;

    var lines = std.mem.splitScalar(u8, cpuinfo_data, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (std.mem.startsWith(u8, trimmed, "model name") and model_name == null) {
            var parts = std.mem.splitScalar(u8, trimmed, ':');
            _ = parts.next(); // discards the key
            if (parts.next()) |value| {
                model_name = std.mem.trim(u8, value, " ");
            }
        } else if (std.mem.startsWith(u8, trimmed, "cpu MHz") and cpu_max_freq_mhz_str == null) {
            var parts = std.mem.splitScalar(u8, trimmed, ':');
            _ = parts.next(); // discard the key
            if (parts.next()) |value| {
                cpu_max_freq_mhz_str = std.mem.trim(u8, value, " ");
            }
        }

        if ((model_name != null) and (cpu_max_freq_mhz_str != null)) {
            break;
        }
    }

    var cpu_max_freq: f32 = 0.0;

    // NOTE: this is the preferred approach beacause it is the most accurate
    const cpuinfo_max_freq_path = "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq";
    var cmf_exists: bool = true;

    // Checks if /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq exists
    _ = std.Io.Dir.accessAbsolute(io, cpuinfo_max_freq_path, .{ .read = true }) catch |err| {
        if (err == std.Io.Dir.AccessError.FileNotFound) {
            cmf_exists = false;
        }
    };

    if (cmf_exists) {
        // Reads /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq
        const maxfreq_file = try std.Io.Dir.cwd().openFile(io, cpuinfo_max_freq_path, .{ .mode = .read_only });
        defer maxfreq_file.close(io);
        const maxfreq_data = try utils.readFile(gpa, io, maxfreq_file, 32);
        defer gpa.free(maxfreq_data);

        // Parsing /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq
        const trimmed = std.mem.trim(u8, maxfreq_data, " \n\r");
        const cpu_max_freq_khz: f32 = try std.fmt.parseFloat(f32, trimmed);
        cpu_max_freq = cpu_max_freq_khz / 1_000_000;
    } else {
        if (cpu_max_freq_mhz_str != null) {
            const cpu_max_freq_mhz: f32 = try std.fmt.parseFloat(f32, cpu_max_freq_mhz_str.?);
            cpu_max_freq = cpu_max_freq_mhz / 1_000;
        }
    }

    return CpuInfo{
        .cpu_name = try gpa.dupe(u8, model_name orelse "Unknown"),
        .cpu_cores = @as(i32, @intCast(cpu_cores)),
        .cpu_max_freq = cpu_max_freq,
    };
}

pub fn getGpuInfo(gpa: std.mem.Allocator) !std.array_list.Managed(GpuInfo) {
    var gpu_info_list = std.array_list.Managed(GpuInfo).init(gpa);

    const display_controller = 0x03;

    const pacc = c.pci_alloc();
    defer c.pci_cleanup(pacc);
    c.pci_init(pacc);
    c.pci_scan_bus(pacc);

    var devices = pacc.*.devices;
    while (devices != null) : (devices = devices.*.next) {
        // NOTE: for references: https://github.com/pciutils/pciutils/blob/3ec74c71c01878f92e751f15bb8febe720c3ab40/lib/access.c#L194
        const known_fields = c.pci_fill_info(devices, c.PCI_FILL_IDENT | c.PCI_FILL_CLASS);
        if (known_fields <= 0) {
            return error.NoLibpciFieldsFound;
        }

        if ((devices.*.device_class >> 8) == display_controller) {
            var name_buffer: [256]u8 = undefined;

            const name = c.pci_lookup_name(
                pacc,
                &name_buffer,
                name_buffer.len,
                c.PCI_LOOKUP_VENDOR | c.PCI_LOOKUP_DEVICE,
                devices.*.vendor_id,
                devices.*.device_id,
            );

            const gpu_name = try gpa.dupe(u8, std.mem.span(name));

            const maybe_parsed_gpu_name = try parseGpuName(gpa, gpu_name);
            var parsed_gpu_name: []u8 = undefined;

            if (maybe_parsed_gpu_name != null) {
                gpa.free(gpu_name);
                parsed_gpu_name = maybe_parsed_gpu_name.?;
            } else {
                parsed_gpu_name = gpu_name;
            }

            try gpu_info_list.append(GpuInfo{
                .gpu_name = parsed_gpu_name,
                .gpu_cores = 0,
                .gpu_freq = 0.0,
            });
        }
    }

    if (gpu_info_list.items.len == 0) {
        try gpu_info_list.append(GpuInfo{
            .gpu_name = try gpa.dupe(u8, "Unknown"),
            .gpu_cores = 0,
            .gpu_freq = 0.0,
        });
    }

    return gpu_info_list;
}

fn parseGpuName(gpa: std.mem.Allocator, name: []u8) !?[]u8 {
    // NOTE: for references: https://github.com/pciutils/pciutils/blob/master/pci.ids

    if (std.mem.startsWith(u8, name, "Advanced Micro Devices, Inc. [AMD/ATI]")) {
        const size = std.mem.replacementSize(u8, name, "Advanced Micro Devices, Inc. [AMD/ATI]", "AMD");
        const parsed_gpu_name = try gpa.alloc(u8, size);
        _ = std.mem.replace(u8, name, "Advanced Micro Devices, Inc. [AMD/ATI]", "AMD", parsed_gpu_name);

        return parsed_gpu_name;
    } else if (std.mem.startsWith(u8, name, "Intel Corporation")) {
        const size = std.mem.replacementSize(u8, name, "Intel Corporation", "Intel");
        const parsed_gpu_name = try gpa.alloc(u8, size);
        _ = std.mem.replace(u8, name, "Intel Corporation", "Intel", parsed_gpu_name);

        return parsed_gpu_name;
    } else if (std.mem.startsWith(u8, name, "NVIDIA Corporation")) {
        const size = std.mem.replacementSize(u8, name, "NVIDIA Corporation", "NVIDIA");
        const parsed_gpu_name = try gpa.alloc(u8, size);
        _ = std.mem.replace(u8, name, "NVIDIA Corporation", "NVIDIA", parsed_gpu_name);

        return parsed_gpu_name;
    }

    return null;
}

pub fn getRamInfo(gpa: std.mem.Allocator, io: std.Io) !RamInfo {
    // Reads /proc/meminfo
    const meminfo_path = "/proc/meminfo";
    const meminfo_file = try std.Io.Dir.cwd().openFile(io, meminfo_path, .{ .mode = .read_only });
    defer meminfo_file.close(io);

    // NOTE: procfs is a pseudo-filesystem, so it is not possible to determine the size of a file
    // https://docs.kernel.org/filesystems/proc.html
    // https://en.wikipedia.org/wiki/Procfs
    //
    // We only need to read the first few lines
    // 512 is more than enough
    const meminfo_data = try utils.readFile(gpa, io, meminfo_file, 512);
    defer gpa.free(meminfo_data);

    // Parsing /proc/meminfo
    var total_mem: f64 = 0.0;
    var free_mem: f64 = 0.0; // remove?
    var available_mem: f64 = 0.0;

    var total_mem_str: ?[]const u8 = null;
    var free_mem_str: ?[]const u8 = null;
    var available_mem_str: ?[]const u8 = null;

    var lines = std.mem.splitScalar(u8, meminfo_data, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (std.mem.startsWith(u8, trimmed, "MemTotal")) {
            var parts = std.mem.splitScalar(u8, trimmed, ':');
            _ = parts.next(); // discards the key
            if (parts.next()) |value| {
                total_mem_str = std.mem.trim(u8, value[0..(value.len - 3)], " ");
                total_mem = try std.fmt.parseFloat(f64, total_mem_str.?);
            }
        } else if (std.mem.startsWith(u8, trimmed, "MemFree")) {
            var parts = std.mem.splitScalar(u8, trimmed, ':');
            _ = parts.next(); // discards the key
            if (parts.next()) |value| {
                free_mem_str = std.mem.trim(u8, value[0..(value.len - 3)], " ");
                free_mem = try std.fmt.parseFloat(f64, free_mem_str.?);
            }
        } else if (std.mem.startsWith(u8, trimmed, "MemAvailable")) {
            var parts = std.mem.splitScalar(u8, trimmed, ':');
            _ = parts.next(); // discards the key
            if (parts.next()) |value| {
                available_mem_str = std.mem.trim(u8, value[0..(value.len - 3)], " ");
                available_mem = try std.fmt.parseFloat(f64, available_mem_str.?);
            }
        }

        if ((total_mem_str != null) and (free_mem_str != null) and (available_mem_str != null)) {
            break;
        }
    }

    var used_mem = total_mem - available_mem;

    // Converts KB in GB
    total_mem /= (1024 * 1024);
    used_mem /= (1024 * 1024);
    const ram_usage_percentage: u8 = @as(u8, @intFromFloat((used_mem * 100) / total_mem));

    return RamInfo{
        .ram_size = total_mem,
        .ram_usage = used_mem,
        .ram_usage_percentage = ram_usage_percentage,
    };
}

pub fn getSwapInfo(gpa: std.mem.Allocator, io: std.Io) !?SwapInfo {
    // Reads /proc/meminfo
    const meminfo_path = "/proc/meminfo";
    const meminfo_file = try std.Io.Dir.cwd().openFile(io, meminfo_path, .{ .mode = .read_only });
    defer meminfo_file.close(io);

    // NOTE: procfs is a pseudo-filesystem, so it is not possible to determine the size of a file
    // https://docs.kernel.org/filesystems/proc.html
    // https://en.wikipedia.org/wiki/Procfs
    //
    // We only need to read the first few lines
    // 512 is ok
    const meminfo_data = try utils.readFile(gpa, io, meminfo_file, 512);
    defer gpa.free(meminfo_data);

    // Parsing /proc/meminfo
    var total_swap: f64 = 0.0;
    var free_swap: f64 = 0.0;

    var total_swap_str: ?[]const u8 = null;
    var free_swap_str: ?[]const u8 = null;

    var lines = std.mem.splitScalar(u8, meminfo_data, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (std.mem.startsWith(u8, trimmed, "SwapTotal")) {
            var parts = std.mem.splitScalar(u8, trimmed, ':');
            _ = parts.next(); // discards the key
            if (parts.next()) |value| {
                total_swap_str = std.mem.trim(u8, value[0..(value.len - 3)], " ");
                total_swap = try std.fmt.parseFloat(f64, total_swap_str.?);
            }
        } else if (std.mem.startsWith(u8, trimmed, "SwapFree")) {
            var parts = std.mem.splitScalar(u8, trimmed, ':');
            _ = parts.next(); // discards the key
            if (parts.next()) |value| {
                free_swap_str = std.mem.trim(u8, value[0..(value.len - 3)], " ");
                free_swap = try std.fmt.parseFloat(f64, free_swap_str.?);
            }
        }

        if ((total_swap_str != null) and (free_swap_str != null)) {
            break;
        }
    }

    var used_swap = total_swap - free_swap;

    // Converts KB in GB
    total_swap /= (1024 * 1024);
    used_swap /= (1024 * 1024);

    if (used_swap == 0) {
        return null;
    }

    const swap_usage_percentage: u8 = @as(u8, @intFromFloat((used_swap * 100) / total_swap));

    return SwapInfo{
        .swap_size = total_swap,
        .swap_usage = used_swap,
        .swap_usage_percentage = swap_usage_percentage,
    };
}

pub fn getDiskSize(disk_path: []const u8) !DiskInfo {
    var stat: c.struct_statvfs = undefined;
    if (c.statvfs(disk_path.ptr, &stat) != 0) {
        return error.StatvfsFailed;
    }

    const total_size = stat.f_blocks * stat.f_frsize;
    const free_size = stat.f_bfree * stat.f_frsize;
    const used_size = total_size - free_size;

    const used_size_percentage = (used_size * 100) / total_size;

    return DiskInfo{
        .disk_path = disk_path,
        .disk_size = @as(f64, @floatFromInt(total_size)) / 1e9,
        .disk_usage = @as(f64, @floatFromInt(used_size)) / 1e9,
        .disk_usage_percentage = @as(u8, @intCast(used_size_percentage)),
    };
}
