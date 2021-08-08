const std = @import("std");
const Text = @import("./text_data_struct.zig").Text;

const TOKENS_PER_LINE = 10;
const MAX_FREQ_LEN = 9;
const PAD = "   ";

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
        var n1: u32 = 0;
        var n2: u32 = 0;
        var it = types.iterator();
        // Init 4 writers
        var fm_wrt = std.io.bufferedWriter(fm_file.writer());
        var f0_wrt = std.io.bufferedWriter(f0_file.writer());
        var tm_wrt = std.io.bufferedWriter(tm_file.writer());
        var t0_wrt = std.io.bufferedWriter(t0_file.writer());

        // Init a list of token and it's count
        var tokens_list = try std.ArrayList(TokenInfo).initCapacity(std.heap.page_allocator, types.count());
        defer tokens_list.deinit();

        // Add items
        while (it.next()) |kv| {
            if (skip_syllables and kv.value_ptr.isSyllable()) continue;
            try tokens_list.append(.{
                .value = kv.key_ptr.*,
                .count = kv.value_ptr.count,
                .is_syllable = kv.value_ptr.isSyllable(),
                .have_marktone = kv.value_ptr.haveMarkTone(),
            });
        }

        // Sort by count desc
        std.sort.sort(TokenInfo, tokens_list.items, {}, order_by_count_desc);

        for (tokens_list.items) |token| {
            if (!token.have_marktone) {
                if (token.is_syllable) {
                    // double check marktone for syllable
                    switch (token.value[token.value.len - 1]) {
                        's', 'f', 'r', 'x', 'j', 'w', 'z' => {
                            // have marktone
                            try writeToken(token, &fm_wrt, &tm_wrt, &n1);
                            continue;
                        },
                        else => {},
                    }
                }
                try writeToken(token, &f0_wrt, &t0_wrt, &n2);
            } else {
                try writeToken(token, &fm_wrt, &tm_wrt, &n1);
            }
        }

        try fm_wrt.flush();
        try f0_wrt.flush();
        try tm_wrt.flush();
        try t0_wrt.flush();
    }

    fn writeToken(token: TokenInfo, freqs_wrt: anytype, types_wrt: anytype, count: *u32) !void {
        // write freq and token pair to file
        _ = try freqs_wrt.writer().print("{d} {s}\n", .{ token.count, token.value });
        count.* += 1;
        // write token to file
        const pad = if (@rem(count.*, TOKENS_PER_LINE) == 0) "\n\n" else PAD;
        _ = try types_wrt.writer().print("{s}{s}", .{ token.value, pad });
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

        // Init list
        var tokens_list = try std.ArrayList(TokenInfo).initCapacity(std.heap.page_allocator, types.count());
        defer tokens_list.deinit();

        // Add items
        var it = types.iterator();
        while (it.next()) |kv| {
            try tokens_list.append(.{
                .value = kv.key_ptr.*,
                .count = comptime switch (@TypeOf(types)) {
                    std.StringHashMap(Text.TypeInfo) => kv.value_ptr.count,
                    std.StringHashMap(u32) => kv.value_ptr.*,
                    else => unreachable,
                },
            });
        }

        // Sort by count desc
        std.sort.sort(TokenInfo, tokens_list.items, {}, order_by_count_desc);

        for (tokens_list.items) |token, i| {
            // write freq and token pair to file
            _ = try freqs_wrt.writer().print("{d} {s}\n", .{ token.count, token.value });
            // write token to file
            const pad = if (@rem(i + 1, TOKENS_PER_LINE) == 0) "\n\n" else PAD;
            _ = try types_wrt.writer().print("{s}{s}", .{ token.value, pad });
        }

        try freqs_wrt.flush();
        try types_wrt.flush();
    }

    pub fn write_text_tokens_to_file(text: *Text, filename: []const u8, max: usize) !void {
        var n = text.tokens_number;
        if (max > 0 and n > max) n = max;

        var file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();

        var wrt = std.io.bufferedWriter(file.writer());
        const writer = wrt.writer();

        var i: usize = 0;
        while (i < n) : (i += 1) {
            const token_info = text.tokens_infos[i];
            _ = try writer.write(token_info.trans_slice(text));
            if (token_info.attrs.spaceAfter()) _ = try writer.write(" ");
        }
        try wrt.flush();
    }

    pub fn write_transforms_to_file(text: *Text, filename: []const u8) !void {
        var file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();

        var wrt = std.io.bufferedWriter(file.writer());
        const writer = wrt.writer();

        var i: usize = 0;
        text.prev_token_is_vi = false;

        while (i < text.tokens_number) : (i += 1)
            try writeTokenInfo(text.tokens_infos[i], text, writer);

        try wrt.flush();
    }

    pub inline fn writeTokenInfo(tk_info: Text.TokenInfo, text: *Text, writer: anytype) !void {
        if (text.keep_origin_amap) {
            // Write all tokens
            _ = try writer.write(tk_info.trans_slice(text));
            if (tk_info.attrs.spaceAfter()) _ = try writer.write(" ");
            return;
        }

        // Write syllables only
        if (tk_info.isSyllable()) {
            _ = try writer.write(tk_info.trans_slice(text));
            _ = try writer.write(" ");
            text.prev_token_is_vi = true;
            //
        } else if (text.prev_token_is_vi) {
            //
            const trans_ptr = tk_info.trans_ptr(text);

            const is_syllable_joiner = tk_info.attrs.surrounded_by_spaces == .none and trans_ptr[1] == 0 and (trans_ptr[0] == '_' or trans_ptr[0] == '+');

            if (!is_syllable_joiner) {
                _ = try writer.write("\n");
                text.prev_token_is_vi = false;
            }
        }
    }
    //
};
