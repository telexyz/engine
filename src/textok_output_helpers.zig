const std = @import("std");
const Text = @import("./text_data_struct.zig").Text;

const MAX_TOKENS_PER_LINE = 10;
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

    pub fn write_mark_vs_norm_tokens_to_files(
        types: std.StringHashMap(Text.TypeInfo),
        typemark_filename: []const u8,
        typenorm_filename: []const u8,
    ) !void {
        var typemark_file = try std.fs.cwd().createFile(typemark_filename, .{});
        var typenorm_file = try std.fs.cwd().createFile(typenorm_filename, .{});

        defer typemark_file.close();
        defer typenorm_file.close();

        var count1: usize = 0;
        var count2: usize = 0;

        var it = types.iterator();

        while (it.next()) |kv| {
            const token = kv.key_ptr.*;

            if (kv.value_ptr.haveMarkTone()) {
                //
                _ = try typemark_file.writer().write(token);
                count1 += 1;
                if (@rem(count1, MAX_TOKENS_PER_LINE) == 0)
                    _ = try typemark_file.writer().write("\n")
                else
                    _ = try typemark_file.writer().write(PAD);
            } else {
                //
                _ = try typenorm_file.writer().write(token);
                count2 += 1;
                if (@rem(count2, MAX_TOKENS_PER_LINE) == 0)
                    _ = try typenorm_file.writer().write("\n")
                else
                    _ = try typenorm_file.writer().write(PAD);
            }
        }
    }

    pub fn write_tokens_to_file(
        types: anytype,
        filename: []const u8,
    ) !void {
        var file = try std.fs.cwd().createFile(filename, .{});
        defer file.close();

        var count: usize = 0;
        var it = types.iterator();
        while (it.next()) |kv| {
            _ = try file.writer().write(kv.key_ptr.*);
            count += 1;
            if (@rem(count, MAX_TOKENS_PER_LINE) == 0)
                _ = try file.writer().write("\n")
            else
                _ = try file.writer().write(PAD);
        }
    }

    pub fn write_mark_vs_norm_types_to_files(
        types: std.StringHashMap(Text.TypeInfo),
        typemark_filename: []const u8,
        typenorm_filename: []const u8,
    ) !void {
        var typemark_file = try std.fs.cwd().createFile(typemark_filename, .{});
        var typenorm_file = try std.fs.cwd().createFile(typenorm_filename, .{});

        defer typemark_file.close();
        defer typenorm_file.close();

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
                _ = try typemark_file.writer().write(result);
            } else {
                _ = try typenorm_file.writer().write(result);
            }
        }
    }

    pub fn write_types_to_file(
        types: anytype,
        output_filename: []const u8,
    ) !void {
        var output_file = try std.fs.cwd().createFile(output_filename, .{});
        defer output_file.close();

        var buffer: [Text.MAX_TOKEN_LEN + 15]u8 = undefined;
        const buff_slice = buffer[0..];

        var it = types.iterator();
        while (it.next()) |kv| {
            if (Text.MAX_TOKEN_LEN < kv.key_ptr.len) {
                std.debug.print("TOKEN TOO LONG: {s}\n", .{kv.key_ptr.*});
                continue;
            }

            const count = comptime if (@TypeOf(types) == std.StringHashMap(Text.TypeInfo)) kv.value_ptr.count else kv.value_ptr.*;

            const result = try std.fmt.bufPrint(buff_slice, "{d:10}  {s}\n", .{ count, kv.key_ptr.* });

            _ = try output_file.writer().write(result);
        }
    }

    pub fn write_text_tokens_to_file(text: Text, output_filename: []const u8, max: usize) !void {
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
