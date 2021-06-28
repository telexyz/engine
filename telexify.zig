const std = @import("std");
const print = std.debug.print;

const Text = @import("./src/text.zig").Text;
const TextokOutputHelpers = @import("./src/textok_output_helpers.zig").TextokOutputHelpers;
const Tokenizer = @import("./src/tokenizer.zig").Tokenizer;

// Init a Tokenizer and a Text
var tknz: Tokenizer = undefined;
var text: Text = undefined;

var input_filename: []const u8 = undefined;
var output_filename: []const u8 = undefined;
var max_lines_count: usize = undefined;

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
    // Optional, get max_lines_count from args
    max_lines_count = if (args.nextPosix() != null) 1001 else 0;
}

fn initTexTok() !void {
    tknz = .{
        .init_allocator = std.heap.page_allocator,
        .max_lines_count = max_lines_count,
    };

    text = .{
        .init_allocator = std.heap.page_allocator,
    };

    try tknz.init();
    try text.initFromFile(input_filename);
}

fn write_out_results1() !void {
    try TextokOutputHelpers.write_counts_to_file(
        text.nonalpha_types,
        "_output/05-nonalpha_types.txt",
    );
    try TextokOutputHelpers.write_tokens_to_file(
        tknz.mixed_tokens_map,
        "_output/06-mixed_tokens.txt",
    );

    // Write sample of final output
    try TextokOutputHelpers.write_text_tokens_to_file(
        text,
        "_output/07-telexified-777.txt",
        777,
    );
}

fn write_out_results2() !void {
    try TextokOutputHelpers.write_counts_to_file(
        text.syllable_types,
        "_output/01-syllable_types.txt",
    );
    try TextokOutputHelpers.write_counts_to_file(
        text.syllower_types,
        "_output/02-syllower_types.txt",
    );
    try TextokOutputHelpers.write_alphabet_types_to_files(
        text.alphabet_types,
        "_output/03-marktone_types.txt",
        "_output/04-alphabet_types.txt",
    );
    try TextokOutputHelpers.write_transforms_to_file(
        text,
        "_output/08-telexified-888.txt",
        888_888,
    );
    // Final result
    try TextokOutputHelpers.write_transforms_to_file(
        text,
        output_filename,
        0,
    );
}

fn showDuration(start_time: i64, comptime fmt_str: []const u8) i64 {
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

    try initTexTok();
    defer tknz.deinit();
    defer text.deinit();

    var time = showDuration(start_time, "Init Done!");

    const thread = try std.Thread.spawn(Text.telexifyAlphabetTokens, &text);
    try tknz.segment(&text);

    time = showDuration(time, "Step-1: Token segmenting finish!");

    // Câu giờ, đề phòng trường hợp thread vẫn chạy thì tận dụng tg để ghi 1 phần kq
    try write_out_results1();

    // Wait for sylabeling thread end
    thread.wait();
    // Then run one more time to finalize sylabeling process
    // since there may be some last tokens was skipped before thread end
    // because sylabeling too fast and timeout before new tokens come
    // It's a very rare-case happend when the sleep() call fail.
    text.tokens_number_finalized = true;
    text.telexifyAlphabetTokens();
    text.removeSyllablesFromAlphabetTypes();

    time = showDuration(time, "Step-2: Token syllabling finish!");

    print("\nWriting final transformation to file ...\n", .{});
    try write_out_results2();

    time = showDuration(time, "Writing final output done!");

    _ = showDuration(start_time, "Total");
}
