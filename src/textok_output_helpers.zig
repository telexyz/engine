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
        mark_filename: []const u8,
        norm_filename: []const u8,
    ) !void {
        var mark_file = try std.fs.cwd().createFile(mark_filename, .{});
        var norm_file = try std.fs.cwd().createFile(norm_filename, .{});

        defer mark_file.close();
        defer norm_file.close();

        var buffer: [Text.MAX_TOKEN_LEN + 15]u8 = undefined;
        const buff_slice = buffer[0..];

        var it = types.iterator();
        while (it.next()) |kv| {
            if (Text.MAX_TOKEN_LEN < kv.key_ptr.len) {
                std.debug.print("TOKEN TOO LONG: {s}\n", .{kv.key_ptr.*});
                continue;
            }

            const result = try std.fmt.bufPrint(buff_slice, "{d:10}  {s}\n", .{ kv.value_ptr.count, kv.key_ptr.* });

            if (kv.value_ptr.haveMarkTone()) {
                _ = try mark_file.writer().write(result);
            } else {
                _ = try norm_file.writer().write(result);
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
            if (Text.MAX_TOKEN_LEN < kv.key_ptr.len) {
                std.debug.print("TOKEN TOO LONG: {s}\n", .{kv.key_ptr.*});
                continue;
            }

            const token = kv.key_ptr.*;
            const count = comptime if (@TypeOf(types) == std.StringHashMap(Text.TypeInfo)) kv.value_ptr.count else kv.value_ptr.*;

            const result = try std.fmt.bufPrint(buff_slice, "{d:10}  {s}\n", .{ count, token });
            _ = try freqs_wrt.write(result);

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
