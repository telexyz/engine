#!/bin/sh

# rm -rf ***/zig-cache ***/zig-out
zig build -Drelease-fast=true
cp ./zig-out/bin/* ~/bin
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt spare
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt parts
./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt utf8
# zig run src/telegram.zig -- data/sample_output.txt.cdx

# zig run src/telexify.zig -O ReleaseFast -- ../data/combined.txt ../data/combined.xyz dense
# zig run src/make_n_gram.zig -O ReleaseFast -- ../data/combined.xyz.cdx

# rm data/??-*
# zig build
# ./zig-out/bin/telexify ../phaps/data/all.txt data/phaps.utf8 utf8
# zig run src/telegram.zig -- data/phaps.utf8.cdx
