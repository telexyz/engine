const std = @import("std");
const print = std.debug.print;

const parsers = @import("./syllable_parsers.zig");
const telex_char_stream = @import("./telex_char_stream.zig");
const U2ACharStream = telex_char_stream.Utf8ToAsciiTelexCharStream;
const Text = @import("./text_data_struct.zig").Text;

inline fn printToken(token: []const u8, attrs: Text.TokenAttributes) void {
    if (token[0] == '\n') {
        print("\nNEWLINE: ", .{});
    } else {
        print("\"{s}\" => {}, {}\n", .{
            token,
            attrs.category,
            attrs.surrounded_by_spaces,
        });
    }
}

fn printNothing(comptime fmt_str: []const u8, args: anytype) void {
    if (false)
        std.debug.print(fmt_str, args);
}

const PAD = "                 ";
const WAIT_NANOSECS: u64 = 500_000_000; // nanoseconds

// Todo: convert &#xA9; to utf8 https://mothereff.in/html-entities
pub fn parseTokens(text: *Text) void {
    @setRuntimeSafety(false);
    var char_stream = U2ACharStream.new();
    char_stream.strict_mode = true;
    var prev_percent: u64 = 0;
    const max_sleeps: u8 = 20;
    var sleeps_count: u8 = 0;
    var prev_token_is_vi = true;

    var i: *usize = &text.parsed_tokens_number;
    var next: *usize = &text.parsed_input_bytes;
    var curr: usize = undefined;

    while (i.* <= text.tokens_number) : (i.* += 1) {
        // Check if reach the end of tokens list
        if (i.* == text.tokens_number) {
            // If segmentation end => no more tokens for sure then return
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

        // Init token shortcuts
        curr = next.* + text.tokens_skip[i.*];
        next.* = curr + text.tokens_len[i.*];
        var token = text.input_bytes[curr..next.*];
        //  and token's attributes shortcut
        var attrs = &text.tokens_attrs[i.*];
        // printToken(token, attrs.*); // DEBUG

        if (token[0] == '\n') {
            recordNewline(text);
            showProgress(text, i.*, &prev_percent);
            prev_token_is_vi = false;
            continue;
        }

        var token_not_written = true;
        // Parse alphabet token to get syllables
        if (attrs.category != .nonalpha and token.len <= Text.MAX_TOKEN_LEN) {
            const gop = text.alphabet_types.getOrPutValue(token, Text.TypeInfo{
                .count = 0,
                .category = ._none,
            }) catch unreachable;

            gop.value_ptr.count += 1;
            const type_info = gop.value_ptr;

            // print("\n| Tkn: {s}, {} | ", .{ token, type_info.category }); //DEBUG
            if (type_info.category == ._none and token.len <= U2ACharStream.MAX_LEN) {
                // Not transformed and not too long token
                char_stream.reset();
                // Try to convert token to syllable
                const syllable = parsers.parseTokenToGetSyllable(
                    true, // strict mode on
                    printNothing,
                    &char_stream,
                    token,
                );

                // print("Alphabet: {s}, {} => is_vn_syllable {}\n", .{ token, attrs.category, syllable.can_be_vietnamese }); //DEBUG

                if (syllable.can_be_vietnamese) {
                    // Token is vietnamese syllable
                    type_info.category = switch (attrs.category) {
                        .alphmark => .syllmark,
                        .alphabet => .syllable,
                        else => unreachable,
                    };
                    type_info.syllable_id = syllable.toId();
                    // Write ascii-telex transform
                    type_info.transform = saveAsciiTransform(text, char_stream);
                    token_not_written = false;
                } else {
                    // For non-syllable, attrs.category can only be
                    // .alphabet or .alphmark
                    type_info.category = attrs.category;
                }
            }

            if (type_info.isSyllable()) {
                // Update token category according to it's type category
                attrs.category = type_info.category;
                // Point token value to it's transform to write to output stream
                token = type_info.transform;
                text.syllable_ids[i.*] = type_info.syllable_id;
            }
        } // END attrs.category == .alphabet or .alphmark

        // Write data out
        if (attrs.isSyllable()) {
            //
            if (token_not_written) {
                for (token) |b| {
                    text.transformed_bytes[text.transformed_bytes_len] = b;
                    text.transformed_bytes_len += 1;
                }
            }
            if (!text.keep_origin_amap) {
                text.transformed_bytes[text.transformed_bytes_len] = 32; // space
                text.transformed_bytes_len += 1;
                prev_token_is_vi = true;
            }
        } else {
            // not syllable
            if (text.keep_origin_amap) {
                // write original bytes
                for (token) |b| {
                    text.transformed_bytes[text.transformed_bytes_len] = b;
                    text.transformed_bytes_len += 1;
                }
            } else { // text.keep_origin_amap == false
                if (!(token.len == 1 and token[0] == '_')) {
                    if (prev_token_is_vi) recordNewline(text);
                    prev_token_is_vi = false;
                }
            }
        }

        if (text.keep_origin_amap and attrs.spaceAfter()) {
            // Write spacing as it is
            text.transformed_bytes[text.transformed_bytes_len] = 32; // space
            text.transformed_bytes_len += 1;
        }

        // text.transformed_bytes[first_byte_index] = attrs.toByte();
        // printToken(token, attrs.*); // DEBUG
    } // END while text.parsed_tokens_number
}

inline fn recordNewline(text: *Text) void {
    var n = text.transformed_bytes_len - 1;
    var byte: u8 = undefined;

    while (n >= 0) {
        // Find first non-space byte
        byte = text.transformed_bytes[n];
        if (byte != 32 and byte != '\n') break;
        n -= 1;
    }
    text.transformed_bytes_len = n + 1;

    text.transformed_bytes[text.transformed_bytes_len] = '\n';
    text.transformed_bytes_len += 1;
}

inline fn showProgress(text: *Text, token_index: usize, prev_percent: *u64) void {
    const percent: u64 = if (prev_percent.* < 66)
        (100 * text.transformed_bytes_len) / text.transformed_bytes_size
    else
        (100 * token_index) / text.tokens_number;

    if (percent > prev_percent.*) {
        prev_percent.* = percent;
        if (@rem(percent, 3) == 0)
            std.debug.print("{s}{d}% Parsing\n", .{ PAD, percent });
    }
}

pub fn saveAsciiTransform(text: *Text, char_stream: U2ACharStream) []const u8 {
    const trans_start_at = text.transformed_bytes_len;
    var byte: u8 = 0;
    var mark: u8 = 0;

    // 1: Nước =>  ^nuoc, VIỆT =>  ^^viet
    if (char_stream.first_char_is_upper) {
        text.transformed_bytes[text.transformed_bytes_len] = '^';
        text.transformed_bytes_len += 1;
        if (char_stream.isUpper()) {
            text.transformed_bytes[text.transformed_bytes_len] = '^';
            text.transformed_bytes_len += 1;
        }
        // 2: Nước => ^ nuoc, VIỆT => ^^ viet
        if (text.convert_mode == 2) {
            text.transformed_bytes[text.transformed_bytes_len] = 32;
            text.transformed_bytes_len += 1;
        }
    }

    var i: usize = 0;
    // 2: đầy => d day, con => con
    if (text.convert_mode == 2 and char_stream.buffer[0] == 'd' and
        char_stream.buffer[1] == 'd')
    {
        text.transformed_bytes[text.transformed_bytes_len] = 'd';
        text.transformed_bytes_len += 1;
        text.transformed_bytes[text.transformed_bytes_len] = 32;
        text.transformed_bytes_len += 1;
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
        text.transformed_bytes[text.transformed_bytes_len] = byte;
        text.transformed_bytes_len += 1;
    }

    text.transformed_bytes[text.transformed_bytes_len] = switch (text.convert_mode) {
        1 => '|',
        2 => 32,
        else => unreachable,
    };
    text.transformed_bytes_len += 1;

    // 1: Nước =>  ^nuoc|w, VIỆT =>  ^^viet|z, đầy =>  dday|z, con => con|
    // 2: Nước => ^ nuoc w, VIỆT => ^^ viet z, đầy => d day z, con => con
    if (mark != 0) {
        text.transformed_bytes[text.transformed_bytes_len] = mark;
        text.transformed_bytes_len += 1;
    }
    // 1: Nước => ^nuoc|ws, VIỆT => ^^viet|zj, đầy => dday|zf, con => con|
    // 2: Nước =>  nuoc ws, VIỆT =>   viet zj, đầy =>d day zf, con => con
    if (char_stream.tone != 0) {
        text.transformed_bytes[text.transformed_bytes_len] = char_stream.tone;
        text.transformed_bytes_len += 1;
    }
    if (text.convert_mode == 2 and
        text.transformed_bytes[text.transformed_bytes_len - 1] == 32)
    { // remove unecessary space for no-mark no-tone syllable
        text.transformed_bytes_len -= 1;
    }
    return text.transformed_bytes[trans_start_at..text.transformed_bytes_len];
}
