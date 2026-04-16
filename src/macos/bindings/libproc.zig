// NOTE: Workaround for translate-c issue
const pid_t = i32;

pub const struct_timeval = extern struct {
    tv_sec: i64,
    tv_usec: i32,
};

pub const PROC_PIDPATHINFO_MAXSIZE: u32 = 4096;

pub extern "c" fn proc_pidpath(
    pid: pid_t,
    buffer: *anyopaque,
    buffersize: u32,
) i32;
