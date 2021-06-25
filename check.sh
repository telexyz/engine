#!/bin/sh

zig test src/syllable_data.zig

zig test src/parsers.zig

zig test src/converters.zig

zig test test_against_vn_syllables.zig