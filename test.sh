#!/bin/sh

# ./clean.sh

~/zig test src/test_parser_with_real_syllables.zig

~/zig test src/syllable_data_structs.zig

~/zig test src/text_data_struct.zig

~/zig test src/syllable_parsers.zig

~/zig test src/n_gram_trie.zig

~/zig test src/tokenizer.zig

~/zig test src/n_gram.zig

~/zig test telexify.zig