test "phoneme" {
    _ = @import("./phoneme/syllable_data_structs.zig");
    _ = @import("./phoneme/syllable_parsers.zig");
    _ = @import("./phoneme/test_parse_real_syllables1.zig");
    _ = @import("./phoneme/test_parse_real_syllables2.zig");
}

test "textoken" {
    _ = @import("./textoken/text_data_struct.zig");
    _ = @import("./textoken/output_helpers.zig");
    _ = @import("./textoken/tokenizer.zig");
    _ = @import("./textoken/text_utils.zig");
}

test "counting" {
    // _ = @import("./counting/n_gram.zig");
    _ = @import("./counting/hash_count_123.zig");
    _ = @import("./counting/hash_count_456.zig");
}
