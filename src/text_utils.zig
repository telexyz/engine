const std = @import("std");
const print = std.debug.print;

const parsers = @import("./syllable_parsers.zig");
const telex_char_stream = @import("./telex_char_stream.zig");
const U2ACharStream = telex_char_stream.Utf8ToAsciiTelexCharStream;
const Text = @import("./text_data_struct.zig").Text;

pub inline fn writeToken(attrs: Text.TokenAttributes, token: []const u8, transform: [*]const u8, text: *Text) void {
    if (attrs.isSyllable()) {
        var n: u8 = 0;
        while (transform[n] != 0) {
            text.transformed_offset_ptr.* = transform[n];
            text.transformed_offset_ptr += 1;
            n += 1;
        }

        if (!text.keep_origin_amap) {
            text.transformed_offset_ptr.* = 32;
            text.transformed_offset_ptr += 1;
            text.prev_token_is_vi = true;
        }
    } else {
        // not syllable
        if (text.keep_origin_amap) {
            // write original bytes
            for (token) |b| {
                text.transformed_offset_ptr.* = b;
                text.transformed_offset_ptr += 1;
            }
        } else { // Bỏ qua _ , - là token kết nối âm tiết
            if (!(token.len == 1 and (token[0] == '_' or token[0] == '-'))) {
                if (text.prev_token_is_vi == true) {
                    // Chỉ xuống dòng cho non-syllable token đầu tiên
                    text.transformed_offset_ptr.* = '\n';
                    text.transformed_offset_ptr += 1;
                    text.prev_token_is_vi = false;
                }
            }
        }
    }

    if (text.keep_origin_amap and attrs.spaceAfter()) {
        // Write spacing as it is
        text.transformed_offset_ptr.* = 32;
        text.transformed_offset_ptr += 1;
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
    if (type_info.category == .can_be_syllable) {
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
            type_info.category = switch (attrs.category) {
                .alphmark => .syllmark,
                .alph0m0t => .syll0m0t,
                else => unreachable,
            };
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
        const n: u8 = if (char_stream.first_char_is_upper) blk: {
            offset_ptr.* = '^';
            offset_ptr += 1;
            offset_ptr.* = ' ';
            offset_ptr += 1;
            break :blk 2;
        } else 0;

        const buff = syllable.printBuffParts(offset_ptr[0..16]);
        text.syllable_bytes_len += @intCast(Text.TransOffset, buff.len) + n;
        //
    } else {
        //
        var byte: u8 = 0;
        var mark: u8 = 0;

        // 1: Nước => ^nuoc, VIỆT => ^^viet
        if (char_stream.first_char_is_upper) {
            offset_ptr.* = '^';
            offset_ptr += 1;
            if (char_stream.isUpper()) {
                offset_ptr.* = '^';
                offset_ptr += 1;
            }
            // 2: Nước => ^ nuoc, VIỆT => ^^ viet
            if (text.convert_mode == 2) {
                offset_ptr.* = 32;
                offset_ptr += 1;
            }
        }

        var i: usize = 0;
        // 2: đầy => d day, con => con
        if (text.convert_mode == 2 and char_stream.buffer[0] == 'd' and
            char_stream.buffer[1] == 'd')
        {
            offset_ptr.* = 'd';
            offset_ptr += 1;
            offset_ptr.* = 32;
            offset_ptr += 1;
            i = 1;
        }

        while (i < char_stream.len) : (i += 1) {
            byte = char_stream.buffer[i];
            if (byte == 'w' or (byte == 'z' and i > 0)) {
                if (mark != 0 and mark != byte) {
                    // std.debug.print("DUPMARK: {s}\n", .{char_stream.buffer[0..char_stream.len]}); //DEBUG
                }
                mark = byte;
                continue;
            }
            offset_ptr.* = byte;
            offset_ptr += 1;
        }

        offset_ptr.* = switch (text.convert_mode) {
            1 => '|',
            2 => 32,
            else => unreachable,
        };

        // 1: Nước =>  ^nuoc|w, VIỆT =>  ^^viet|z, đầy =>  dday|z, con => con|
        // 2: Nước => ^ nuoc w, VIỆT => ^^ viet z, đầy => d day z, con => con
        if (mark != 0) {
            offset_ptr += 1;
            offset_ptr.* = mark;
        }
        // 1: Nước => ^nuoc|ws, VIỆT => ^^viet|zj, đầy => dday|zf, con => con|
        // 2: Nước =>  nuoc ws, VIỆT =>   viet zj, đầy =>d day zf, con => con
        if (char_stream.tone != 0) {
            offset_ptr += 1;
            offset_ptr.* = char_stream.tone;
        }

        if (offset_ptr[0] != 32) offset_ptr += 1;
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

    var i: *usize = &text.parsed_tokens_number;
    text.prev_token_is_vi = true;

    while (i.* <= text.tokens_number) : (i.* += 1) {
        // Check if reach the end of tokens list
        if (i.* == text.tokens_number) {
            // Segmentation ended => no more tokens for sure then return
            if (text.tokens_number_finalized) return;

            std.time.sleep(WAIT_NANOSECS);
            std.debug.print("{s}... wait new tokens\n", .{PAD});

            // No new token and timeout
            if (i.* == text.tokens_number) return;
        }

        const token_info = &text.tokens_infos[i.*];

        // Init token and attrs shortcuts
        var token = token_info.trans_slice(text);
        var attrs = &token_info.attrs;
        var trans_ptr: [*]u8 = undefined;
        text.parsed_input_bytes += token.len + 1;

        // Parse alphabet and not too long token only
        if (attrs.category != .nonalpha and token.len <= U2ACharStream.MAX_LEN) {
            // Show progress
            if (text.parsed_input_bytes >= percents_threshold) {
                percents += 10;
                if (percents > 100) percents = 100;
                std.debug.print("{s}{d}% Parsing\n", .{ PAD, percents });
                percents_threshold += ten_percents;
            }

            const ptr = text.alphabet_types.getPtr(token);
            if (ptr == null) {
                std.debug.print("!!! WRONG SYLLABLE CANDIDATE `{s}` !!!\n", .{token});
                unreachable;
            }
            // Init type_info shortcut
            const type_info = ptr.?;

            token2Syllable(token, attrs.*, type_info, text);

            if (type_info.isSyllable()) {
                trans_ptr = type_info.trans_ptr(text);
                attrs.category = type_info.category;
                token_info.syllable_id = type_info.syllable_id;
            }
        } // END parse alphabet token to get syllable

        // Write data out
        writeToken(attrs.*, token, trans_ptr, text);
    } // while loop
}
