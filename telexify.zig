const std = @import("std");
const print = std.debug.print;

const Text = @import("./src/text_data_struct.zig").Text;
const TextokOutput = @import("./src/textok_output_helpers.zig").TextokOutputHelpers;
const Tokenizer = @import("./src/tokenizer.zig").Tokenizer;
const text_utils = @import("./src/text_utils.zig");
const NGram = @import("./src/n_gram.zig").NGram;

// Init a Tokenizer and a Text
var tknz: Tokenizer = undefined;
var text: Text = undefined;
var gram: NGram = undefined;

var input_filename: []const u8 = undefined;
var output_filename: []const u8 = undefined;
var keep_origin_amap: bool = true;
var convert_mode: u8 = 1; // dense
var parse_n_grams: bool = false;

fn initConfigsFromArgs() void {
    // Advance the iterator since we want to ignore the binary name.
    var args = std.process.args();
    _ = args.nextPosix();
    // Get input filename from args
    input_filename = args.nextPosix() orelse {
        std.debug.warn("expected input_filename as first argument\n", .{});
        std.os.exit(1);
    };
    // Get output filename from args
    output_filename = args.nextPosix() orelse {
        std.debug.warn("expected output_filename as second argument\n", .{});
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
            else => 0,
        };
        if (convert_mode == 0) {
            std.debug.warn("expected convert_mode is dense|spare|parts\n", .{});
            std.os.exit(1);
        }
    }
    // Optional, parse n-grams or not?
    temp = args.nextPosix();
    parse_n_grams = (temp != null);
}

fn write_out_samples() !void {
    // Write sample of final output to preview
    try TextokOutput.write_text_tokens_to_file(
        text,
        "data/07-tokens_sample.txt",
        777_777,
    );
}

fn write_out_types() !void {
    try TextokOutput.write_mktn_vs_0m0t_types_to_files(
        text.syllable_types,
        "data/01-syllmark_freqs.txt",
        "data/02-syll0m0t_freqs.txt",
        "data/11-syllmark_types.txt",
        "data/12-syll0m0t_types.txt",
    );
    try TextokOutput.write_types_to_files(
        text.syllow0t_types,
        "data/03-syllow0t_freqs.txt",
        "data/13-syllow0t_types.txt",
    );
    try TextokOutput.write_mktn_vs_0m0t_types_to_files(
        text.alphabet_types,
        "data/04-alphmark_freqs.txt",
        "data/05-alph0m0t_freqs.txt",
        "data/14-alphmark_types.txt",
        "data/15-alph0m0t_types.txt",
    );
    try TextokOutput.write_types_to_files(
        text.nonalpha_types,
        "data/06-nonalpha_freqs.txt",
        "data/16-nonalpha_types.txt",
    );
}

fn write_out_final() !void {
    try TextokOutput.write_too_long_tokens_to_file(
        text.alphabet_too_long_tokens,
        "data/09-alphabet_too_long.txt",
        "data/08-alphmark_too_long.txt",
    );
    try TextokOutput.write_too_long_tokens_to_file(
        text.nonalpha_too_long_tokens,
        "data/10-nonalpha_too_long.txt",
        "data/temp.txt",
    );
    // Final result
    try text_utils.writeTransformsToFile(&text, output_filename);
}

fn showMeTimeLap(start_time: i64, comptime fmt_str: []const u8) i64 {
    const now = std.time.milliTimestamp();
    const duration = now - start_time;
    const mins = @intToFloat(f32, duration) / 60000;
    print("\n[ " ++ fmt_str ++ " Duration {} ms => {d:.2} mins ]\n\n", .{
        duration,
        mins,
    });
    return now;
}

pub fn main() anyerror!void {
    const start_time = std.time.milliTimestamp();
    print("\nStarted at {}\n", .{start_time});

    initConfigsFromArgs();

    tknz = .{ .max_lines = 0 };
    text = .{
        .init_allocator = std.heap.page_allocator,
        .keep_origin_amap = keep_origin_amap,
        .convert_mode = convert_mode,
    };

    try text.initFromFile(input_filename);
    defer text.deinit();
    const step0_time = showMeTimeLap(start_time, "Init Done!");

    // Init parser thread just before you run tknz.segment so it can catch up :)
    const thread = try std.Thread.spawn(.{}, text_utils.parseTokens, .{&text});

    try tknz.segment(&text);
    _ = showMeTimeLap(step0_time, "Step-1: Token segmenting finish!");

    // Câu giờ, đề phòng trường hợp thread vẫn chạy thì tận dụng tg để ghi 1 phần kq
    try write_out_samples();
    thread.join(); // Wait for sylabeling thread end

    // Then run one more time to finalize sylabeling process
    // since there may be some last tokens was skipped before thread end
    // because sylabeling too fast and timeout before new tokens come
    // It's a very rare-case happend when the sleep() call fail.
    text.tokens_number_finalized = true;
    text_utils.parseTokens(&text);
    const step2_time = showMeTimeLap(step0_time, "Step-2: Token parsing finish!");

    var step3_time: i64 = undefined;
    if (parse_n_grams) {
        print("\nParse and write n-gram ...\n", .{});
        gram = .{};
        gram.init(std.heap.page_allocator);
        defer gram.deinit();

        const thread1 = try std.Thread.spawn(
            .{},
            NGram.parseAndWriteBiTriGram,
            .{ &gram, text, "data/17-bi_gram.txt", "data/18-tri_gram.txt" },
        );

        const thread2 = try std.Thread.spawn(
            .{},
            NGram.parseAndWriteFourGram,
            .{ &gram, text, "data/19-four_gram.txt" },
        );

        print("\nWriting tokenized results to file ...\n", .{});
        try write_out_final();
        _ = showMeTimeLap(step2_time, "Writing tokenized results done!");

        thread1.join();
        thread2.join();

        step3_time = showMeTimeLap(step2_time, "Parse and write n-gram done!");
        //
    } else {
        //
        print("\nWriting tokenized results to file ...\n", .{});
        try write_out_final();
        step3_time = showMeTimeLap(step2_time, "Writing tokenized results done!");
    }

    print("\nWriting types to file ...\n", .{});
    try write_out_types();
    _ = showMeTimeLap(step3_time, "Writing types to file done!");

    _ = showMeTimeLap(start_time, "Total");
}
