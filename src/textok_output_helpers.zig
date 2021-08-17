const std = @import("std");
const Text = @import("./text_data_struct.zig").Text;
const text_utils = @import("./text_utils.zig");

const BYTES_PER_LINE = 80;
const PAD = "  ";

pub const TextokOutputHelpers = struct {
    //
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
        var i: usize = 0;
        while (it.next()) |kv| {
            if (skip_syllables and kv.value_ptr.isSyllable()) continue;
            tokens[i] = .{
                .value = kv.key_ptr.*,
                .count = kv.value_ptr.count,
                .is_syllable = kv.value_ptr.isSyllable(),
                .have_marktone = kv.value_ptr.haveMarkTone(),
            };
            i += 1;
        }
        tokens = tokens_[0..i];

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
        while (it.next()) |kv| {
            tokens[i] = .{
                .value = kv.key_ptr.*,
                .count = comptime switch (@TypeOf(types)) {
                    std.StringHashMap(Text.TypeInfo) => kv.value_ptr.count,
                    std.StringHashMap(u32) => kv.value_ptr.*,
                    else => unreachable,
                },
            };
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

        try freqs_wrt.flush();
        try types_wrt.flush();
    }

    pub fn write_text_tokens_to_file(text: *Text, filename: []const u8, max: usize) !void {
        var n = text.tokens_num;
        if (max > 0 and n > max) n = max;

        var file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();

        var wrt = std.io.bufferedWriter(file.writer());
        const writer = wrt.writer();

        var i: usize = 0;
        while (i < n) : (i += 1) {
            const token_info = text.tokens_infos.get(i);
            _ = try writer.write(token_info.trans_slice(text));
            if (token_info.attrs.spaceAfter()) _ = try writer.write(" ");
        }
        try wrt.flush();
    }

    pub fn write_transforms_to_file(text: *Text, filename: []const u8) !void {
        var file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();
        var wrt = Text.BufferedWriter{ .unbuffered_writer = file.writer() };
        const writer = wrt.writer();

        var i: usize = 0;
        text.prev_token_is_vi = false;

        while (i < text.tokens_num) : (i += 1)
            try text_utils.writeTokenInfo(text.tokens_infos.get(i), text, writer);

        try wrt.flush();
    }
};
