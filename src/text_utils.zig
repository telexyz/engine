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
const WAIT_NANOSECS: u64 = 100_000_000; // nanoseconds

pub fn telexifyAlphabetTokens(text: *Text) void {
    @setRuntimeSafety(false);
    var char_stream = U2ACharStream.new();
    char_stream.strict_mode = true;
    var prev_percent: u64 = 0;
    const max_sleeps: u8 = 2;
    var sleeps_count: u8 = 0;

    var i: *usize = &text.processed_tokens_number;
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
        var token = text.tokens[i.*];
        if (token[0] == '\n') {
            recordNewLineTokenAndShowProgress(text, i.*, &prev_percent);
            continue;
        }
        //  and token's attributes shortcut
        var attrs = &text.tokens_attrs[i.*];
        var token_not_written = true;

        // Reserver first-byte to write token attrs
        const firt_byte_index = text.transformed_bytes_len;
        if (text.telexified_all_tokens)
            text.transformed_bytes_len += 1;

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
                    // Write ascii-telex transform
                    type_info.transform = saveAsciiTransform(text, char_stream);
                    token_not_written = false;
                    // print("char_stream: {s} => {s}\n", .{ token, type_info.transform }); //DEBUG
                } else {
                    // For non-syllable, attrs.category can only be
                    // .alphabet or .alphmark
                    type_info.category = attrs.category;
                }
            }

            if (type_info.isSyllable()) {
                // if (type_info.category != ._none) {
                // Update token category according to it's type category
                attrs.category = type_info.category;
                // Point token value to it's transform to write to output stream
                token = type_info.transform;
            }
        } // attrs.category == .alphabet or .alphmark

        if (text.telexified_all_tokens and token_not_written) {
            for (token) |b| {
                text.transformed_bytes[text.transformed_bytes_len] = b;
                text.transformed_bytes_len += 1;
            }
        }

        if (text.telexified_all_tokens)
            text.transformed_bytes[firt_byte_index] = 32; // space
        // text.transformed_bytes[firt_byte_index] = attrs.toByte();

        // printToken(token, attrs.*); // DEBUG
    } // END while text.processed_tokens_number
}

fn recordNewLineTokenAndShowProgress(text: *Text, token_index: usize, prev_percent: *u64) void {
    if (text.telexified_all_tokens) {
        text.transformed_bytes[text.transformed_bytes_len] = '\n';
        text.transformed_bytes_len += 1;
    }
    // Show token parsing progress
    const percent: u64 = if (prev_percent.* < 80)
        (100 * text.transformed_bytes_len) / text.transformed_bytes_size
    else
        (100 * token_index) / text.tokens_number;

    if (percent > prev_percent.*) {
        prev_percent.* = percent;
        if (@rem(percent, 5) == 0)
            std.debug.print("{s}{d}% Parsing\n", .{ PAD, percent });
    }
}

pub fn saveAsciiTransform(text: *Text, char_stream: U2ACharStream) []const u8 {
    const trans_start_at = text.transformed_bytes_len;
    const am_dau_is_zd = (char_stream.buffer[0] == 'z');
    var byte: u8 = 0;
    var mark: u8 = 0;

    var i: usize = 0;
    if (am_dau_is_zd) i += 1;
    while (i < char_stream.len) : (i += 1) {
        byte = char_stream.buffer[i];
        if (byte == 'w' or byte == 'z') {
            if (mark != 0 and mark != byte) {
                std.debug.print("DUPMARK: {s}\n", .{char_stream.buffer[0..char_stream.len]}); //DEBUG
            }
            mark = byte;
            continue;
        }
        text.transformed_bytes[text.transformed_bytes_len] = byte;
        text.transformed_bytes_len += 1;
    }

    if (char_stream.first_char_is_upper or am_dau_is_zd or
        mark != 0 or char_stream.tone != 0)
    {
        text.transformed_bytes[text.transformed_bytes_len] = '|';
        text.transformed_bytes_len += 1;
    }
    // Nước => nuoc|, VIỆT => viet|, đầy => day|d
    if (am_dau_is_zd) {
        text.transformed_bytes[text.transformed_bytes_len] = 'd';
        text.transformed_bytes_len += 1;
    }
    // Nước => nuoc|w, VIỆT => viet|z, đầy => day|dz
    if (mark != 0) {
        text.transformed_bytes[text.transformed_bytes_len] = mark;
        text.transformed_bytes_len += 1;
    }
    // Nước => nuoc|ws, VIỆT => viet|zj, đầy => day|dzf
    if (char_stream.tone != 0) {
        text.transformed_bytes[text.transformed_bytes_len] = char_stream.tone;
        text.transformed_bytes_len += 1;
    }
    // Nước => nuoc|ws^, VIỆT => viet|zj#, đầy => day|dzf
    if (char_stream.first_char_is_upper) {
        text.transformed_bytes[text.transformed_bytes_len] =
            if (char_stream.isCapitalized()) '#' else '^';
        text.transformed_bytes_len += 1;
    }
    return text.transformed_bytes[trans_start_at..text.transformed_bytes_len];
}
