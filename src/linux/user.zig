const std = @import("std");

pub fn getUsername(allocator: std.mem.Allocator) ![]u8 {
    const username = try std.process.getEnvVarOwned(allocator, "USER");
    return username;
}

pub fn getShell(allocator: std.mem.Allocator) ![]u8 {
    const shell = std.process.getEnvVarOwned(allocator, "SHELL") catch |err| if (err == error.EnvironmentVariableNotFound) {
        return allocator.dupe(u8, "Unknown");
    } else return err;

    var child = std.process.Child.init(&[_][]const u8{ shell, "--version" }, allocator);
    defer allocator.free(shell);

    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    const output = try child.stdout.?.reader().readAllAlloc(allocator, 1024 * 1024);

    _ = try child.wait();

    if (std.mem.indexOf(u8, shell, "bash") != null) {
        const bash_version = parseBashVersion(allocator, output);
        defer allocator.free(output);
        return try std.fmt.allocPrint(allocator, "{s} {s}", .{ "bash", bash_version.? });
    }

    return output;
}

fn parseBashVersion(allocator: std.mem.Allocator, shell_version_output: []u8) ?[]u8 {
    _ = allocator;
    const end_index = std.mem.indexOf(u8, shell_version_output, "(");
    if (end_index == null) return null;

    const version_keyword = "version ";
    const version_keyword_index = std.mem.indexOf(u8, shell_version_output[0..end_index.?], version_keyword);
    if (version_keyword_index == null) return null;

    return shell_version_output[version_keyword_index.? + version_keyword.len .. end_index.?];
}

pub fn getTerminalName(allocator: std.mem.Allocator) ![]u8 {
    const term_program = std.process.getEnvVarOwned(allocator, "TERM_PROGRAM") catch |err| if (err == error.EnvironmentVariableNotFound) {
        return allocator.dupe(u8, "Unknown");
    } else return err;
    return term_program;
}
