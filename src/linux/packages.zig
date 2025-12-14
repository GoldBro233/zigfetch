const std = @import("std");

fn countFlatpakPackages(allocator: std.mem.Allocator) !usize {
    // flatpak list | wc -l
    const result = try std.process.Child.run(.{ .allocator = allocator, .argv = &[_][]const u8{
        "sh",
        "-c",
        "flatpak list | wc -l",
    } });
    const result_stdout = result.stdout;
    const result_trimmed = std.mem.trim(u8, result_stdout, "\n");
    defer allocator.free(result_stdout);
    defer allocator.free(result.stderr);

    return try std.fmt.parseInt(usize, result_trimmed, 10);
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
