const std = @import("std");
const print = std.debug.print;
const time = std.time;
const parsers = @import("./parsers.zig");

pub fn main() anyerror!void {
    var args = std.process.args();

    // Advance the iterator since we want to ignore the binary name.
    _ = args.nextPosix();

    var syllable = args.nextPosix() orelse {
        const start_time = time.milliTimestamp();
        print("start_time {}\n", .{start_time});

        parsers.testPerformance(100000);

        const end_time = time.milliTimestamp();
        print("end_time {}\n", .{end_time});
        print("Duration {} ms\n\n", .{end_time - start_time});
        // std.debug.warn("expected input syllable an argument\n", .{});
        std.os.exit(1);
    };

    print("Syllable: {s}\n", .{syllable});
    print("parseAmTietToGetSyllable \"{s}\" => {any}\n\n", .{ syllable, parsers.parseAmTietToGetSyllable(print, syllable) });
}
