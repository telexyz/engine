#!/bin/sh

# zig test src/syllable_data_structs.zig

# zig test src/parsers.zig

# zig test src/converters.zig

zig test test_against_vn_syllables.zig

zig test src/text.zig

zig test telexify.zig