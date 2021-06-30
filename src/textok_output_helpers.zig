const std = @import("std");
const Text = @import("./text_data_struct.zig").Text;

pub const TextokOutputHelpers = struct {
    pub fn write_tokens_to_file(tokens_map: std.StringHashMap(void), output_filename: []const u8) !void {
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

    pub fn write_mark_vs_norm_types_to_files(
        types: std.StringHashMap(Text.TypeInfo),
        typemark_filename: []const u8,
        typenorm_filename: []const u8,
    ) !void {
        var typemark_file = try std.fs.cwd().createFile(typemark_filename, .{});
        var typenorm_file = try std.fs.cwd().createFile(typenorm_filename, .{});

        defer typemark_file.close();
        defer typenorm_file.close();

        const max_token_len = 30;
        var buffer: [max_token_len + 15]u8 = undefined;
        const buff_slice = buffer[0..];

        var it = types.iterator();
        while (it.next()) |kv| {
            if (max_token_len < kv.key_ptr.len) {
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
        types: std.StringHashMap(Text.TypeInfo),
        output_filename: []const u8,
    ) !void {
        var output_file = try std.fs.cwd().createFile(output_filename, .{});
        defer output_file.close();

        const max_token_len = 30;
        var buffer: [max_token_len + 15]u8 = undefined;
        const buff_slice = buffer[0..];

        var it = types.iterator();
        while (it.next()) |kv| {
            if (max_token_len < kv.key_ptr.len) {
                std.debug.print("TOKEN TOO LONG: {s}\n", .{kv.key_ptr.*});
                continue;
            }
            const result = try std.fmt.bufPrint(buff_slice, "{d:10}  {s}\n", .{ kv.value_ptr.count, kv.key_ptr.* });

            _ = try output_file.writer().write(result);
        }
    }

    pub fn write_text_trans_to_file(text: Text, output_filename: []const u8, max: usize) !void {
        var n = text.tokens_number;
        if (max > 0 and n > max) n = max;
        // Open files to write transformed input data (final result)
        var output_file = try std.fs.cwd().createFile(output_filename, .{});
        defer output_file.close();

        var i: usize = 0;

        while (i < n) : (i += 1) {
            const attrs = text.tokens_attrs[i];
            var trans = text.tokens_type_infos[i].transform;

            _ = try output_file.writer().write(trans);

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
