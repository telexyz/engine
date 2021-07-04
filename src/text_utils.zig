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
const WAIT_NANOSECS: u64 = 600_000_000; // nanoseconds

pub fn telexifyAlphabetTokens(text: *Text) void {
    @setRuntimeSafety(false);
    var char_stream = U2ACharStream.new();
    char_stream.strict_mode = true;
    var prev_percent: u64 = 0;
    const max_sleeps: u8 = 1;
    var sleeps_count: u8 = 0;

    var i: *usize = &text.processed_tokens_number;
    while (i.* <= text.tokens_number) : (i.* += 1) {
        // Check if reach the end of tokens list
        if (i.* == text.tokens_number) {
            // If segmentation end => no more tokens for sure then return
            if (text.tokens_number_finalized) return;
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
        text.transformed_bytes_len += 1;

        if (attrs.category != .nonalpha and token.len <= 11) {
            // Get token coresponding type info
            const type_info = text.alphabet_types.getPtr(token).?;

            // print("\n| Tkn: {s}, {} | ", .{ token, type_info.category }); // DEBUG
            if (type_info.category == ._none) { // Not transformed yet
                char_stream.reset();
                // Try to convert token to syllable
                const syllable = parsers.parseTokenToGetSyllable(
                    true, // strick mode on
                    printNothing,
                    &char_stream,
                    token,
                );

                // print("Alphabet: {s}, {} => is_vn_syllable {}\n", .{ token, attrs.category, syllable.can_be_vietnamese }); // DEBUG

                if (syllable.can_be_vietnamese) {
                    // Token is vietnamese syllable
                    type_info.category = switch (attrs.category) {
                        .alphmark => .syllmark,
                        .alphabet => .syllable,
                        else => unreachable,
                    };
                    // Write ascii-telex transform
                    const syllable_token = saveAsciiTelexTransform(text, char_stream);
                    type_info.transform = syllable_token;
                    countSyllableAndSyllower(text, syllable_token, type_info) catch unreachable;
                    token_not_written = false;
                } else {
                    // For non-syllable, attrs.category can only be
                    // .alphabet or .alphmark
                    type_info.category = attrs.category;
                }
            }

            if (type_info.isSyllable()) {
                attrs.category = type_info.category;
                // Point token value to it's type trans to write to output stream
                token = type_info.transform;
            }
        } // attrs.category == .alphabet or .alphmark

        if (token_not_written) {
            for (token) |b| {
                text.transformed_bytes[text.transformed_bytes_len] = b;
                text.transformed_bytes_len += 1;
            }
        }

        // Write attrs at the begin of token's ouput stream
        text.transformed_bytes[firt_byte_index] = attrs.toByte();

        // printToken(token, attrs.*); // DEBUG
    } // END while text.processed_tokens_number
}

fn recordNewLineTokenAndShowProgress(text: *Text, token_index: usize, prev_percent: *u64) void {
    text.transformed_bytes[text.transformed_bytes_len] = '\n';
    text.transformed_bytes_len += 1;

    // Show token parsing progress
    const percent: u64 = if (!text.tokens_number_finalized)
        (100 * text.transformed_bytes_len) / text.transformed_bytes_size
    else
        (100 * token_index) / text.tokens_number;

    if (percent > prev_percent.*) {
        prev_percent.* = percent;
        if (@rem(percent, 3) == 0)
            std.debug.print("{s}{d}% Syllabling\n", .{ PAD, percent });
    }
}

fn countSyllableAndSyllower(text: *Text, syllable: []const u8, type_info: *const Text.TypeInfo) !void {
    // Record and count syllable
    const gop1 = try text.syllable_types.getOrPutValue(syllable, Text.TypeInfo{ .category = type_info.category });
    gop1.value_ptr.count += type_info.count;

    const next = text.syllower_bytes_len + syllable.len;
    const syllower = text.syllower_bytes[text.syllower_bytes_len..next];
    // Convert syllable to lowercase
    for (syllable) |c, i| {
        syllower[i] = c | 0b00100000;
    }
    const gop2 = try text.syllower_types.getOrPutValue(syllower, Text.TypeInfo{ .category = type_info.category });
    gop2.value_ptr.count += type_info.count;
    text.syllower_bytes_len = next;
}

pub fn saveAsciiTelexTransform(text: *Text, char_stream: U2ACharStream) []const u8 {
    // Convert input's utf-8 to output's ascii-telex
    const bytes_len = &text.transformed_bytes_len;
    const trans_start_at = bytes_len.*;

    if (char_stream.isCapitalized()) {
        var i: usize = 0;
        while (i < char_stream.len) : (i += 1) {
            // Upper case the whole input bytes
            text.transformed_bytes[bytes_len.*] =
                char_stream.buffer[i] & 0b11011111;
            bytes_len.* += 1;
        }
        if (char_stream.tone != 0) {
            text.transformed_bytes[bytes_len.*] =
                char_stream.tone & 0b11011111;
            bytes_len.* += 1;
        }
    } else {
        var i: usize = 0;
        // Upper case the first letter
        if (char_stream.isTitlied()) {
            text.transformed_bytes[bytes_len.*] =
                char_stream.buffer[0] & 0b11011111;
            bytes_len.* += 1;
            i = 1; // skip the first byte
        }
        // Copy the rest
        while (i < char_stream.len) {
            text.transformed_bytes[bytes_len.*] = char_stream.buffer[i];
            i += 1;
            bytes_len.* += 1;
        }
        if (char_stream.tone != 0) {
            text.transformed_bytes[bytes_len.*] = char_stream.tone;
            bytes_len.* += 1;
        }
    }
    // END Convert input's utf-8 to output's ascii-telex
    return text.transformed_bytes[trans_start_at..bytes_len.*];
}
