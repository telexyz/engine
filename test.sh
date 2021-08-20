#!/bin/sh

# ./clean.sh

~/zig test src/test_parse_real_syllables1.zig

~/zig test src/test_parse_real_syllables2.zig

~/zig test src/syllable_data_structs.zig

~/zig test src/text_data_struct.zig

~/zig test src/syllable_parsers.zig

~/zig test src/tokenizer.zig

~/zig test src/n_gram.zig

~/zig test telexify.zig