// NOTE: Workaround for the issue: https://codeberg.org/ziglang/translate-c/issues/289

const cf = @import("corefoundation.zig");

pub const kern_return_t = i32;
pub const IOReturn = kern_return_t;
pub const io_object_t = u32;
pub const io_service_t = io_object_t;
pub const io_iterator_t = io_object_t;
pub const mach_port_t = u32;

pub const TRUE = cf.TRUE;
pub const FALSE = cf.FALSE;

pub const KERN_SUCCESS: kern_return_t = 0;
pub const kIOMasterPortDefault: mach_port_t = 0;

pub const CFMutableDictionaryRef = cf.CFMutableDictionaryRef;
pub const kCFAllocatorDefault = cf.kCFAllocatorDefault;
pub const kCFStringEncodingUTF8 = cf.kCFStringEncodingUTF8;
pub const CFTypeRef = cf.CFTypeRef;
pub const CFDictionaryRef = cf.CFDictionaryRef;
pub const CFStringRef = cf.CFStringRef;
pub const CFIndex = cf.CFIndex;

pub extern "c" fn IOServiceGetMatchingService(
    masterPort: mach_port_t,
    matching: cf.CFDictionaryRef,
) io_service_t;

pub extern "c" fn IOServiceGetMatchingServices(
    masterPort: mach_port_t,
    matching: cf.CFDictionaryRef,
    existing: *io_iterator_t,
) kern_return_t;

pub extern "c" fn IOServiceMatching(
    name: [*:0]const u8,
) cf.CFMutableDictionaryRef;

pub extern "c" fn IOServiceNameMatching(
    name: [*:0]const u8,
) cf.CFMutableDictionaryRef;

pub extern "c" fn IOObjectRelease(object: io_object_t) kern_return_t;

pub extern "c" fn IOObjectConformsTo(
    object: io_object_t,
    className: [*:0]const u8,
) u8;

pub extern "c" fn IOIteratorNext(iterator: io_iterator_t) io_object_t;

pub extern "c" fn IORegistryEntryCreateCFProperty(
    entry: io_service_t,
    key: cf.CFStringRef,
    allocator: cf.CFAllocatorRef,
    options: u32,
) cf.CFTypeRef;

pub extern "c" fn IORegistryEntryCreateCFProperties(
    entry: io_service_t,
    properties: *cf.CFMutableDictionaryRef,
    allocator: cf.CFAllocatorRef,
    options: u32,
) kern_return_t;

pub const CFStringCreateWithCString = cf.CFStringCreateWithCString;

pub const CFRelease = cf.CFRelease;

pub const CFGetTypeID = cf.CFGetTypeID;

pub const CFDataGetLength = cf.CFDataGetLength;

pub const CFDictionaryGetValueIfPresent = cf.CFDictionaryGetValueIfPresent;

pub const CFDataGetBytePtr = cf.CFDataGetBytePtr;

pub const CFStringGetTypeID = cf.CFStringGetTypeID;

pub const CFStringGetLength = cf.CFStringGetLength;

pub const CFStringGetMaximumSizeForEncoding = cf.CFStringGetMaximumSizeForEncoding;

pub const CFStringGetCString = cf.CFStringGetCString;
