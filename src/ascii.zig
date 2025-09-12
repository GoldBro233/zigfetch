const std = @import("std");
const utils = @import("./utils.zig");

pub const Reset = "\x1b[0m";
pub const Bold = "\x1b[1m";
pub const Red = "\x1b[31m";
pub const Green = "\x1b[32m";
pub const Yellow = "\x1b[33m";
pub const Blue = "\x1b[34m";
pub const Magenta = "\x1b[35m";
pub const Cyan = "\x1b[36m";
pub const White = "\x1b[37m";

pub fn selectAscii() void {}

inline fn parseHexChar(c: u8) !u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'a'...'f' => c - 'a' + 10,
        'A'...'F' => c - 'A' + 10,
        else => error.InvalidHexChar,
    };
}

fn parseHexByte(s: []const u8) !u8 {
    if (s.len != 2) return error.InvalidHexByteLength;

    const hi = try parseHexChar(s[0]);
    const lo = try parseHexChar(s[1]);

    // Example: ff
    // hi = 0b00001111 (15)
    // lo = 0b00001111 (15)
    //
    // hi << 4 -> 0b11110000 (240)
    //
    // (hi << 4) | lo -> 0b11110000 | 0b00001111
    // => 0b11111111 (255)

    return (hi << 4) | lo;
}

/// Converts a hex color to rgb
pub fn hexColorToRgb(color: []const u8) !struct { r: u8, g: u8, b: u8 } {
    if (color.len < 6 or color.len > 7) return error.InvalidHexColorLength;

    var start: usize = 0;

    if (color[0] == '#') start = 1;

    return .{
        .r = try parseHexByte(color[start .. start + 2]),
        .g = try parseHexByte(color[start + 2 .. start + 4]),
        .b = try parseHexByte(color[start + 4 ..]),
    };
}

test "parse #ffffff" {
    const result = try hexColorToRgb("#ffffff");
    try std.testing.expect((result.r == 255) and (result.g == 255) and (result.b == 255));
}

test "parse ffffff" {
    const result = try hexColorToRgb("ffffff");
    try std.testing.expect((result.r == 255) and (result.g == 255) and (result.b == 255));
}

pub fn printAsciiAndModules(allocator: std.mem.Allocator, ascii_art_path: ?[]u8, sys_info_list: std.array_list.Managed([]u8)) !void {
    var stdout_buffer: [2048]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var ascii_art_data: []const u8 = undefined;
    if (ascii_art_path) |ascii| {
        var ascii_file = try std.fs.cwd().openFile(ascii, .{});
        defer ascii_file.close();
        ascii_art_data = try ascii_file.readToEndAlloc(allocator, std.math.maxInt(usize));
    } else {
        ascii_art_data = @embedFile("./assets/ascii/guy_fawks.txt");
    }

    defer if (ascii_art_path != null) {
        allocator.free(ascii_art_data);
    };

    var lines = std.mem.splitScalar(u8, ascii_art_data, '\n');

    var ascii_art_content_list = std.array_list.Managed([]const u8).init(allocator);
    defer ascii_art_content_list.deinit();

    while (lines.next()) |line| {
        try ascii_art_content_list.append(line);
    }

    const ascii_art_items = ascii_art_content_list.items;
    const sys_info_items = sys_info_list.items;

    const terminal_size = try utils.getTerminalSize() catch utils.TermSize{ 50, 50 };
    const terminal_width: usize = @intCast(terminal_size.width);

    const spacing: usize = 5;

    const longest_ascii_art_row_len: usize = try utils.getLongestAsciiArtRowLen(ascii_art_items);
    const longest_sys_info_string_len = utils.getLongestSysInfoStringLen(sys_info_items);

    const can_print_ascii_art: bool = terminal_width > longest_ascii_art_row_len + longest_sys_info_string_len + spacing;

    const ascii_art_len: usize = ascii_art_items.len;
    const sys_info_len: usize = sys_info_items.len;

    // NOTE: sys_info_len + 3 to be able to print the colors
    const max_len: usize = if ((ascii_art_len > sys_info_len) and can_print_ascii_art) ascii_art_len else sys_info_len + 3;

    var i: usize = 0;
    while (i < max_len) : (i += 1) {
        // Print the ascii art if the width of the terminal is greater than the spacing (5) + the longest ascii art row length + the longest sys info string length
        if (can_print_ascii_art) {
            const alignment_buffer = try allocator.alloc(u8, if (i < ascii_art_len) longest_ascii_art_row_len - (try utils.countCodepoints(ascii_art_items[i])) + spacing else longest_ascii_art_row_len + spacing);
            @memset(alignment_buffer, ' ');

            if (i < ascii_art_len) {
                try stdout.print("{s}{s}", .{ ascii_art_items[i], alignment_buffer });
            } else {
                try stdout.print("{s}", .{alignment_buffer});
            }

            allocator.free(alignment_buffer);

            try stdout.flush();
        }

        if (i < sys_info_len) {
            try stdout.print("{s}\n", .{sys_info_items[i]});
        } else if (i == sys_info_len + 1) {
            // Print the first row of colors
            for (0..8) |j| {
                try stdout.print("\x1b[48;5;{d}m  \x1b[0m", .{j});
            }
            try stdout.print("\n", .{});
        } else if (i == sys_info_len + 2) {
            // Print the second row of colors
            for (8..16) |j| {
                try stdout.print("\x1b[48;5;{d}m  \x1b[0m", .{j});
            }
            try stdout.print("\n", .{});
        } else {
            try stdout.print("\n", .{});
        }
        try stdout.flush();
    }

    for (sys_info_list.items) |item| {
        allocator.free(item);
    }
}
