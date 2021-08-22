test "all" {
    _ = @import("./libs/phoneme/syllable_data_structs.zig");
    _ = @import("./libs/phoneme/syllable_parsers.zig");
    _ = @import("./libs/phoneme/test_parse_real_syllables1.zig");
    _ = @import("./libs/phoneme/test_parse_real_syllables2.zig");

    _ = @import("./libs/textoken/text_data_struct.zig");
    _ = @import("./libs/textoken/output_helpers.zig");
    _ = @import("./libs/textoken/tokenizer.zig");
    _ = @import("./libs/textoken/text_utils.zig");

    _ = @import("./libs/ngrams/n_gram.zig");
}
