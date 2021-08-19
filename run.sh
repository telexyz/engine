#!/bin/sh

# rm data/0*.txt data/1*.txt data/2*.txt data/temp*.txt
# ./clean.sh

# ~/zig build
# ~/zig build -Drelease-safe=true && cp ./zig-out/bin/telexify ~/bin
~/zig build -Drelease-fast=true && cp ./zig-out/bin/telexify ~/bin

# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt parts ngram
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt spare ngram
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt dense ngram
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt spare
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt parts
./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt dense

./zig-out/bin/telexify ../data/combined.txt ../data/combined.xyz dense
# ./zig-out/bin/telexify ../data/fb_comments.txt ../data/fb_comments.dense.xyz dense ngram
# ./zig-out/bin/telexify ../data/vietai_sat.txt ../data/vietai_sat.dense.xyz dense ngram
# ./zig-out/bin/telexify ../data/vi_wiki_all.txt ../data/vi_wiki_all.spare.xyz spare ngram
# ./zig-out/bin/telexify ../data/opensub.vi ../data/opensub.xyz dense ngram

# - - - - - - - - - - - - - - 
# Windows cross-platform build
# Wine Is Not an Emulator: translates Windows API calls into POSIX calls on-the-fly
# brew install wine-stable # wine64 file.exe
# ./clean.sh && zig build -Dtarget=x86_64-windows -Drelease-safe=true
# wine64 zig-out/bin/telexify.exe data/sample_input.txt data/sample_output.txt