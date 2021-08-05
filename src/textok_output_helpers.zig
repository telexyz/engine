const std = @import("std");
const Text = @import("./text_data_struct.zig").Text;

const TOKENS_PER_LINE = 10;
const MAX_FREQ_LEN = 9;
const PAD = "    ";

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

    pub fn write_too_long_tokens_to_file(
        tokens: std.ArrayList([]const u8),
        filename: []const u8,
        filename2: []const u8,
    ) !void {
        var file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();
        var wrt = std.io.bufferedWriter(file.writer());

        var file2 = try std.fs.cwd().createFile(filename2, .{});
        defer file2.close();
        var wrt2 = std.io.bufferedWriter(file2.writer());

        const lookForMarkTone = (filename2.len > 18);
        var is_marktone = false;

        for (tokens.items) |token| {
            if (lookForMarkTone) {
                for (token) |byte| {
                    if (byte < 'A' or byte > 'z') {
                        is_marktone = true;
                        break;
                    }
                }
            }

            if (is_marktone) {
                _ = try wrt2.writer().write(token);
                _ = try wrt2.writer().write("\n");
                is_marktone = false;
            } else {
                _ = try wrt.writer().write(token);
                _ = try wrt.writer().write("\n");
            }
        }
        try wrt.flush();
        try wrt2.flush();
    }

    pub fn write_mktn_vs_0m0t_types_to_files(
        types: std.StringHashMap(Text.TypeInfo),
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
        const pad = if (@rem(count.*, TOKENS_PER_LINE) == 0) "\n" else PAD;
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
            const pad = if (@rem(i + 1, TOKENS_PER_LINE) == 0) "\n" else PAD;
            _ = try types_wrt.writer().print("{s}{s}", .{ token.value, pad });
        }

        try freqs_wrt.flush();
        try types_wrt.flush();
    }

    pub fn write_text_tokens_to_file(text: Text, output_filename: []const u8, max: usize) !void {
        var n = text.tokens_number;
        if (max > 0 and n > max) n = max;
        // Open files to write transformed input data (final result)
        var output_file = try std.fs.cwd().createFile(output_filename, .{});
        defer output_file.close();

        var wrt = std.io.bufferedWriter(output_file.writer());
        var curr: usize = 0;
        var next: usize = 0;

        var i: usize = 0;
        while (i < text.tokens_number) : (i += 1) {
            const token_info = text.tokens_infos[i];
            curr = next + token_info.skip;
            next = curr + token_info.len;
            _ = try wrt.writer().write(text.input_bytes[curr..next]);

            if (token_info.attrs.surrounded_by_spaces == .both or
                token_info.attrs.surrounded_by_spaces == .right)
                _ = try wrt.writer().write(" ");
        }
        try wrt.flush();
    }

    pub fn write_transforms_to_file(text: Text, filename: []const u8) !void {
        var file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();
        var wrt = std.io.bufferedWriter(file.writer());
        // const wrt = output_file.writer();
        _ = try wrt.writer().write(text.transformed_bytes);
        try wrt.flush();
    }
};
