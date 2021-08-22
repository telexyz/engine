test "all" {
    _ = @import("./src/phoneme/syllable_data_structs.zig");
    _ = @import("./src/phoneme/syllable_parsers.zig");
    _ = @import("./src/phoneme/test_parse_real_syllables1.zig");
    _ = @import("./src/phoneme/test_parse_real_syllables2.zig");

    _ = @import("./src/textoken/text_data_struct.zig");
    _ = @import("./src/textoken/output_helpers.zig");
    _ = @import("./src/textoken/tokenizer.zig");
    _ = @import("./src/textoken/text_utils.zig");

    _ = @import("./src/n_gram.zig");
}
