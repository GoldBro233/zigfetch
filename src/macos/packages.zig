const std = @import("std");
const utils = @import("../utils.zig");

pub fn getPackagesInfo(allocator: std.mem.Allocator) ![]const u8 {
    var packages_info = std.array_list.Managed(u8).init(allocator);
    defer packages_info.deinit();

    const homebrew_packages = countHomebrewPackages() catch |err| if (err == error.FileNotFound) 0 else return err;
    const homebrew_casks = countHomebrewCasks() catch |err| if (err == error.FileNotFound) 0 else return err;
    const macports_packages = countMacportPackages() catch |err| if (err == error.FileNotFound) 0 else return err;

    var buffer: [32]u8 = undefined;

    if (homebrew_packages > 0) {
        try packages_info.appendSlice(try std.fmt.bufPrint(&buffer, " brew: {d}", .{homebrew_packages}));
    }

    if (homebrew_casks > 0) {
        try packages_info.appendSlice(try std.fmt.bufPrint(&buffer, " brew-cask: {d}", .{homebrew_casks}));
    }

    if (macports_packages > 0) {
        try packages_info.appendSlice(try std.fmt.bufPrint(&buffer, " macports: {d}", .{macports_packages}));
    }

    return try allocator.dupe(u8, packages_info.items);
}

fn countHomebrewPackages() !usize {
    return try utils.countEntries("/opt/homebrew/Cellar");
}

fn countHomebrewCasks() !usize {
    return try utils.countEntries("/opt/homebrew/Caskroom");
}

fn countMacportPackages() !usize {
    return try utils.countEntries("/opt/local/bin");
}
