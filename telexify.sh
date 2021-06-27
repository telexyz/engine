#!/bin/sh

rm _output/*.txt

~/zig run telexify.zig -O ReleaseFast -- _input/corpus/corpus-title.txt _output/telexified/corpus-title.txt

# ~/zig run telexify.zig -- _input/corpus/corpus-title.txt _output/telexified/corpus-title.txt

# ~/zig run telexify.zig -- _input/test.txt _output/test.txt

# zig run telexify0.zig -O ReleaseFast -- _input/corpus/corpus-title.txt _output/telexified/corpus-title.txt

# zig run telexify.zig -O ReleaseSafe -- _input/corpus/corpus-title.txt _output/telexified/corpus-title.txt

# zig run telexify.zig -O ReleaseSafe -- _input/corpus/VNESEcorpus.txt _output/telexified/VNESEcorpus.txt

# zig run telexify.zig -O ReleaseSafe -- _input/corpus/VNTQcorpus-big.txt _output/telexified/VNTQcorpus.txt

# zig run telexify.zig -- _input/corpus/corpus-title-sample.txt _output/telexified/corpus-title-sample.txt 1000
