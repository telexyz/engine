#!/bin/sh

rm -rf ***/zig-cache ***/zig-out
# ~/z build -Dcpu=x86_64 -Drelease-fast=true # && cp ./zig-out/bin/telexify ~/bin
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt spare
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt parts
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt dense
# zig run src/count_n_gram.zig -- data/sample_output.txt.cdx

~/z run src/telexify.zig -O ReleaseFast -- ../data/combined.txt ../data/combined.xyz dense
~/z run src/count_n_gram.zig -O ReleaseFast -- ../data/combined.xyz.cdx

# rm data/??-*
# ~/z build
# ./zig-out/bin/telexify ../phaps/data/all.txt data/phaps.utf8 utf8
# ~/z run src/count_n_gram.zig -- data/phaps.utf8.cdx
