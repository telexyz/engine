const std = @import("std");
const Text = @import("./text_data_struct.zig").Text;

const TOKENS_PER_LINE = 10;
const MAX_FREQ_LEN = 9;
const PAD = "  ";

pub const TextokOutputHelpers = struct {
    //
    const TokenInfo = struct {
        value: []const u8,
        count: u32,
        have_marktone: bool = false,
    };

    fn order_by_count_desc(context: void, a: TokenInfo, b: TokenInfo) bool {
        _ = context;
        return a.count > b.count;
    }

    pub fn write_too_long_tokens_to_file(text: Text, token_ids: std.ArrayList(usize), filename: []const u8) !void {
        var file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();
        var wrt = std.io.bufferedWriter(file.writer()).writer();
        for (token_ids.items) |index| {
            _ = try wrt.write(text.tokens[index]);
            _ = try wrt.write("\n");
        }
    }

    pub fn write_mktn_vs_0m0t_types_to_files(
        types: std.StringHashMap(Text.TypeInfo),
        freqs_mktn_filename: []const u8,
        freqs_0m0t_filename: []const u8,
        types_mktn_filename: []const u8,
        types_0m0t_filename: []const u8,
    ) !void {
        var freqs_mktn_file = try std.fs.cwd().createFile(freqs_mktn_filename, .{});
        var freqs_0m0t_file = try std.fs.cwd().createFile(freqs_0m0t_filename, .{});
        var types_mktn_file = try std.fs.cwd().createFile(types_mktn_filename, .{});
        var types_0m0t_file = try std.fs.cwd().createFile(types_0m0t_filename, .{});
        defer freqs_mktn_file.close();
        defer freqs_0m0t_file.close();
        defer types_mktn_file.close();
        defer types_0m0t_file.close();

        // Init 2 counters and the main iterator
        var n1: u32 = 0;
        var n2: u32 = 0;
        var it = types.iterator();
        // Init 4 writers
        const fm_wrt = std.io.bufferedWriter(freqs_mktn_file.writer()).writer();
        const f0_wrt = std.io.bufferedWriter(freqs_0m0t_file.writer()).writer();
        const tm_wrt = std.io.bufferedWriter(types_mktn_file.writer()).writer();
        const t0_wrt = std.io.bufferedWriter(types_0m0t_file.writer()).writer();

        // Init
        var tokens_list = try std.ArrayList(TokenInfo).initCapacity(std.heap.page_allocator, types.count());
        defer tokens_list.deinit();
        // Add items
        while (it.next()) |kv| {
            try tokens_list.append(.{
                .value = kv.key_ptr.*,
                .count = kv.value_ptr.count,
                .have_marktone = kv.value_ptr.haveMarkTone(),
            });
        }
        // Sort by count desc
        std.sort.sort(TokenInfo, tokens_list.items, {}, order_by_count_desc);

        for (tokens_list.items) |token| {
            if (token.have_marktone) {
                // write freq and token pair to file
                _ = try fm_wrt.print("{d} {s}\n", .{ token.count, token.value });
                // write token to file
                n1 += 1;
                _ = try tm_wrt.write(token.value);
                _ = try tm_wrt.write(if (@rem(n1, TOKENS_PER_LINE) == 0) "\n" else PAD);
            } else {
                // write freq and token pair to file
                _ = try f0_wrt.print("{d} {s}\n", .{ token.count, token.value });
                // write token to file
                n2 += 1;
                _ = try t0_wrt.write(token.value);
                _ = try t0_wrt.write(if (@rem(n2, TOKENS_PER_LINE) == 0) "\n" else PAD);
            }
        }
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
        const freqs_wrt = std.io.bufferedWriter(freqs_file.writer()).writer();
        const types_wrt = std.io.bufferedWriter(types_file.writer()).writer();

        // Init
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
            _ = try freqs_wrt.print("{d} {s}\n", .{ token.count, token.value });
            // write token to file
            _ = try types_wrt.write(token.value);
            _ = try types_wrt.write(if (@rem(i + 1, TOKENS_PER_LINE) == 0) "\n" else PAD);
        }
    }

    pub fn write_text_tokens_to_file(text: Text, output_filename: []const u8, max: usize) !void {
        var n = text.tokens_number;
        if (max > 0 and n > max) n = max;
        // Open files to write transformed input data (final result)
        var output_file = try std.fs.cwd().createFile(output_filename, .{});
        defer output_file.close();

        var i: usize = 0;
        const wrt = std.io.bufferedWriter(output_file.writer()).writer();

        while (i < n) : (i += 1) {
            _ = try wrt.write(text.tokens[i]);

            const attrs = text.tokens_attrs[i];
            if (attrs.surrounded_by_spaces == .both or
                attrs.surrounded_by_spaces == .right)
                _ = try wrt.write(" ");
        }
    }

    pub fn write_transforms_to_file(
        text: Text,
        output_filename: []const u8,
        max: usize,
    ) !void {
        var n = text.transformed_bytes_len;
        if (max > 0 and n > max) n = max;
        // Open files to write transformed input data (final result)
        var output_file = try std.fs.cwd().createFile(output_filename, .{});
        defer output_file.close();
        var wrt = std.io.bufferedWriter(output_file.writer()).writer();
        // const wrt = output_file.writer();
        _ = try wrt.write(text.transformed_bytes[0..n]);
    }
};
