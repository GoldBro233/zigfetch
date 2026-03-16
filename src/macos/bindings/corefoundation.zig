// NOTE: Workaround for the issue: https://codeberg.org/ziglang/translate-c/issues/289

pub const CFTypeRef = ?*anyopaque;
pub const CFAllocatorRef = ?*anyopaque;
pub const CFStringRef = ?*anyopaque;
pub const CFDictionaryRef = ?*anyopaque;
pub const CFMutableDictionaryRef = ?*anyopaque;
pub const CFDataRef = ?*anyopaque;
pub const CFNumberRef = ?*anyopaque;

pub const CFTypeID = usize;
pub const CFIndex = isize;
pub const CFStringEncoding = u32;

pub const Boolean = u8;
pub const TRUE: Boolean = 1;
pub const FALSE: Boolean = 0;

pub const kCFStringEncodingUTF8: CFStringEncoding = 0x08000100;
pub const kCFNumberIntType: CFNumberType = 9;

pub const CFNumberType = i32;

pub const kCFAllocatorDefault: CFAllocatorRef = null;

pub extern "c" fn CFGetTypeID(cf: CFTypeRef) CFTypeID;

pub extern "c" fn CFRelease(cf: CFTypeRef) void;

pub extern "c" fn CFStringGetTypeID() CFTypeID;

pub extern "c" fn CFDataGetTypeID() CFTypeID;

pub extern "c" fn CFNumberGetTypeID() CFTypeID;

pub extern "c" fn CFStringCreateWithCString(
    alloc: CFAllocatorRef,
    cStr: [*:0]const u8,
    encoding: CFStringEncoding,
) CFStringRef;

pub extern "c" fn CFStringGetCString(
    theString: CFStringRef,
    buffer: [*]u8,
    bufferSize: CFIndex,
    encoding: CFStringEncoding,
) Boolean;

pub extern "c" fn CFStringGetLength(theString: CFStringRef) CFIndex;

pub extern "c" fn CFStringGetMaximumSizeForEncoding(
    length: CFIndex,
    encoding: CFStringEncoding,
) CFIndex;

pub extern "c" fn CFDataGetLength(theData: CFDataRef) CFIndex;

pub extern "c" fn CFDataGetBytePtr(theData: CFDataRef) [*c]const u8;

pub extern "c" fn CFNumberGetValue(
    number: CFNumberRef,
    theType: CFNumberType,
    valuePtr: *anyopaque,
) Boolean;

pub extern "c" fn CFDictionaryGetValueIfPresent(
    theDict: CFDictionaryRef,
    key: CFTypeRef,
    value: *CFTypeRef,
) Boolean;
