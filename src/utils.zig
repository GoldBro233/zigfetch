const std = @import("std");
const builtin = @import("builtin");

pub const TermSize = struct {
    width: u16,
    height: u16,
};

pub fn getTerminalSize() !TermSize {
    // https://github.com/softprops/zig-termsize (https://github.com/softprops/zig-termsize/blob/main/src/main.zig)

    const stdout = std.io.getStdIn();

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
    const terminal_size = try getTerminalSize();

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
        }

        longest_len = @max(longest_len, s[start..].len);
    }

    return longest_len;
}

test "getLongestSysInfoStringLen" {
    const strings = [_][]const u8{ "", "", "test", "test-test", "test1" };

    try std.testing.expectEqual(strings[3].len, getLongestSysInfoStringLen(strings[0..]));
}
