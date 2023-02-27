#!/bin/sh

# rm -rf ***/zig-cache ***/zig-out
# zig build -Drelease-fast=true
# zig build -Drelease-safe=true
# zig build
sudo cp ./zig-out/bin/* /usr/local/bin/
cp ./zig-out/bin/telexify ../vi
./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt utf8 ngram
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt spare
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt parts
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt dense
# tail data/sample_input.txt data/sample_output.txt
# zig run src/telegram.zig -- data/sample_output.txt.cdx

# zig run src/telexify.zig -O ReleaseSafe -- ../data/vi_wiki_all.txt ../data/vi_wiki_all.xyz dense
# zig run src/telexify.zig -O ReleaseSafe -- ../thogpt/data/tho00_luc-bat_4-chu_5-chu_7-chu_8-chu.txt data/out.xyz dense

# zig run src/telexify.zig -O ReleaseFast -- ../data/combined.txt ../data/combined.xyz dense
# zig run src/make_n_gram.zig -O ReleaseFast -- ../data/combined.xyz.cdx

# rm data/??-*
# zig build
# ./zig-out/bin/telexify ../phaps/data/all.txt data/phaps.utf8 utf8
# zig run src/telegram.zig -- data/phaps.utf8.cdx
