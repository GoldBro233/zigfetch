const std = @import("std");
const c_iokit = @cImport(@cInclude("IOKit/IOKitLib.h"));

/// Converts a CFTypeRef casted to CFStringRef to a Zig string.
pub fn cfTypeRefToZigString(allocator: std.mem.Allocator, cf_type_ref: c_iokit.CFTypeRef) ![]u8 {
    const cf_string: c_iokit.CFStringRef = @ptrFromInt(@intFromPtr(cf_type_ref));

    const length = c_iokit.CFStringGetLength(cf_string);
    const max_size = c_iokit.CFStringGetMaximumSizeForEncoding(length, c_iokit.kCFStringEncodingUTF8) + 1;
    const max_size_usize = @as(usize, @intCast(max_size));

    const buffer = try allocator.alloc(u8, max_size_usize);
    errdefer allocator.free(buffer);

    if (c_iokit.CFStringGetCString(cf_string, buffer.ptr, @as(c_iokit.CFIndex, @intCast(buffer.len)), c_iokit.kCFStringEncodingUTF8) == c_iokit.FALSE) {
        return error.StringConversionFailed;
    }

    var actual_len: usize = 0;
    while (actual_len < buffer.len and buffer[actual_len] != 0) {
        actual_len += 1;
    }

    return allocator.realloc(buffer, actual_len);
}

pub fn countEntries(dir_path: []const u8) !usize {
    var dir = try std.fs.openDirAbsolute(dir_path, .{ .iterate = true });
    defer dir.close();

    var count: usize = 0;
    var iter = dir.iterate();

    while (try iter.next()) |_| {
        count += 1;
    }

    return count;
}
