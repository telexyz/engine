const std = @import("std");
const print = std.debug.print;

const parsers = @import("./parsers.zig");
const chars_utils = @import("./chars_utils.zig");
const U2ACharStream = chars_utils.Utf8ToAsciiTelexAmTietCharStream;
const Text = @import("./text.zig").Text;

fn printNothing(comptime fmt_str: []const u8, args: anytype) void {
    if (false)
        std.debug.print(fmt_str, args);
}

const PAD = "                 ";
pub fn telexifyAlphabetTokens(text: *Text) void {
    @setRuntimeSafety(false);
    var prev_percent: u64 = 0;

    const max_sleeps: u8 = 1;
    const sleep_time: u64 = 600_000_000; // nanosec
    var sleeps_count: u8 = 0;

    var i: *usize = &text.processed_types_count;
    while (i.* <= text.tokens_number) : (i.* += 1) {
        // Check if reach the end of tokens list
        if (i.* == text.tokens_number) {
            // If no more tokens for sure then return
            if (text.tokens_number_finalized) return;
            // BEGIN waiting for new tokens (all tokens is processed)
            while (sleeps_count < max_sleeps and i.* == text.tokens_number) {
                std.time.sleep(sleep_time);
                sleeps_count += 1;
                std.debug.print("{s}... wait new tokens\n", .{PAD});
            }
            if (i.* == text.tokens_number) {
                // No new token and timeout
                return;
            } else {
                // Reset sleep counter and continue
                sleeps_count = 0;
            }
        } // END waiting for new tokens

        // Init token
        var token = text.tokens[i.*];

        // is NewLine token
        if (token[0] == '\n') {
            recordNewLineTokenAndShowProgress(text, i.*, &prev_percent);
            continue;
        }

        //  and it's attributes shortcuts
        var attrs = &text.tokens_attrs[i.*];
        var token_written = false;

        // Reserver first-byte to write token attrs
        const firt_byte_index = text.transformed_bytes_len;
        text.transformed_bytes_len += 1;

        if (attrs.category == .alphabet or attrs.category == .marktone) {
            // Since token is alphabet, it's alphabet_types[i]'s info must existed
            const type_info = text.alphabet_types.getPtr(token).?;
            if (type_info.category == ._none) {
                if (syllablizeToken(text, token, type_info)) {
                    // Mark token_written = true to know this is the first token
                    // point to this syllable trans (don't need to write twice)
                    token_written = true;
                } else {
                    // For non-syllable, attrs.category can only be .alphabet or .marktone
                    type_info.*.category = attrs.category;
                }
            }
            if (type_info.*.category == .syllable) {
                attrs.category = .syllable;
                // Point token value to it's syllable trans
                token = type_info.*.transform;
                text.transforms[i.*] = token;
            }
        } // attrs.category == .alphabet or .marktone

        if (!token_written) {
            // write original token it's is not syllable
            for (token) |b| {
                text.transformed_bytes[text.transformed_bytes_len] = b;
                text.transformed_bytes_len += 1;
            }
        }
        // Write attrs at the begin of token's ouput stream
        text.transformed_bytes[firt_byte_index] = @bitCast(u8, attrs.*);
    }
}

fn syllablizeToken(text: *Text, token: []const u8, type_info: *Text.TypeInfo) bool {
    // Not transformed yet
    var char_stream = U2ACharStream.new();
    const syllable = parsers.parseTokenToGetSyllable(
        true,
        printNothing,
        &char_stream,
        token,
    );

    if (syllable.can_be_vietnamese) {
        // First time convert type to syllable
        type_info.category = .syllable;
        // Point token value to it's syllable trans
        const syllable_token = saveAsciiTelexTransform(text, char_stream);
        type_info.transform = syllable_token;
        countSyllableAndSyllower(text, syllable_token, type_info.count) catch unreachable;
        return true;
    }
    return false;
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

fn countSyllableAndSyllower(text: *Text, syllable: []const u8, count: u32) !void {
    // Record and count syllable
    const gop1 = try text.syllable_types.getOrPutValue(syllable, 0);
    gop1.value_ptr.* += count;

    const next = text.syllower_bytes_len + syllable.len;
    const syllower = text.syllower_bytes[text.syllower_bytes_len..next];
    // Convert syllable to lowercase
    for (syllable) |c, i| {
        syllower[i] = c | 0b00100000;
    }
    const gop2 = try text.syllower_types.getOrPutValue(syllower, 0);
    gop2.value_ptr.* += count;
    text.syllower_bytes_len = next;
}

pub fn saveAsciiTelexTransform(text: *Text, char_stream: U2ACharStream) []const u8 {
    // Convert input's utf-8 to output's ascii-telex
    const bytes_len = &text.transformed_bytes_len;
    const trans_start_at = bytes_len.*;

    if (char_stream.is_upper_case) {
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
        if (char_stream.is_title_case) {
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
