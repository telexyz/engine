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
    var thread = try std.Thread.spawn(.{}, NGram.countAndWrite23, .{ &gram, "data/22-grams", "data/23-grams" });
    try gram.countAndWrite15("data/21-grams", "data/25-grams");
    // try write_results(step2_time);
    thread.join();

    // Nhưng chia làm hai mẻ để không nóng máy và quá tải bộ nhớ
    thread = try std.Thread.spawn(.{}, NGram.countAndWrite04, .{ &gram, "data/24-grams" });
    try gram.countAndWrite06("data/26-grams");
    thread.join();

    _ = showMeTimeLap(step0_time, "STEP 3: Count and write n-gram done!");

    // Hoàn tất chương trình, hiện tổng thời gian chạy
    _ = showMeTimeLap(start_time, "FINISHED: Total");
}
