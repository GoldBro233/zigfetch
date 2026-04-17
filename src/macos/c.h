// TODO: Uncomment once the translate-c issues is fixed
// See issues:
// - https://codeberg.org/ziglang/translate-c/issues/289
// - https://codeberg.org/ziglang/translate-c/issues/320
// #include <CoreFoundation/CoreFoundation.h>
// #include <IOKit/IOKitLib.h>
// #include <libproc.h>
// #include <mach/mach.h>
#include <arpa/inet.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/statvfs.h>
#include <sys/sysctl.h>
