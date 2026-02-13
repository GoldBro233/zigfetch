const std = @import("std");

pub fn getUsername(allocator: std.mem.Allocator, environ: std.process.Environ) ![]u8 {
    return try std.process.Environ.getAlloc(environ, allocator, "USER");
}

pub fn getShell(allocator: std.mem.Allocator, io: std.Io, environ: std.process.Environ) ![]u8 {
    const shell = std.process.Environ.getAlloc(environ, allocator, "SHELL") catch |err| if (err == error.EnvironmentVariableNotFound) {
        return allocator.dupe(u8, "Unknown");
    } else return err;

    defer allocator.free(shell);

    const result = try std.process.run(allocator, io, .{ .argv = &[_][]const u8{ shell, "--version" } });
    const result_stdout = result.stdout;

    if (std.mem.indexOf(u8, shell, "bash") != null) {
        const bash_version = parseBashVersion(result_stdout);
        defer allocator.free(result_stdout);
        return try std.fmt.allocPrint(allocator, "{s} {s}", .{ "bash", bash_version.? });
    }

    return result_stdout;
}

fn parseBashVersion(shell_version_output: []u8) ?[]u8 {
    const end_index = std.mem.indexOf(u8, shell_version_output, "(");
    if (end_index == null) return null;

    const version_keyword = "version ";
    const version_keyword_index = std.mem.indexOf(u8, shell_version_output[0..end_index.?], version_keyword);
    if (version_keyword_index == null) return null;

    return shell_version_output[version_keyword_index.? + version_keyword.len .. end_index.? + 1];
}

pub fn getTerminalName(allocator: std.mem.Allocator, environ: std.process.Environ) ![]u8 {
    const term_program = std.process.Environ.getAlloc(environ, allocator, "TERM_PROGRAM") catch |err| if (err == error.EnvironmentVariableNotFound) {
        return allocator.dupe(u8, "Unknown");
    } else return err;
    return term_program;
}
