const std = @import("std");
const Text = @import("./text_data_struct.zig").Text;
const text_utils = @import("./text_utils.zig");

const BYTES_PER_LINE = 80;
const PAD = "  ";

const TokenInfo = struct {
    value: []const u8,
    count: u32,
    is_syllable: bool = false,
    have_marktone: bool = false,
};

fn order_by_count_desc(context: void, a: TokenInfo, b: TokenInfo) bool {
    _ = context;
    return a.count > b.count;
}

fn order_by_len_desc(context: void, a: TokenInfo, b: TokenInfo) bool {
    _ = context;
    return a.value.len > b.value.len;
}

pub fn write_mktn_vs_0m0t_types_to_files(
    types: std.StringHashMap(Text.TypeInfo),
    skip_syllables: bool,
    freqs_mktn_filename: []const u8,
    freqs_0m0t_filename: []const u8,
    types_mktn_filename: []const u8,
    types_0m0t_filename: []const u8,
) !void {
    var fm_file = try std.fs.cwd().createFile(freqs_mktn_filename, .{});
    var f0_file = try std.fs.cwd().createFile(freqs_0m0t_filename, .{});
    var tm_file = try std.fs.cwd().createFile(types_mktn_filename, .{});
    var t0_file = try std.fs.cwd().createFile(types_0m0t_filename, .{});

    defer fm_file.close();
    defer f0_file.close();
    defer tm_file.close();
    defer t0_file.close();

    // Init 2 counters and the main iterator
    var n0: usize = 0;
    var nm: usize = 0;
    var it = types.iterator();

    // Init 4 buffered writers
    var fm_wrt = std.io.bufferedWriter(fm_file.writer());
    var f0_wrt = std.io.bufferedWriter(f0_file.writer());
    var tm_wrt = std.io.bufferedWriter(tm_file.writer());
    var t0_wrt = std.io.bufferedWriter(t0_file.writer());

    // Init 4 writers
    var fm_writer = fm_wrt.writer();
    var f0_writer = f0_wrt.writer();
    var tm_writer = tm_wrt.writer();
    var t0_writer = t0_wrt.writer();

    // Init a list of TokenInfo
    var tokens_ = try std.heap.page_allocator.alloc(TokenInfo, types.count());
    defer std.heap.page_allocator.free(tokens_);
    var tokens = tokens_[0..];

    // Add items to tokens
    var tokens_count: usize = 0;
    var i: usize = 0;

    while (it.next()) |kv| {
        if (skip_syllables and kv.value_ptr.isSyllable()) {
            continue;
        }
        tokens[i] = .{
            .value = kv.key_ptr.*,
            .count = kv.value_ptr.count,
            .is_syllable = kv.value_ptr.isSyllable(),
            .have_marktone = kv.value_ptr.haveMarkTone(),
        };
        tokens_count += kv.value_ptr.count;
        i += 1;
    }
    tokens = tokens_[0..i];

    std.debug.print("\n\n >> `{s}` + `{s}` NUMBER OF TOKENS {d} <<\n\n", .{ freqs_mktn_filename, freqs_0m0t_filename, tokens_count });

    // Sort by type count desc
    std.sort.sort(TokenInfo, tokens, {}, order_by_count_desc);
    //
    for (tokens) |token| {
        // if (token.have_marktone) {
        if (token.have_marktone) {
            try fm_writer.print("{d} {s}\n", .{ token.count, token.value });
        } else {
            try f0_writer.print("{d} {s}\n", .{ token.count, token.value });
        }
    }

    // Sort by type length desc
    std.sort.sort(TokenInfo, tokens, {}, order_by_len_desc);
    const tokens_len_1 = tokens.len - 1;
    //
    for (tokens) |token, j| {
        const nn = if (j < tokens_len_1) tokens[j + 1].value.len else 0;
        var pad = PAD;
        // if (token.have_marktone) {
        if (token.have_marktone) {
            nm += token.value.len + PAD.len;
            if (nm + nn >= BYTES_PER_LINE) {
                pad = "\n\n";
                nm = 0;
            }
            try tm_writer.print("{s}{s}", .{ token.value, pad });
        } else {
            n0 += token.value.len + PAD.len;
            if (n0 + nn >= BYTES_PER_LINE) {
                pad = "\n\n";
                n0 = 0;
            }
            try t0_writer.print("{s}{s}", .{ token.value, pad });
        }
    }

    try fm_wrt.flush();
    try f0_wrt.flush();
    try tm_wrt.flush();
    try t0_wrt.flush();
}

pub fn write_types_to_files(
    types: anytype,
    freqs_filename: []const u8,
    types_filename: []const u8,
) !void {
    var freqs_file = try std.fs.cwd().createFile(freqs_filename, .{});
    var types_file = try std.fs.cwd().createFile(types_filename, .{});
    defer freqs_file.close();
    defer types_file.close();

    var freqs_wrt = std.io.bufferedWriter(freqs_file.writer());
    var types_wrt = std.io.bufferedWriter(types_file.writer());

    var freqs_writer = freqs_wrt.writer();
    var types_writer = types_wrt.writer();

    // Init a list of TokenInfo
    var tokens_ = try std.heap.page_allocator.alloc(TokenInfo, types.count());
    defer std.heap.page_allocator.free(tokens_);
    var tokens = tokens_[0..];

    // Add items to tokens
    var i: usize = 0;
    var it = types.iterator();
    var mono_len_count: usize = 0;
    var count: u32 = undefined;

    while (it.next()) |kv| {
        count = comptime switch (@TypeOf(types)) {
            std.StringHashMap(Text.TypeInfo) => kv.value_ptr.count,
            std.StringHashMap(u32) => kv.value_ptr.*,
            else => unreachable,
        };
        tokens[i] = .{
            .value = kv.key_ptr.*,
            .count = count,
        };
        if (kv.key_ptr.len == 1) mono_len_count += count;
        i += 1;
    }
    tokens = tokens_[0..i];

    // Sort by type count desc
    std.sort.sort(TokenInfo, tokens, {}, order_by_count_desc);
    for (tokens) |token| {
        try freqs_writer.print("{d} {s}\n", .{ token.count, token.value });
    }

    // Sort by type len desc
    std.sort.sort(TokenInfo, tokens, {}, order_by_len_desc);
    const tokens_len_1 = tokens.len - 1;

    var n: usize = 0;
    for (tokens) |token, j| {
        n += token.value.len + PAD.len;
        const nn = if (j < tokens_len_1) tokens[j + 1].value.len else 0;
        var pad = PAD;
        if (n + nn >= BYTES_PER_LINE) {
            pad = "\n\n";
            n = 0;
        }
        try types_writer.print("{s}{s}", .{ token.value, pad });
    }

    std.debug.print("\n>>> {s} types have only 1 char: {d} <<<\n", .{ freqs_filename, mono_len_count });

    try freqs_wrt.flush();
    try types_wrt.flush();
}

pub fn write_transforms_to_file(
    text: *Text,
    txt_filename: []const u8,
    no_vi_filename: []const u8,
    low_vi_filename: []const u8,
) !void {
    //
    var buffer: [100]u8 = undefined;
    // Extend .cdx to txt_filename
    std.mem.copy(u8, buffer[0..], txt_filename);
    std.mem.copy(u8, buffer[txt_filename.len..], ".cdx");
    const cdx_filename = buffer[0 .. txt_filename.len + 4];

    var txt_file = try std.fs.cwd().createFile(txt_filename, .{});
    var cdx_file = try std.fs.cwd().createFile(cdx_filename, .{});
    var low_file = try std.fs.cwd().createFile(low_vi_filename, .{});
    var nvi_file = try std.fs.cwd().createFile(no_vi_filename, .{});

    defer txt_file.close();
    defer cdx_file.close();
    defer low_file.close();
    defer nvi_file.close();

    var txt_wrt = Text.BufferedWriter{ .unbuffered_writer = txt_file.writer() };
    const txt_writer = txt_wrt.writer();

    var cdx_wrt = Text.BufferedWriter{ .unbuffered_writer = cdx_file.writer() };
    const cdx_writer = cdx_wrt.writer();

    var low_wrt = Text.BufferedWriter{ .unbuffered_writer = low_file.writer() };
    const low_writer = low_wrt.writer();

    var nvi_wrt = Text.BufferedWriter{ .unbuffered_writer = nvi_file.writer() };
    const nvi_writer = nvi_wrt.writer();

    var i: usize = 0;

    while (i < text.tokens_num) : (i += 1) {
        if (text_utils.writeTokenInfo(text.tokens_infos.get(i), text)) {
            if (text.line_bytes_len == 1) continue;

            text.line_bytes[text.line_bytes_len] = '\n';
            text.code_bytes[text.code_bytes_len] = '\n';

            if (text.line_vi_tokens_len == 0) {
                // Không có tiếng Việt
                _ = try nvi_writer.write(text.line_bytes[0 .. text.line_bytes_len + 1]);
                //
            } else if (text.line_bytes_len > 2 + text.line_vi_tokens_len * 2) {
                // Tiếng Việt chiếm thiểu số
                _ = try low_writer.write(text.line_bytes[0 .. text.line_bytes_len + 1]);
                // write to cdx so there is no-diff in n-gram count
                _ = try txt_writer.write(text.line_bytes[0 .. text.line_bytes_len + 1]);
                _ = try cdx_writer.write(text.code_bytes[0 .. text.code_bytes_len + 1]);
            } else {
                // Tiếng Việt chiếm đa số
                _ = try txt_writer.write(text.line_bytes[0 .. text.line_bytes_len + 1]);
                _ = try cdx_writer.write(text.code_bytes[0 .. text.code_bytes_len + 1]);
            }
            // Reset at last
            text.initNewLine();
        }
    }

    try txt_wrt.flush();
    try cdx_wrt.flush();
    try low_wrt.flush();
    try nvi_wrt.flush();
}
