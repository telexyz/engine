//21-grams UNIQ: 11598,      T1: 1277,       DIFF: 10321,     TOTAL: 147234683, MAX: 1648223
//22-grams UNIQ: 2_660_982,  T1: 1_073_694,  DIFF: 1_587_288, TOTAL: 173407236, MAX: 402570
//23-grams UNIQ: 18_199_609, T1: 11_391_603, DIFF: 6_808_006, TOTAL: 143373168, MAX: 141418
//24-grams UNIQ: 38_657_253, T1: 28_845_097, DIFF: 9_812_156, TOTAL: 116442296, MAX: 56755
//25-grams UNIQ: 48_995_220, T1: 40_173_861, DIFF: 8_821_359, TOTAL: 95807330, MAX: 48105
//26-grams UNIQ: 49_354_098, T1: 42_480_313, DIFF: 6_873_785, TOTAL: 78207530, MAX: 37901
//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//             2..6-GRAMS   2-GRAMS      3-GRAMS      4-GRAMS      5-GRAMS      6-GRAMS
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// count = 1: 123_964_568 = 1_073_694 + 11_391_603 + 28_845_097 + 40_173_861 + 42_480_313
//                  BinaryFuseFilter = (( 268 MB ))
// remains:
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//             33_968_373 = 1_587_288 +  6_873_785 +  9_812_156 +  8_821_359 +  6_873_785
//      2^26 = 67_108_864 * 11-bytes = (( 704 MB )) 1..6-grams HashCount
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//             25_507_300 =                           9_812_156 +  8_821_359 +  6_873_785
//      2^25 = 33_554_432 * 10-bytes = (( 320 MB )) 4,5,6-grams HashCount
//
//              8_472_671 = 1_587_288 +  6_873_785 +  11598 (1-grams)
//      2^24   16_777_216 * 11-bytes = (( 176 MB )) 1,2,3-grams HashCount
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// TOTAL 764 MB

const std = @import("std");
const NGram = @import("./counting/n_gram.zig").NGram(true);

var input_filename: []const u8 = undefined;

fn initConfigsFromArgs() void {
    // Advance the iterator since we want to ignore the binary name.
    var args = std.process.args();
    _ = args.nextPosix();
    // Get input filename from args
    input_filename = args.nextPosix() orelse {
        std.debug.warn("expected input_filename as first argument\n", .{});
        std.os.exit(1);
    };
}

fn showMeTimeLap(start_time: i64, comptime fmt_str: []const u8) i64 {
    const now = std.time.milliTimestamp();
    const duration = now - start_time;
    const mins = @intToFloat(f32, duration) / 60000;
    std.debug.print("\n(( " ++ fmt_str ++ " Duration {d:.2} mins ))\n\n", .{mins});
    return now;
}

pub fn main() anyerror!void {
    const start_time = std.time.milliTimestamp();

    // Parse configs để get input_filename
    initConfigsFromArgs();

    // Khởi tạo bộ đếm
    var gram: NGram = .{};
    gram.init(std.heap.page_allocator);
    defer gram.deinit();

    try gram.loadSyllableIdsCdxFile(input_filename);
    const step0_time = showMeTimeLap(start_time, "Init Done!");

    std.debug.print("\nSTEP 3: Count and write n-gram ...\n", .{});

    // Chạy song song để tăng tốc
    // var thread = try std.Thread.spawn(.{}, NGram.countAndWrite23, .{ &gram, "data/22-grams", "data/23-grams" });
    try gram.countAndWrite23("data/22-grams", "data/23-grams");
    try gram.countAndWrite15("data/21-grams", "data/25-grams");
    // thread.join();

    // Nhưng chia làm hai mẻ để không nóng máy và quá tải bộ nhớ
    // thread = try std.Thread.spawn(.{}, NGram.countAndWrite04, .{ &gram, "data/24-grams" });
    try gram.countAndWrite04("data/24-grams");
    try gram.countAndWrite06("data/26-grams");
    // thread.join();

    _ = showMeTimeLap(step0_time, "STEP 3: Count and write n-gram done!");

    // Hoàn tất chương trình, hiện tổng thời gian chạy
    _ = showMeTimeLap(start_time, "FINISHED: Total");
}
