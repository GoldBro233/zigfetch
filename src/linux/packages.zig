const std = @import("std");

fn countFlatpaks(allocator: std.mem.Allocator) !usize {
    // flatpak list | wc -l
    const result = try std.process.Child.run(.{ .allocator = allocator, .argv = &[_][]const u8{
        "sh",
        "-c",
        "flatpak list | wc -l",
    } });
    const result_stdout = result.stdout;
    const result_trimmed = std.mem.trim(u8, result_stdout, "\n");
    defer allocator.free(result_stdout);

    return try std.fmt.parseInt(usize, result_trimmed, 10);
}
