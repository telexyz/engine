const std = @import("std");

const Text = @import("./textoken/text_data_struct.zig").Text;
const TextokenOutput = @import("./textoken/output_helpers.zig");
const Tokenizer = @import("./textoken/tokenizer.zig").Tokenizer;
const text_utils = @import("./textoken/text_utils.zig");

// Init a Tokenizer and a Text
var tknz: Tokenizer = undefined;
var text: Text = undefined;

var input_filename: []const u8 = undefined;
var output_filename: []const u8 = undefined;
var keep_origin_amap: bool = true;
var convert_mode: u8 = 1; // dense
var count_n_grams: bool = false;

fn initConfigsFromArgs() void {
    // Advance the iterator since we want to ignore the binary name.
    var args = std.process.args();
    _ = args.nextPosix();
    // Get input filename from args
    input_filename = args.nextPosix() orelse {
        std.debug.print("expected input_filename as first argument\n", .{});
        std.os.exit(1);
    };
    // Get output filename from args
    output_filename = args.nextPosix() orelse {
        std.debug.print("expected output_filename as second argument\n", .{});
        std.os.exit(1);
    };
    // Optional, get max_lines from args
    var temp = args.nextPosix();
    if (temp != null) {
        keep_origin_amap = false;
        convert_mode = switch (temp.?[0]) {
            'd' => 1,
            's' => 2,
            'p' => 3,
            'u' => 4,
            else => 0,
        };
        if (convert_mode == 0) {
            std.debug.print("expected convert_mode is dense|spare|parts|utf-8\n", .{});
            std.os.exit(1);
        }
    }
    // Optional, parse n-grams or not?
    temp = args.nextPosix();
    count_n_grams = (temp != null);
}

fn write_out_types() !void {
    try TextokenOutput.write_mktn_vs_0m0t_types_to_files(
        text.syllable_types,
        false, // don't skip syllable
        "data/01-syllmark_freqs.txt",
        "data/02-syll0m0t_freqs.txt",
        "data/11-syllmark_types.txt",
        "data/12-syll0m0t_types.txt",
    );

    try TextokenOutput.write_types_to_files(
        text.syllow00_types,
        "data/03-syllow00_freqs.txt",
        "data/13-syllow00_types.txt",
    );

    try TextokenOutput.write_mktn_vs_0m0t_types_to_files(
        text.alphabet_types,
        true, // skip syllable
        "data/04-alphmark_freqs.txt",
        "data/05-alph0m0t_freqs.txt",
        "data/14-alphmark_types.txt",
        "data/15-alph0m0t_types.txt",
    );

    try TextokenOutput.write_types_to_files(
        text.nonalpha_types,
        "data/06-nonalpha_freqs.txt",
        "data/16-nonalpha_types.txt",
    );

    try TextokenOutput.write_types_to_files(
        text.syllable_types,
        "data/07-syllable_freqs.txt",
        "data/17-syllable_types.txt",
    );

    try TextokenOutput.write_types_to_files(
        text.syllower_types,
        "data/08-syllower_freqs.txt",
        "data/18-syllower_types.txt",
    );

    try TextokenOutput.write_types_to_files(
        text.syllovan_types,
        "data/09-syllovan_freqs.txt",
        "data/19-syllovan_types.txt",
    );
}

fn showMeTimeLap(start_time: i64, comptime fmt_str: []const u8) i64 {
    const now = std.time.milliTimestamp();
    const duration = now - start_time;
    const mins = @intToFloat(f32, duration) / 60000;
    std.debug.print("\n(( " ++ fmt_str ++ " Duration {d:.2} mins ))\n\n", .{mins});
    return now;
}

fn write_results(step2_time: i64) !void {
    // In the mean time writing parsed results out, and free amap mem asap
    std.debug.print("\nWriting types to files ...\n", .{});
    try text.processAlphabetTypes();
    try write_out_types();
    _ = showMeTimeLap(step2_time, "Writing types to files done!");

    std.debug.print("\nWriting tokenized results to {s} ...\n", .{output_filename});
    try TextokenOutput.write_transforms_to_file(
        &text,
        output_filename,
        "data/31-no_vietnamese.txt",
        "data/32-low_vietnamese.txt",
    );
    _ = showMeTimeLap(step2_time, "Writing tokenized results done!");
}

fn tokenizeAndParse(step0_time: i64) !i64 {
    // Thread riêng cho parser là tuỳ chọn,
    // có thể comment out và bật lại parse syllable on-the-fly
    var thread = try std.Thread.spawn(.{}, text_utils.parseTokens, .{&text});
    const then_parse_syllable = false;

    // Tuỳ chọn parse syllable on-the-fly
    // const then_parse_syllable = true;

    // Bắt đầu tknz trên text đã được load (thường là từ file)
    try tknz.segment(&text, then_parse_syllable);
    text.free_input_bytes();
    std.debug.print("\n\n >> TOTAL NUMBER OF TOKENS {d} <<\n\n", .{text.tokens_num});

    // Kết thúc tknz, hiện time tknz
    _ = showMeTimeLap(step0_time, "STEP 1: Token segmenting finish!");

    // Kết thúc parser thread là tuỳ chọn, comment out nếu bật parse syllable on-the-fly
    thread.join(); // Wait for sylabeling thread end

    // Kiểm tra xem đã parse hết token chưa
    if (text.parsed_tokens_num != text.tokens_num) std.debug.print("!!! PARSER NOT REACH THE LAST TOKEN !!!", .{}); // unreachable;

    // Kết thúc và hiện time tknz + parse
    return showMeTimeLap(step0_time, "STEP 1+2: Segment & parse tokens finish!");
}

pub fn countNGram(step2_time: i64) !void {
    std.debug.print("\nSTEP 3: Count and write n-gram ...\n", .{});

    const NGram = @import("./counting/n_gram.zig").NGram(true);
    // Khởi tạo bộ đếm
    var gram: NGram = .{};
    gram.init(std.heap.page_allocator);
    defer gram.deinit();

    try gram.loadSyllableIdsFromText(text);
    text.deinit();

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

    _ = showMeTimeLap(step2_time, "STEP 3: Count and write n-gram done!");
}

pub fn main() anyerror!void {
    const start_time = std.time.milliTimestamp();

    // Parse configs để get input_filename, convert_mode ...
    initConfigsFromArgs();
    std.debug.print("\nStart tokenize {s} ...\n", .{input_filename});

    tknz = .{ .max_lines = 0 };
    text = .{
        .init_allocator = std.heap.page_allocator,
        .keep_origin_amap = keep_origin_amap,
        .convert_mode = convert_mode,
    };

    // Load file text đầu vào
    try text.initFromFile(input_filename);
    defer text.deinit();
    const step0_time = showMeTimeLap(start_time, "Init Done!");

    // Bắt đầu tokenize và parse token để phát hiện âm tiết TV
    var step2_time = try tokenizeAndParse(step0_time);

    if (!count_n_grams) {
        // Nếu không phải đếm n-gram thì viết kết quả tknz và parser ra luôn
        try write_results(step2_time);
    } else {
        // Nếu đếm n-gram thì có thể tiện viết kết quả trong lúc count
        try countNGram(step2_time);
    }

    // Hoàn tất chương trình, hiện tổng thời gian chạy
    _ = showMeTimeLap(start_time, "FINISHED: Total");
}
