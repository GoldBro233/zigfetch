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
