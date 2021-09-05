// 1-gram U: 11598,    U1: 1277,     U234: 1520,    U5+: 8801, T: 147230477, M: 1648223
// 2-gram U: 2660982,  U1: 1073694,  U234: 699083,  U5+: 888205,  T: 171548242, M: 402570
// 3-gram U: 18199606, U1: 11391599, U234: 4193497, U5+: 2614510, T: 132637965, M: 141418
// 4-gram U: 38657253, U1: 28845097, U234: 6969558, U5+: 2842598, T: 99047714,  M: 56755
// 5-gram U: 48995220, U1: 40173861, U234: 6807030, U5+: 2014329, T: 79163202,  M: 48105
// 6-gram U: 49354098, U1: 42480313, U234: 5577166, U5+: 1296619, T: 64776242,  M: 37901
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//             2..6-GRAMS   2-GRAMS      3-GRAMS      4-GRAMS      5-GRAMS      6-GRAMS
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// count = 1: 123_964_568 = 1_073_694 + 11_391_603 + 28_845_097 + 40_173_861 + 42_480_313
//                  BinaryFuseFilter = (( 268 MB ))
//
// count=234:  24_246_334 =   699_083 +  4_193_497 +  6_969_558 +  6_807_030 +  5_577_166
//                  BinaryFuseFilter = ((  46 MB ))
// remains:
//              6_153_546 =                           2_842_598 +  2_014_329 +  1_296_619
//      2^23 =  8_388_608 *  9-bytes = ((  66 MB )) 4,5,6-grams HashCount
//
//              3_511_516 =  888_205 +  2_614_510 +  8801 (1-grams)
//      2^22    4_194_304 *  9-bytes = ((  36 MB )) 1,2,3-grams HashCount
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// TOTAL 416 MB

//
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//             2..6-GRAMS   2-GRAMS      3-GRAMS      4-GRAMS      5-GRAMS      6-GRAMS
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// count = 1: 123_964_568 = 1_073_694 + 11_391_603 + 28_845_097 + 40_173_861 + 42_480_313
//                  BinaryFuseFilter = (( 268 MB ))
//
// count = 2:  15_651_196 =   368_646 +  2_474_876 +  4_539_069 +  4_407_207 +  3_861_398
//                  BinaryFuseFilter = ((  30 MB ))
// remains:
//             12_699_626 =                           5_404_949 +  4_282_290 +  3_012_387
//      2^24 = 16_777_216 *  9-bytes = (( 131 MB )) 4,5,6-grams HashCount
//
//              5_561_385 = 1_218_642 +  4_333_131 +  9612 (1-grams)
//      2^23    8_388_608 *  9-bytes = (( 72 MB )) 1,2,3-grams HashCount
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// TOTAL 501 MB

// 1-gram U: 11598,    U1: 1277,     U2: 709,     U3+: 9612,    T: 147233265, M: 1648223
// 2-gram U: 2660982,  U1: 1073694,  U2: 368646,  U3+: 1218642, T: 172669944, M: 402570
// 3-gram U: 18199606, U1: 11391599, U2: 2474876, U3+: 4333131, T: 138423416, M: 141418
// 4-gram U: 38657253, U1: 28845097, U2: 4407207, U3+: 5404949, T: 107627882, M: 56755
// 5-gram U: 48995220, U1: 40173861, U2: 4539069, U3+: 4282290, T: 86729192,  M: 48105
// 6-gram U: 49354098, U1: 42480313, U2: 3861398, U3+: 3012387, T: 70484734,  M: 37901
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
//             2..6-GRAMS   2-GRAMS      3-GRAMS      4-GRAMS      5-GRAMS      6-GRAMS
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// count = 1: 123_964_568 = 1_073_694 + 11_391_603 + 28_845_097 + 40_173_861 + 42_480_313
//                  BinaryFuseFilter = (( 268 MB ))
// remains:
//             25_507_300 =                           9_812_156 +  8_821_359 +  6_873_785
//      2^25 = 33_554_432 *  9-bytes = (( 262 MB )) 4,5,6-grams HashCount
//
//              8_472_671 = 1_587_288 +  6_873_785 +  11598 (1-grams)
//      2^24   16_777_216 *  9-bytes = (( 144 MB )) 1,2,3-grams HashCount
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// TOTAL 674 MB

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
