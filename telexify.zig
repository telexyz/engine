const std = @import("std");
const print = std.debug.print;

const Text = @import("./src/text_data_struct.zig").Text;
const TextokOutputHelpers = @import("./src/textok_output_helpers.zig").TextokOutputHelpers;
const Tokenizer = @import("./src/tokenizer.zig").Tokenizer;
const text_utils = @import("./src/text_utils.zig");

// Init a Tokenizer and a Text
var tknz: Tokenizer = undefined;
var text: Text = undefined;

var input_filename: []const u8 = undefined;
var output_filename: []const u8 = undefined;
var max_lines: usize = undefined;

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
    max_lines = if (args.nextPosix() != null) 1001 else 0;
}

fn write_out_results1() !void {
    try TextokOutputHelpers.write_types_to_files(
        text.nonalpha_types,
        "output/06-nonalpha_freqs.txt",
        "output/16-nonalpha_types.txt",
    );
    // Write sample of final output to preview
    try TextokOutputHelpers.write_tokens_to_file(
        text,
        "output/07-tokens_sample.txt",
        777,
    );
    try TextokOutputHelpers.write_transforms_to_file(
        text,
        "output/08-telexified_sample.txt",
        888_888,
    );
}

fn write_out_types() !void {
    try TextokOutputHelpers.write_mark_vs_norm_types_to_files(
        text.syllable_types,
        "output/01-syllmark_freqs.txt",
        "output/02-syllable_freqs.txt",
        "output/11-syllmark_types.txt",
        "output/12-syllable_types.txt",
    );
    try TextokOutputHelpers.write_types_to_files(
        text.syllower_types,
        "output/03-syllower_freqs.txt",
        "output/13-syllower_types.txt",
    );
    try TextokOutputHelpers.write_mark_vs_norm_types_to_files(
        text.alphabet_types,
        "output/04-alphmark_freqs.txt",
        "output/05-alphabet_freqs.txt",
        "output/14-alphmark_types.txt",
        "output/15-alphabet_types.txt",
    );
}

fn write_out_tokens_and_final() !void {
    // Final result
    try TextokOutputHelpers.write_transforms_to_file(
        text,
        output_filename,
        0,
    );

    try TextokOutputHelpers.write_too_long_tokens_to_file(
        text,
        text.alphabet_too_long_token_ids,
        "output/09-alphabet_too_long_tokens.txt",
    );
    try TextokOutputHelpers.write_too_long_tokens_to_file(
        text,
        text.nonalpha_too_long_token_ids,
        "output/10-nonalpha_too_long_tokens.txt",
    );
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
    text = .{
        .init_allocator = std.heap.page_allocator,
        .telexified_all_tokens = true,
    };
    tknz = .{ .max_lines = max_lines };

    try text.initFromFile(input_filename);
    defer text.deinit();
    const step0_time = showMeTimeLap(start_time, "Init Done!");

    const thread = try std.Thread.spawn(text_utils.telexifyAlphabetTokens, &text);
    try tknz.segment(&text);
    _ = showMeTimeLap(step0_time, "Step-1: Token segmenting finish!");
    // Câu giờ, đề phòng trường hợp thread vẫn chạy thì tận dụng tg để ghi 1 phần kq
    try write_out_results1();
    // Wait for sylabeling thread end
    thread.wait();
    if (!text.tokens_number_finalized) {
        // Then run one more time to finalize sylabeling process
        // since there may be some last tokens was skipped before thread end
        // because sylabeling too fast and timeout before new tokens come
        // It's a very rare-case happend when the sleep() call fail.
        text.tokens_number_finalized = true;
        text_utils.telexifyAlphabetTokens(&text);
    }
    const step2_time = showMeTimeLap(step0_time, "Step-2: Token syllabling finish!");

    print("\nWriting types to file ...\n", .{});
    try write_out_types();
    const types_time = showMeTimeLap(step2_time, "Writing types to file done!");

    print("\nWriting tokens and final transform to file ...\n", .{});
    try write_out_tokens_and_final();
    _ = showMeTimeLap(types_time, "Writing tokens and final transform done!");

    _ = showMeTimeLap(start_time, "Total");
}
