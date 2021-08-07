const std = @import("std");
const print = std.debug.print;

const parsers = @import("./syllable_parsers.zig");
const telex_char_stream = @import("./telex_char_stream.zig");
const U2ACharStream = telex_char_stream.Utf8ToAsciiTelexCharStream;
const Text = @import("./text_data_struct.zig").Text;

pub inline fn writeToken(attrs: Text.TokenAttributes, token: []const u8, transform: [*]const u8, text: *Text) void {
    @setRuntimeSafety(false); // mimic std / mem.zig / fn copy()
    var trans_ptr = text.transformed_bytes.ptr + text.transformed_bytes_len;
    if (attrs.isSyllable()) {
        var n: u8 = 0;
        while (transform[n] != 0) {
            trans_ptr.* = transform[n];
            trans_ptr += 1;
            n += 1;
        }

        if (!text.keep_origin_amap) {
            trans_ptr.* = 32;
            trans_ptr += 1;
            text.prev_token_is_vi = true;
        }
    } else {
        // not syllable
        if (text.keep_origin_amap) {
            // write original bytes
            for (token) |b| {
                trans_ptr.* = b;
                trans_ptr += 1;
            }
        } else { // Bỏ qua _ , - là token kết nối âm tiết
            if (!(token.len == 1 and (token[0] == '_' or token[0] == '-'))) {
                if (text.prev_token_is_vi == true) {
                    // Chỉ xuống dòng cho non-syllable token đầu tiên
                    trans_ptr.* = '\n';
                    trans_ptr += 1;
                    text.prev_token_is_vi = false;
                }
            }
        }
    }

    if (text.keep_origin_amap and attrs.spaceAfter()) {
        // Write spacing as it is
        trans_ptr.* = 32;
        trans_ptr += 1;
    }

    // text.transformed_bytes[first_byte_index] = attrs.toByte();
    text.transformed_bytes_len = @ptrToInt(trans_ptr) - @ptrToInt(text.transformed_bytes.ptr);
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
            type_info.trans_ptr = saveAsciiTransform(
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

pub inline fn saveAsciiTransform(text: *Text, char_stream: U2ACharStream, syllable: *parsers.Syllable) Text.TransPtr {
    const trans_start_at = text.syllable_bytes_len;

    if (text.convert_mode == 3) {
        //
        if (char_stream.first_char_is_upper) {
            text.syllable_bytes[text.syllable_bytes_len] = '^';
            text.syllable_bytes_len += 1;
            text.syllable_bytes[text.syllable_bytes_len] = ' ';
            text.syllable_bytes_len += 1;
        }

        const buff = text.syllable_bytes[text.syllable_bytes_len..];
        text.syllable_bytes_len += syllable.printBuffParts(buff).len;
        //
    } else {
        //
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
                    // std.debug.print("DUPMARK: {s}\n", .{char_stream.buffer[0..char_stream.len]}); //DEBUG
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
    }

    // Add 0 terminator
    text.syllable_bytes[text.syllable_bytes_len] = 0;
    text.syllable_bytes_len += 1;

    // Encode slice to offset + length
    // const len = text.syllable_bytes_len - trans_start_at;
    // return @intCast(Text.TransPtr, (trans_start_at << 4) + len);
    return @intCast(Text.TransPtr, trans_start_at);
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
    var next: *usize = &text.parsed_input_bytes;
    var curr: usize = undefined;
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
        curr = next.* + token_info.skip;
        next.* = curr + token_info.len;

        // Init token and attrs shortcuts
        var token = text.input_bytes[curr..next.*];
        var attrs = &token_info.attrs;
        var trans: [*]u8 = undefined;

        // Parse alphabet and not too long token only
        if (attrs.category != .nonalpha and token_info.len <= U2ACharStream.MAX_LEN) {
            // Show progress
            if (next.* >= percents_threshold) {
                percents += 10;
                std.debug.print("{s}{d}% Parsing\n", .{ PAD, percents });
                percents_threshold += ten_percents;
            }

            const ptr = text.alphabet_types.getPtr(token);
            if (ptr == null) {
                std.debug.print("!!! WRONG SYLLABLE CANDIDATE `{s}` !!!\n", .{token});
                std.debug.print("Xem tokens_infos.append(..) đã được update chưa ???\n", .{});
                std.debug.print("CONTEXT {s}\n", .{text.input_bytes[curr - 10 .. next.* + 10]});
                unreachable;
            }
            // Init type_info shortcut
            const type_info = ptr.?;

            token2Syllable(token, attrs.*, type_info, text);

            if (type_info.isSyllable()) {
                trans = type_info.transform(text);
                attrs.category = type_info.category;
                token_info.syllable_id = type_info.syllable_id;
            }
        } // END parse alphabet token to get syllable

        // Write data out
        writeToken(attrs.*, token, trans, text);
    } // while loop
}
