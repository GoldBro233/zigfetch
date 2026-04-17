// NOTE: Workaround for translate-c issue
pub const kern_return_t = i32;
pub const mach_port_t = u32;
pub const host_t = mach_port_t;
pub const natural_t = u32;
pub const integer_t = i32;
pub const mach_msg_type_number_t = natural_t;
pub const host_flavor_t = i32;
pub const host_info64_t = [*]integer_t;

pub const KERN_SUCCESS: kern_return_t = 0;
pub const HOST_VM_INFO64: host_flavor_t = 4;

pub const vm_statistics64 = extern struct {
    free_count: natural_t,
    active_count: natural_t,
    inactive_count: natural_t,
    wire_count: natural_t,
    zero_fill_count: u64,
    reactivations: u64,
    pageins: u64,
    pageouts: u64,
    faults: u64,
    cow_faults: u64,
    lookups: u64,
    hits: u64,
    purges: u64,
    purgeable_count: natural_t,
    speculative_count: natural_t,
    decompressions: u64,
    compressions: u64,
    swapins: u64,
    swapouts: u64,
    compressor_page_count: natural_t,
    throttled_count: natural_t,
    external_page_count: natural_t,
    internal_page_count: natural_t,
    total_uncompressed_pages_in_compressor: u64,
};

pub extern "c" fn mach_host_self() host_t;

pub extern "c" fn host_statistics64(
    host_priv: host_t,
    flavor: host_flavor_t,
    host_info64_out: host_info64_t,
    host_info64_outCnt: *mach_msg_type_number_t,
) kern_return_t;
