test "phoneme" {
    _ = @import("./src/phoneme/syllable_data_structs.zig");
    _ = @import("./src/phoneme/syllable_parsers.zig");
    _ = @import("./src/phoneme/test_parse_real_syllables1.zig");
    _ = @import("./src/phoneme/test_parse_real_syllables2.zig");
}

test "textoken" {
    _ = @import("./src/textoken/text_data_struct.zig");
    _ = @import("./src/textoken/output_helpers.zig");
    _ = @import("./src/textoken/tokenizer.zig");
    _ = @import("./src/textoken/text_utils.zig");
}

test "counting" {
    // _ = @import("./src/counting/n_gram0.zig");
    _ = @import("./src/counting/n_gram.zig");
    _ = @import("./src/counting/hash_count.zig");
}

test "lib" {
    // _ = @import("./src/lib/hash_map.zig");
    // _ = @import("./src/lib/fastfilter/binaryfusefilter.zig");
}
