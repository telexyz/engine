const std = @import("std");
const print = std.debug.print;

const parsers = @import("./syllable_parsers.zig");
const telex_char_stream = @import("./telex_char_stream.zig");
const U2ACharStream = telex_char_stream.Utf8ToAsciiTelexCharStream;
const Text = @import("./text_data_struct.zig").Text;

pub inline fn writeTokenInfo(tk_info: Text.TokenInfo, text: *Text, writer: Text.BufferedWriter.Writer) !void {
    if (text.keep_origin_amap) {
        // Write all tokens
        _ = try writer.write(tk_info.trans_slice(text));

        if (tk_info.attrs.spaceAfter()) {
            _ = try writer.write(" ");
        }
        return;
    }

    // Write space after token
    const token = tk_info.trans_slice(text);

    if (tk_info.isSyllable()) {
        _ = try writer.print("{s} ", .{token});
        text.prev_token_is_vi = true;
        //
    } else switch (token[0]) {
        //
        '\n' => _ = {
            _ = try writer.write("\n");
        },
        '_', '-' => { // skip true_joiner
            if (!(tk_info.attrs.fenced_by_spaces == .none and token.len == 1)) {
                try writer.print("{s} ", .{token});
            }
        },
        else => {
            _ = try writer.print("{s} ", .{token});
        },
    }
}

fn printNothing(comptime fmt_str: []const u8, args: anytype) void {
    if (false)
        std.debug.print(fmt_str, args);
}

pub inline fn token2Syllable(
    token: []const u8,
    attrs: Text.TokenAttributes,
    type_info: *Text.TypeInfo,
    text: *Text,
) void {
    if (type_info.category == .to_parse_syllable) { // not parsed yet
        // Char stream to parse syllable
        var char_stream = U2ACharStream.new();
        char_stream.strict_mode = true;

        // Try to convert token to syllable
        var syllable = parsers.parseTokenToGetSyllable(
            true, // strict mode on
            printNothing,
            &char_stream,
            token,
        );

        if (syllable.can_be_vietnamese) {
            // Token is vietnamese syllable
            type_info.category = if (char_stream.hasMarkOrTone()) .syllmark else .syll0m0t;
            type_info.syllable_id = syllable.toId();
            type_info.trans_offset = saveAsciiTransform(
                text,
                char_stream,
                &syllable,
            );
        } else {
            // For non-syllable, attrs.category can only be .alph0m0t or .alphmark
            type_info.category = attrs.category;
        }
    }
}

pub inline fn saveAsciiTransform(text: *Text, char_stream: U2ACharStream, syllable: *parsers.Syllable) Text.TransOffset {
    const trans_start_at = text.syllable_bytes_len;
    var offset_ptr = text.syllable_bytes.ptr + text.syllable_bytes_len;

    if (text.convert_mode == 3) {
        //
        if (char_stream.first_char_is_upper) {
            offset_ptr.* = '^';
            offset_ptr += 1;
            offset_ptr.* = ' ';
            offset_ptr += 1;
        }
        const buff = syllable.printBuffParts(offset_ptr[0..16]);
        offset_ptr += buff.len;
        //
    } else {
        //
        const is_spare_mode = (text.convert_mode == 2);

        // 1: Nước => ^nuoc, VIỆT => ^^viet
        if (char_stream.first_char_is_upper) {
            offset_ptr.* = '^';
            offset_ptr += 1;
            if (char_stream.isUpper()) {
                offset_ptr.* = '^';
                offset_ptr += 1;
            }
            // 2: Nước => ^ nuoc, VIỆT => ^^ viet
            if (is_spare_mode) {
                offset_ptr.* = 32;
                offset_ptr += 1;
            }
        }

        const buff = syllable.printBuff(offset_ptr[0..13], is_spare_mode);
        offset_ptr += buff.len;
    }

    // Add double 0 terminators
    offset_ptr.* = 0;
    offset_ptr += 1;
    offset_ptr.* = 0;
    offset_ptr += 1;

    text.syllable_bytes_len = @intCast(Text.TransOffset, @ptrToInt(offset_ptr) - @ptrToInt(text.syllable_bytes.ptr));

    return trans_start_at;
}

// - - - - - - - - - - - - - - -
// Low use / keep for references

const PAD = "                 ";
const WAIT_NANOSECS: u64 = 800_000_000; // nanoseconds

pub fn parseTokens(text: *Text) void {
    // @setRuntimeSafety(false); // !!! DANGER: PLAY WITH FIRE !!!
    // Record progress
    const ten_percents = text.input_bytes.len / 10;
    var percents_threshold = ten_percents;
    var percents: u8 = 0;

    while (text.parsed_tokens_num <= text.tokens_num) : (text.parsed_tokens_num += 1) {
        // Check if reach the end of tokens list
        if (text.parsed_tokens_num == text.tokens_num) {
            // Segmentation ended => no more tokens for sure then return
            if (text.tokens_num_finalized) return;

            std.time.sleep(WAIT_NANOSECS);
            std.debug.print("{s}... wait new tokens\n", .{PAD});

            // No new token and timeout
            if (text.parsed_tokens_num == text.tokens_num) return;
        }

        const token_info = text.tokens_infos.get(text.parsed_tokens_num);

        // Init token and attrs shortcuts
        var token = token_info.trans_slice(text);
        text.parsed_input_bytes += token.len + 1;

        // Parse alphabet and not too long token only
        if (token_info.attrs.category != .nonalpha and
            token.len <= U2ACharStream.MAX_LEN)
        {
            // Show progress
            if (text.parsed_input_bytes >= percents_threshold) {
                percents += 10;
                if (percents > 100) percents = 100;
                std.debug.print("{s}{d}% Parsing\n", .{ PAD, percents });
                percents_threshold += ten_percents;
            }

            // Init type_info shortcut
            var ptr = text.alphabet_types.getPtr(token);
            if (ptr == null) {
                std.debug.print("!!! SYLLABLE CANDIDATE `{s}` INDEX {d} ???\n", .{ token, text.parsed_tokens_num });

                std.debug.print("CONTEXT: `{s}` `{s}` `{s}`\n", .{
                    text.tokens_infos.get(text.parsed_tokens_num - 2).trans_slice(text),
                    text.tokens_infos.get(text.parsed_tokens_num - 1).trans_slice(text),
                    token,
                });

                // Second-chance
                std.time.sleep(WAIT_NANOSECS);
                ptr = text.alphabet_types.getPtr(token);

                if (ptr == null) {
                    std.debug.print("!!! alphabet_types đã được update chưa ???\n", .{});
                    unreachable;
                }
            }
            const type_info = ptr.?;

            // Over-write type_info's category, syllable_id, trans_offset
            token2Syllable(token, token_info.attrs, type_info, text);

            if (type_info.isSyllable())
                text.tokens_infos.set(text.parsed_tokens_num, .{
                    .attrs = .{
                        .fenced_by_spaces = token_info.attrs.fenced_by_spaces,
                        .category = type_info.category,
                    },
                    .trans_offset = type_info.trans_offset,
                    .syllable_id = type_info.syllable_id,
                });
        } // END parse alphabet token to get syllable
    } // while loop
}
