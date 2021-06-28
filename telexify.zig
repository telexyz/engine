const std = @import("std");
const print = std.debug.print;
const time = std.time;

const Text = @import("./src/text.zig").Text;
const Tokenizer = @import("./src/tokenizer.zig").Tokenizer;

fn write_tokens_to_file(tokens_map: std.StringHashMap(void), output_filename: []const u8) !void {
    var file = try std.fs.cwd().createFile(output_filename, .{});
    defer file.close();

    var count: usize = 0;
    var it = tokens_map.iterator();

    while (it.next()) |kv| {
        const token = kv.key_ptr.*;

        _ = try file.writer().write(token);
        count += 1;

        if (@rem(count, 12) == 0)
            _ = try file.writer().write("\n")
        else
            _ = try file.writer().write("   ");
    }
}

fn write_text_tokens_to_file(
    text: Text,
    output_filename: []const u8,
    max: usize,
) !void {
    var n = text.tokens_number;
    if (max > 0 and n > max) n = max;
    // Open files to write transformed input data (final result)
    var output_file = try std.fs.cwd().createFile(output_filename, .{});
    defer output_file.close();

    var i: usize = 0;

    while (i < n) : (i += 1) {
        const attrs = text.tokens_attrs[i];
        var token = text.tokens[i];

        if (attrs.category == .syllable) {
            token = text.transforms[i];
        }
        _ = try output_file.writer().write(token);

        if (attrs.surrounded_by_spaces == .both or
            attrs.surrounded_by_spaces == .right)
            _ = try output_file.writer().write(" ");
    }
}

fn write_transforms_to_file(
    text: Text,
    output_filename: []const u8,
    max: usize,
) !void {
    var n = text.transformed_bytes_len;
    if (max > 0 and n > max) n = max;
    // Open files to write transformed input data (final result)
    var output_file = try std.fs.cwd().createFile(output_filename, .{});
    defer output_file.close();
    _ = try output_file.writer().write(text.transformed_bytes[0..n]);
}

fn write_alphabet_types_to_files(
    alphabet_types: std.StringHashMap(Text.TypeInfo),
    marktone_filename: []const u8,
    alphabet_filename: []const u8,
) !void {
    var alphabet_file = try std.fs.cwd().createFile(alphabet_filename, .{});
    var marktone_file = try std.fs.cwd().createFile(marktone_filename, .{});
    defer alphabet_file.close();
    defer marktone_file.close();

    const max_token_len = 30;
    var buffer: [max_token_len + 15]u8 = undefined;
    const buff_slice = buffer[0..];

    var it = alphabet_types.iterator();
    while (it.next()) |kv| {
        if (max_token_len < kv.key_ptr.*.len) {
            print("TOKEN TOO LONG: {s}\n", .{kv.key_ptr.*});
            continue;
        }
        const result = try std.fmt.bufPrint(buff_slice, "{d:10}  {s}\n", .{ kv.value_ptr.*.count, kv.key_ptr.* });
        if (kv.value_ptr.*.category == .marktone) {
            _ = try marktone_file.writer().write(result);
        } else {
            _ = try alphabet_file.writer().write(result);
        }
    }
}

fn write_counts_to_file(counts: anytype, output_filename: []const u8) !void {
    var output_file = try std.fs.cwd().createFile(output_filename, .{});
    defer output_file.close();

    const max_token_len = 30;
    var buffer: [max_token_len + 15]u8 = undefined;
    const buff_slice = buffer[0..];

    var it = counts.iterator();
    while (it.next()) |kv| {
        if (max_token_len < kv.key_ptr.*.len) {
            print("TOKEN TOO LONG: {s}\n", .{kv.key_ptr.*});
            continue;
        }
        const count = if (comptime @TypeOf(counts) == std.StringHashMap(Text.TypeInfo)) kv.value_ptr.*.count else kv.value_ptr.*;

        const result = try std.fmt.bufPrint(buff_slice, "{d:10}  {s}\n", .{ count, kv.key_ptr.* });
        _ = try output_file.writer().write(result);
    }
}

pub fn main() anyerror!void {
    // Init a Tokenizer and a Text
    var tknz: Tokenizer = undefined;
    var text: Text = undefined;

    const start_time = time.milliTimestamp();
    print("\nstart_time {}\n", .{start_time});

    // Advance the iterator since we want to ignore the binary name.
    var args = std.process.args();
    _ = args.nextPosix();
    // Get input filename from args
    const input_filename = args.nextPosix() orelse {
        std.debug.warn("expected input_filename as first argument\n", .{});
        std.os.exit(1);
    };
    // Get output filename from args
    const output_filename = args.nextPosix() orelse {
        std.debug.warn("expected output_filename as second argument\n", .{});
        std.os.exit(1);
    };
    // Optional, get max_lines_count from args
    const max_lines_count: usize = if (args.nextPosix() != null) 1001 else 0;

    tknz = .{
        .init_allocator = std.heap.page_allocator,
        .max_lines_count = max_lines_count,
    };

    text = .{
        .init_allocator = std.heap.page_allocator,
    };

    try tknz.init();
    defer tknz.deinit();

    try text.initFromFile(input_filename);
    defer text.deinit();

    const init_ms = time.milliTimestamp() - start_time;
    const init_mins = @intToFloat(f32, init_ms) / 60000;
    print("\nInit Done! Duration {} ms => {d:.2} mins\n\n", .{ init_ms, init_mins });

    const thread = try std.Thread.spawn(Text.telexifyAlphabetTokens, &text);
    try tknz.segment(&text);

    const step1_ms = time.milliTimestamp() - start_time;
    const step1_mins = @intToFloat(f32, step1_ms) / 60000;

    print("\nStep-1: Token segmenting finish! Duration {} ms => {d:.2} mins\n\n", .{ step1_ms, step1_mins });

    // Write out stats
    try write_counts_to_file(
        text.nonalpha_types,
        "_output/05-nonalpha_types.txt",
    );
    try write_tokens_to_file(
        tknz.mixed_tokens_map,
        "_output/06-mixed_tokens.txt",
    );

    // Write sample of final output
    try write_text_tokens_to_file(
        text,
        "_output/07-telexified-777.txt",
        777,
    );

    // Wait for sylabeling thread end
    thread.wait();
    // Then run one more time to finalize sylabeling process
    // since there may be some last tokens was skipped before thread end
    // because sylabeling too fast and timeout before new tokens come
    // It's a very rare-case happend when the sleep() call fail.
    text.tokens_number_finalized = true;
    text.telexifyAlphabetTokens();
    text.removeSyllablesFromAlphabetTypes();

    const step2_ms = time.milliTimestamp() - start_time;
    const step2_mins = @intToFloat(f32, step2_ms) / 60000;
    print("\nStep-2:  Token syllabling finish! Duration {} ms => {d:.2} mins\n\n", .{ step2_ms, step2_mins });

    print("\nWriting final transformation to file ...\n", .{});

    try write_counts_to_file(
        text.syllable_types,
        "_output/01-syllable_types.txt",
    );
    try write_counts_to_file(
        text.syllower_types,
        "_output/02-syllower_types.txt",
    );
    try write_alphabet_types_to_files(
        text.alphabet_types,
        "_output/03-marktone_types.txt",
        "_output/04-alphabet_types.txt",
    );
    try write_transforms_to_file(
        text,
        "_output/08-telexified-888.txt",
        888_888,
    );
    // Final result
    try write_transforms_to_file(
        text,
        output_filename,
        0,
    );

    const end_time = time.milliTimestamp();
    print("\nend_time {}\n", .{end_time});
    const duration = end_time - start_time;
    const minutes = @intToFloat(f32, duration) / 60000;
    print("Duration {} ms => {d:.2} mins\n\n", .{ duration, minutes });
}
