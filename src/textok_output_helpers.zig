const std = @import("std");
const Text = @import("./text_data_struct.zig").Text;

const TOKENS_PER_LINE = 10;
const PAD = "  ";

pub const TextokOutputHelpers = struct {
    pub fn write_too_long_tokens_to_file(text: Text, token_ids: std.ArrayList(usize), filename: []const u8) !void {
        var file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();
        for (token_ids.items) |index| {
            _ = try file.writer().write(text.tokens[index]);
            _ = try file.writer().write("\n");
        }
    }

    pub fn write_mark_vs_norm_types_to_files(
        types: std.StringHashMap(Text.TypeInfo),
        freqs_mark_filename: []const u8,
        freqs_norm_filename: []const u8,
        types_mark_filename: []const u8,
        types_norm_filename: []const u8,
    ) !void {
        var freqs_mark_file = try std.fs.cwd().createFile(freqs_mark_filename, .{});
        var freqs_norm_file = try std.fs.cwd().createFile(freqs_norm_filename, .{});
        var types_mark_file = try std.fs.cwd().createFile(types_mark_filename, .{});
        var types_norm_file = try std.fs.cwd().createFile(types_norm_filename, .{});
        defer freqs_mark_file.close();
        defer freqs_norm_file.close();
        defer types_mark_file.close();
        defer types_norm_file.close();

        var buffer: [Text.MAX_TOKEN_LEN + 15]u8 = undefined;
        const buff_slice = buffer[0..];

        // Init 2 counters and the main iterator
        var n1: u32 = 0;
        var n2: u32 = 0;
        var it = types.iterator();
        // Init 4 writers
        var fm_wrt = freqs_mark_file.writer();
        var fn_wrt = freqs_norm_file.writer();
        var tm_wrt = types_mark_file.writer();
        var tn_wrt = types_norm_file.writer();

        while (it.next()) |kv| {
            const token = kv.key_ptr.*;
            const result = try std.fmt.bufPrint(buff_slice, "{d:10}  {s}\n", .{ kv.value_ptr.count, token });

            if (kv.value_ptr.haveMarkTone()) {
                // write freq and token pair to file
                _ = try fm_wrt.write(result);
                // write token to file
                n1 += 1;
                _ = try tm_wrt.write(token);
                _ = try tm_wrt.write(if (@rem(n1, TOKENS_PER_LINE) == 0) "\n" else PAD);
            } else {
                // write freq and token pair to file
                _ = try fn_wrt.write(result);
                // write token to file
                n2 += 1;
                _ = try tn_wrt.write(token);
                _ = try tn_wrt.write(if (@rem(n2, TOKENS_PER_LINE) == 0) "\n" else PAD);
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

        var buffer: [Text.MAX_TOKEN_LEN + 15]u8 = undefined;
        const buff_slice = buffer[0..];

        var n: u32 = 0;
        var it = types.iterator();
        var freqs_wrt = freqs_file.writer();
        var types_wrt = types_file.writer();

        while (it.next()) |kv| {
            // Get token and it's count
            const token = kv.key_ptr.*;
            const count = comptime if (@TypeOf(types) == std.StringHashMap(Text.TypeInfo)) kv.value_ptr.count else kv.value_ptr.*;

            // write freq and token pair to freqs file
            const result = try std.fmt.bufPrint(buff_slice, "{d:10}  {s}\n", .{ count, token });
            _ = try freqs_wrt.write(result);

            // write token to types file
            n += 1;
            _ = try types_wrt.write(token);
            _ = try types_wrt.write(if (@rem(n, TOKENS_PER_LINE) == 0) "\n" else PAD);
        }
    }

    pub fn write_tokens_to_file(text: Text, output_filename: []const u8, max: usize) !void {
        var n = text.tokens_number;
        if (max > 0 and n > max) n = max;
        // Open files to write transformed input data (final result)
        var output_file = try std.fs.cwd().createFile(output_filename, .{});
        defer output_file.close();

        var i: usize = 0;

        while (i < n) : (i += 1) {
            _ = try output_file.writer().write(text.tokens[i]);

            const attrs = text.tokens_attrs[i];
            if (attrs.surrounded_by_spaces == .both or
                attrs.surrounded_by_spaces == .right)
                _ = try output_file.writer().write(" ");
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
        _ = try output_file.writer().write(text.transformed_bytes[0..n]);
    }
};
