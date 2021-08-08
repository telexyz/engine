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
        &text,
        "data/07-tokens_sample.txt",
        77_777,
    );
}

fn write_out_types() !void {
    try TextokOutput.write_mktn_vs_0m0t_types_to_files(
        text.syllable_types,
        false, // don't skip syllable
        "data/01-syllmark_freqs.txt",
        "data/02-syll0m0t_freqs.txt",
        "data/11-syllmark_types.txt",
        "data/12-syll0m0t_types.txt",
    );
    try TextokOutput.write_types_to_files(
        text.syllow00_types,
        "data/03-syllow00_freqs.txt",
        "data/13-syllow00_types.txt",
    );
    try TextokOutput.write_mktn_vs_0m0t_types_to_files(
        text.alphabet_types,
        true, // skip syllable
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

fn showMeTimeLap(start_time: i64, comptime fmt_str: []const u8) i64 {
    const now = std.time.milliTimestamp();
    const duration = now - start_time;
    const mins = @intToFloat(f32, duration) / 60000;
    print("\n(( " ++ fmt_str ++ " Duration {d:.2} mins ))\n\n", .{mins});
    return now;
}

fn write_results(step2_time: i64) !void {
    // In the mean time writing parsed results out, and free amap mem asap
    print("\nWriting types to files ...\n", .{});
    try text.processAlphabetTypes();
    try write_out_types();
    _ = showMeTimeLap(step2_time, "Writing types to files done!");

    // print("\nWriting tokenized results to {s} ...\n", .{output_filename});
    // try TextokOutput.write_transforms_to_file(&text, output_filename);
    // _ = showMeTimeLap(step2_time, "Writing tokenized results done!");
}

pub fn main() anyerror!void {
    const start_time = std.time.milliTimestamp();

    initConfigsFromArgs();
    print("\nStart tokenize {s} ...\n", .{input_filename});

    tknz = .{ .max_lines = 0 };
    text = .{
        .init_allocator = std.heap.page_allocator,
        .keep_origin_amap = keep_origin_amap,
        .convert_mode = convert_mode,
    };

    try text.initFromFile(input_filename);
    defer text.deinit();
    const step0_time = showMeTimeLap(start_time, "Init Done!");

    var file = try std.fs.cwd().createFile(output_filename, .{});
    defer file.close();
    const file_wtr = file.writer();
    var buff_wrt = Text.BufferedWriter{
        .unbuffered_writer = file_wtr,
    };
    text.writer = buff_wrt.writer();

    // Init parser thread just before you run tknz.segment so it can catch up :)
    // const thread = try std.Thread.spawn(.{}, text_utils.parseTokens, .{&text});
    // const then_parse_syllable = false;
    const then_parse_syllable = true;

    try tknz.segment(&text, then_parse_syllable); // parse syllable on-the-fly
    text.free_input_bytes();
    try buff_wrt.flush();
    try write_out_samples();

    // _ = showMeTimeLap(step0_time, "STEP 1: Token segmenting finish!");
    // thread.join(); // Wait for sylabeling thread end
    // if (text.parsed_tokens_number != text.tokens_number) {
    //     std.debug.print("!!! PARSER NOT REACH THE LAST TOKEN !!!", .{});
    //     unreachable;
    // }

    var step2_time = showMeTimeLap(step0_time, "STEP 1+2: Segment & parse tokens finish!");
    if (parse_n_grams) {
        print("\nSTEP 3: Parse and write n-gram ...\n", .{});
        gram = .{};
        gram.init(std.heap.page_allocator);
        defer gram.deinit();

        const thread1 = try std.Thread.spawn(.{}, NGram.parseAndWriteBiTriGram, .{ &gram, text, "data/17-bi_gram.txt", "data/18-tri_gram.txt" });
        // const thread2 = try std.Thread.spawn(.{}, NGram.parseAndWriteFourGram, .{ &gram, text, "data/19-four_gram.txt" });

        try write_results(step2_time);
        gram.parseAndWriteFourGram(text, "data/19-four_gram.txt");

        thread1.join();
        // thread2.join();
        _ = showMeTimeLap(step2_time, "STEP 3: Parse and write n-gram done!");
        //
    } else {
        //
        try write_results(step2_time);
    }
    _ = showMeTimeLap(start_time, "FINISHED: Total");
}
