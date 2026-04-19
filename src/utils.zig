const std = @import("std");
const builtin = @import("builtin");

pub const TermSize = struct {
    width: u16,
    height: u16,
};

pub fn getTerminalSize() !TermSize {
    // https://github.com/softprops/zig-termsize (https://github.com/softprops/zig-termsize/blob/main/src/main.zig)

    const stdout = std.Io.File.stdout();

    switch (builtin.os.tag) {
        .windows => {
            var buf: std.os.windows.CONSOLE_SCREEN_BUFFER_INFO = undefined;
            switch (std.os.windows.kernel32.GetConsoleScreenBufferInfo(stdout.handle, &buf)) {
                std.os.windows.TRUE => return TermSize{
                    .width = @intCast(buf.srWindow.Right - buf.srWindow.Left + 1),
                    .height = @intCast(buf.srWindow.Bottom - buf.srWindow.Top + 1),
                },
                else => return error.GetConsoleScreenBufferInfoFailed,
            }
        },
        .linux, .macos => {
            var buf: std.posix.winsize = undefined;
            switch (std.posix.errno(
                std.posix.system.ioctl(
                    stdout.handle,
                    std.posix.T.IOCGWINSZ,
                    @intFromPtr(&buf),
                ),
            )) {
                std.posix.E.SUCCESS => return TermSize{
                    .width = buf.col,
                    .height = buf.row,
                },
                else => return error.IoctlFailed,
            }
        },
        else => return error.UnsupportedOperatingSystem,
    }
}

test "getTerminalSize" {
    const terminal_size = getTerminalSize() catch TermSize{ .height = 50, .width = 50 };

    std.debug.print("Height: {}, Width {}\n", .{ terminal_size.height, terminal_size.width });

    try std.testing.expect((terminal_size.height > 0) and (terminal_size.width > 0));
}

pub fn getLongestSysInfoStringLen(strings: []const []const u8) usize {
    const ansi_reset = "\x1b[0m";
    var longest_len: usize = 0;

    // Ignore the username@host and the separator
    for (strings[2..]) |s| {
        const ansi_restet_index = std.mem.indexOf(u8, s, ansi_reset);
        var start: usize = 0;

        if (ansi_restet_index != null) {
            // `start` is the index of the last character of the ANSI reset escape sequence + 1
            start = ansi_restet_index.? + ansi_reset.len + 1;

            if (start > s.len) continue;
        }

        longest_len = @max(longest_len, s[start..].len);
    }

    return longest_len;
}

test "getLongestSysInfoStringLen" {
    const strings = [_][]const u8{ "", "", "test", "test-test", "test1" };

    try std.testing.expectEqual(strings[3].len, getLongestSysInfoStringLen(strings[0..]));
}

pub fn countCodepoints(str: []const u8) !usize {
    var count: usize = 0;
    var i: usize = 0;

    while (i < str.len) {
        const byte_len = try std.unicode.utf8ByteSequenceLength(str[i]);
        if ((i + byte_len > str.len) or (!std.unicode.utf8ValidateSlice(str[i .. i + byte_len]))) return error.InvalidUtf8;

        count += 1;
        i += byte_len;
    }

    return count;
}

test "countCodepoints" {
    const str = "            ████████████████";

    try std.testing.expectEqual(28, try countCodepoints(str));
}

pub fn getLongestAsciiArtRowLen(ascii_art: []const []const u8) !usize {
    var longest_len: usize = 0;

    for (ascii_art) |ascii_row| {
        longest_len = @max(longest_len, try countCodepoints(ascii_row));
    }

    return longest_len;
}

test "getLongestAsciiArtRowLen" {
    const rows = [_][]const u8{ "            ████████████████", "██░░░░██████████░░    ░░██████████░░░░██" };

    try std.testing.expectEqual(40, try getLongestAsciiArtRowLen(rows[0..]));
}

pub fn readFile(gpa: std.mem.Allocator, io: std.Io, file: std.Io.File, size: usize) ![]const u8 {
    var file_buf = try gpa.alloc(u8, size);
    defer gpa.free(file_buf);

    const read = try file.readPositionalAll(io, file_buf, 0);

    const data = file_buf[0..read];

    return gpa.dupe(u8, data);
}

pub fn countEntries(io: std.Io, dir_path: []const u8) !usize {
    var dir = try std.Io.Dir.openDirAbsolute(io, dir_path, .{ .iterate = true });
    defer dir.close(io);

    var count: usize = 0;
    var iter = dir.iterate();

    while (try iter.next(io)) |_| {
        count += 1;
    }

    return count;
}

/// Checks whether the file is a PNG image by inspecting its magic bytes.
pub fn isFilePng(gpa: std.mem.Allocator, io: std.Io, file_path: []const u8) !bool {
    const png_magic = [8]u8{ 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };

    const file = try std.Io.Dir.openFileAbsolute(io, file_path, .{ .mode = .read_only });
    const content = try readFile(gpa, io, file, 8);
    defer gpa.free(content);

    return std.mem.eql(u8, content, &png_magic);
}
