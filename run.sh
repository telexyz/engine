#!/bin/sh

rm data/temp* # data/0?-*.txt data/1?-*.txt data/3?-*.txt
# rm -rf ***/zig-cache ***/zig-out

~/zig build -Drelease-fast=true # && cp ./zig-out/bin/telexify ~/bin
# ~/zig build

# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt spare
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt parts
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt dense
# ~/zig run src/count_n_gram.zig -- data/sample_output.txt.cdx

# ./zig-out/bin/telexify ../data/_train.txt ../data/_train.xyz dense
# ~/zig run src/count_n_gram.zig -O ReleaseFast -- ../data/_train.xyz.cdx

# ./zig-out/bin/telexify ../data/combined.txt ../data/combined.xyz dense
~/zig run src/count_n_gram.zig -O ReleaseFast -- ../data/combined.xyz.cdx
