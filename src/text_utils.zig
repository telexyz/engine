const std = @import("std");
const print = std.debug.print;

const parsers = @import("./syllable_parsers.zig");
const telex_char_stream = @import("./telex_char_stream.zig");
const U2ACharStream = telex_char_stream.Utf8ToAsciiTelexCharStream;
const Text = @import("./text_data_struct.zig").Text;

inline fn showProgress(text: *Text, prev_percent: *usize) void {
    const percent = (100 * text.parsed_input_bytes) / text.input_bytes.len;
    if (percent > prev_percent.*) {
        prev_percent.* = percent;
        if (@rem(percent, 5) == 0)
            std.debug.print("{s}{d}% Parsing\n", .{ PAD, percent });
    }
}

fn printNothing(comptime fmt_str: []const u8, args: anytype) void {
    if (false)
        std.debug.print(fmt_str, args);
}

pub fn writeTransformsToFile(text: *Text, filename: []const u8) !void {
    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    var wrt = std.io.bufferedWriter(file.writer());
    var writer = wrt.writer();

    var next: usize = 0;
    var curr: usize = undefined;
    var prev_token_is_vi = true;

    for (text.tokens_infos.items) |token_info| {
        //
        curr = next + token_info.skip;
        next = curr + token_info.len;
        var token = text.input_bytes[curr..next];
        var attrs = token_info.attrs;

        // Write data out
        if (attrs.isSyllable()) {
            const type_ptr = text.syllabet_types.getPtr(token);
            _ = try writer.write(type_ptr.?.transform);

            if (!text.keep_origin_amap) {
                _ = try writer.write(" ");
                prev_token_is_vi = true;
            }
        } else {
            // not syllable
            if (text.keep_origin_amap) {
                // write original bytes
                _ = try writer.write(token);
            } else {
                if (!(token.len == 1 and token[0] == '_')) {
                    if (prev_token_is_vi) _ = try writer.write("\n");
                    prev_token_is_vi = false;
                }
            }
        }

        if (text.keep_origin_amap and attrs.spaceAfter()) {
            // Write spacing as it is
            _ = try writer.write(" ");
        }
        // text.transformed_bytes[first_byte_index] = attrs.toByte();
    }
    try wrt.flush();
}

// TODO: convert &#xA9; to utf8 https://mothereff.in/html-entities
const PAD = "                 ";
const WAIT_NANOSECS: u64 = 800_000_000; // nanoseconds
const M_WAIT_NANOSECS: u64 = 100_000_000; // nanoseconds

pub fn parseTokens(text: *Text) void {
    // @setRuntimeSafety(false);
    var char_stream = U2ACharStream.new();
    char_stream.strict_mode = true;
    var prev_percent: usize = 0;
    const max_sleeps: u8 = 10;
    var sleeps_count: u8 = 0;

    var i: *usize = &text.parsed_tokens_number;
    var next: *usize = &text.parsed_input_bytes;
    var curr: usize = undefined;

    while (i.* <= text.tokens_number) : (i.* += 1) {
        // Check if reach the end of tokens list
        if (i.* == text.tokens_number) {

            // Segmentation ended => no more tokens for sure then return
            if (text.tokens_number_finalized) {
                text.removeSyllablesFromAlphabetTypes() catch unreachable;
                return;
            }

            // BEGIN waiting for new tokens (all tokens is processed)
            while (sleeps_count < max_sleeps and i.* == text.tokens_number) {
                std.time.sleep(WAIT_NANOSECS);
                sleeps_count += 1;
                std.debug.print("{s}... wait new tokens\n", .{PAD});
            } // END waiting for new tokens

            // No new token and timeout
            if (i.* == text.tokens_number) return;

            // Got new tokens, reset counter and continue
            sleeps_count = 0;
        }

        // Better wait to syllabet_types be finalized
        if (i.* > text.tokens_number - 5) std.time.sleep(M_WAIT_NANOSECS);

        const token_info = &text.tokens_infos.items[i.*];
        curr = next.* + token_info.skip;
        next.* = curr + token_info.len;

        if (text.input_bytes[curr] == '\n') {
            showProgress(text, &prev_percent);
            continue;
        }

        //  and token's attributes shortcut
        var attrs = &token_info.attrs;

        // Parse alphabet and not too long token only
        if (attrs.category == .nonalpha) continue;

        // Init token shortcuts
        var token = text.input_bytes[curr..next.*];

        if (token.len > U2ACharStream.MAX_LEN) {
            const gop = text.alphabet_types.getOrPutValue(token, Text.TypeInfo{
                .count = 0,
                .category = ._none,
            }) catch unreachable;
            gop.value_ptr.count += 1;
            continue;
        }

        const type_info = text.syllabet_types.getPtr(token).?;

        if (type_info.category == ._none) {
            // Not transformed yet
            char_stream.reset();

            // Try to convert token to syllable
            var syllable = parsers.parseTokenToGetSyllable(
                true, // strict mode on
                printNothing,
                &char_stream,
                token,
            );

            if (syllable.can_be_vietnamese) {
                // Token is vietnamese syllable
                type_info.category = switch (attrs.category) {
                    .alphmark => .syllmark,
                    .alphabet => .syllable,
                    else => unreachable,
                };
                type_info.syllable_id = syllable.toId();

                // Write ascii transform
                if (text.convert_mode == 3) {
                    if (char_stream.first_char_is_upper) {
                        text.syllable_bytes[text.syllable_bytes_len] = '^';
                        text.syllable_bytes_len += 1;
                        text.syllable_bytes[text.syllable_bytes_len] = ' ';
                        text.syllable_bytes_len += 1;
                    }
                    const buff = text.syllable_bytes[text.syllable_bytes_len..];
                    type_info.transform = syllable.printBuffParts(buff);
                    text.syllable_bytes_len += type_info.transform.len;
                } else {
                    type_info.transform = saveAsciiTransform(text, char_stream);
                }
            } else {
                // For non-syllable, attrs.category can only be .alphabet or .alphmark
                type_info.category = attrs.category;
            }
        }

        if (type_info.isSyllable()) {
            attrs.category = type_info.category;
            token_info.syllable_id = type_info.syllable_id;
        }
    }
}

pub fn saveAsciiTransform(text: *Text, char_stream: U2ACharStream) []const u8 {
    const trans_start_at = text.syllable_bytes_len;
    var byte: u8 = 0;
    var mark: u8 = 0;

    // 1: Nước => ^nuoc, VIỆT => ^^viet
    if (char_stream.first_char_is_upper) {
        text.syllable_bytes[text.syllable_bytes_len] = '^';
        text.syllable_bytes_len += 1;
        if (char_stream.isUpper()) {
            text.syllable_bytes[text.syllable_bytes_len] = '^';
            text.syllable_bytes_len += 1;
        }
        // 2: Nước => ^ nuoc, VIỆT => ^^ viet
        if (text.convert_mode == 2) {
            text.syllable_bytes[text.syllable_bytes_len] = 32;
            text.syllable_bytes_len += 1;
        }
    }

    var i: usize = 0;
    // 2: đầy => d day, con => con
    if (text.convert_mode == 2 and char_stream.buffer[0] == 'd' and
        char_stream.buffer[1] == 'd')
    {
        text.syllable_bytes[text.syllable_bytes_len] = 'd';
        text.syllable_bytes_len += 1;
        text.syllable_bytes[text.syllable_bytes_len] = 32;
        text.syllable_bytes_len += 1;
        i = 1;
    }

    while (i < char_stream.len) : (i += 1) {
        byte = char_stream.buffer[i];
        if (byte == 'w' or (byte == 'z' and i > 0)) {
            if (mark != 0 and mark != byte) {
                std.debug.print("DUPMARK: {s}\n", .{char_stream.buffer[0..char_stream.len]}); //DEBUG
            }
            mark = byte;
            continue;
        }
        text.syllable_bytes[text.syllable_bytes_len] = byte;
        text.syllable_bytes_len += 1;
    }

    text.syllable_bytes[text.syllable_bytes_len] = switch (text.convert_mode) {
        1 => '|',
        2 => 32,
        else => unreachable,
    };
    text.syllable_bytes_len += 1;

    // 1: Nước =>  ^nuoc|w, VIỆT =>  ^^viet|z, đầy =>  dday|z, con => con|
    // 2: Nước => ^ nuoc w, VIỆT => ^^ viet z, đầy => d day z, con => con
    if (mark != 0) {
        text.syllable_bytes[text.syllable_bytes_len] = mark;
        text.syllable_bytes_len += 1;
    }
    // 1: Nước => ^nuoc|ws, VIỆT => ^^viet|zj, đầy => dday|zf, con => con|
    // 2: Nước =>  nuoc ws, VIỆT =>   viet zj, đầy =>d day zf, con => con
    if (char_stream.tone != 0) {
        text.syllable_bytes[text.syllable_bytes_len] = char_stream.tone;
        text.syllable_bytes_len += 1;
    }
    if (text.convert_mode == 2 and
        text.syllable_bytes[text.syllable_bytes_len - 1] == 32)
    { // remove unecessary space for no-mark no-tone syllable
        text.syllable_bytes_len -= 1;
    }
    return text.syllable_bytes[trans_start_at..text.syllable_bytes_len];
}
