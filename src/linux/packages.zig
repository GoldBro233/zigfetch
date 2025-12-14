const std = @import("std");
const utils = @import("../utils.zig");

pub fn getPackagesInfo(allocator: std.mem.Allocator) ![]const u8 {
    var packages_info = std.array_list.Managed(u8).init(allocator);
    defer packages_info.deinit();

    const flatpak_packages = countFlatpakPackages() catch |err| if (err == error.FileNotFound) 0 else return err;
    const nix_packages = countNixPackages(allocator) catch 0;
    const dpkg_packages = countDpkgPackages(allocator) catch |err| if (err == error.FileNotFound) 0 else return err;
    const pacman_packages = countPacmanPackages() catch |err| if (err == error.FileNotFound) 0 else return err;
    const xbps_packages = countXbpsPackages(allocator) catch |err| if (err == error.FileNotFound) 0 else return err;

    var buffer: [32]u8 = undefined;

    if (nix_packages > 0) {
        try packages_info.appendSlice(try std.fmt.bufPrint(&buffer, " Nix: {d}", .{nix_packages}));
    }

    if (flatpak_packages > 0) {
        try packages_info.appendSlice(try std.fmt.bufPrint(&buffer, " Flatpak: {d}", .{flatpak_packages}));
    }

    if (dpkg_packages > 0) {
        try packages_info.appendSlice(try std.fmt.bufPrint(&buffer, " Dpkg: {d}", .{dpkg_packages}));
    }

    if (pacman_packages > 0) {
        try packages_info.appendSlice(try std.fmt.bufPrint(&buffer, " Pacman: {d}", .{pacman_packages}));
    }

    if (xbps_packages > 0) {
        try packages_info.appendSlice(try std.fmt.bufPrint(&buffer, " Xbps: {d}", .{xbps_packages}));
    }

    return try allocator.dupe(u8, packages_info.items);
}

fn countFlatpakPackages() !usize {
    const flatpak_apps = try countFlatpakApps();
    const flatpak_runtimes = try countFlatpakRuntimes();

    return flatpak_apps + flatpak_runtimes;
}

fn countFlatpakApps() !usize {
    var dir = try std.fs.openDirAbsolute("/var/lib/flatpak/app/", .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();

    var count: usize = 0;

    while (try iter.next()) |e| {
        if (e.kind != .directory) continue;

        var sub_dir = try dir.openDir(e.name, .{});
        defer sub_dir.close();

        var current = sub_dir.openDir("current", .{}) catch continue;
        defer current.close();

        // If `current` was opened successfully, increment the count
        count += 1;
    }

    return count;
}

fn countFlatpakRuntimes() !usize {
    var dir = try std.fs.openDirAbsolute("/var/lib/flatpak/runtime/", .{ .iterate = true });
    defer dir.close();

    var iter = dir.iterate();

    var counter: usize = 0;

    while (try iter.next()) |e| {
        if (std.mem.endsWith(u8, e.name, ".Locale") or std.mem.endsWith(u8, e.name, ".Debug")) continue;

        var arch_dir = try dir.openDir(e.name, .{ .iterate = true });
        defer arch_dir.close();
        var arch_iter = arch_dir.iterate();
        while (try arch_iter.next()) |arch_e| {
            if (arch_e.kind != .directory) continue;

            var sub_dir = try arch_dir.openDir(arch_e.name, .{ .iterate = true });
            defer sub_dir.close();
            var sub_iter = sub_dir.iterate();
            while (try sub_iter.next()) |_| {
                counter += 1;
            }
        }
    }

    return counter;
}

fn countNixPackages(allocator: std.mem.Allocator) !usize {
    // nix-store --query --requisites /run/current-system | wc -l
    const result = try std.process.Child.run(.{ .allocator = allocator, .argv = &[_][]const u8{
        "sh",
        "-c",
        "nix-store --query --requisites /run/current-system | wc -l",
    } });

    const result_stdout = result.stdout;
    const result_trimmed = std.mem.trim(u8, result_stdout, "\n");
    defer allocator.free(result_stdout);
    defer allocator.free(result.stderr);

    return try std.fmt.parseInt(usize, result_trimmed, 10);
}

fn countDpkgPackages(allocator: std.mem.Allocator) !usize {
    const dpkg_status_path = "/var/lib/dpkg/status";
    const dpkg_file = try std.fs.cwd().openFile(dpkg_status_path, .{ .mode = .read_only });
    defer dpkg_file.close();
    const file_size = (try dpkg_file.stat()).size;

    const content = try utils.readFile(allocator, dpkg_file, file_size);
    defer allocator.free(content);

    var count: usize = 0;
    var iter = std.mem.splitSequence(u8, content, "\n\n");
    // TODO: find a way to avoid this loop
    while (iter.next()) |_| {
        count += 1;
    }

    // Subtruct 1 to remove an useless line
    return count - 1;
}

fn countPacmanPackages() !usize {
    // Subtruct 1 to remove `ALPM_DB_VERSION` from the count
    return try utils.countEntries("/var/lib/pacman/local") - 1;
}

fn countXbpsPackages(allocator: std.mem.Allocator) !usize {
    var dir = try std.fs.openDirAbsolute("/var/db/xbps/", .{ .iterate = true });
    defer dir.close();

    var count: usize = 0;

    var dir_iter = dir.iterate();

    while (try dir_iter.next()) |e| {
        if ((e.kind == .file) and std.mem.startsWith(u8, e.name, "pkgdb-")) {
            const pkgdb_file = try dir.openFile(e.name, .{ .mode = .read_only });
            defer pkgdb_file.close();
            const file_size = (try pkgdb_file.stat()).size;

            const content = try utils.readFile(allocator, pkgdb_file, file_size);
            defer allocator.free(content);

            var file_iter = std.mem.splitSequence(u8, content, "<string>installed</string>");
            // TODO: find a way to avoid this loop
            while (file_iter.next()) |_| {
                count += 1;
            }

            break;
        }
    }

    // Subtruct 1 to remove an useless line
    return count - 1;
}
