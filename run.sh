#!/bin/sh

# rm data/0?-*.txt data/1?-*.txt data/3?-*.txt data/temp*
# rm -rf ***/zig-cache ***/zig-out

# ~/zig build
# ~/zig build -Drelease-safe=true && cp ./zig-out/bin/telexify ~/bin
~/zig build -Drelease-fast=true && cp ./zig-out/bin/telexify ~/bin

# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt spare
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt parts
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt dense ngram

./zig-out/bin/telexify ../data/combined.txt ../data/combined.xyz dense
# ./zig-out/bin/telexify ../data/news_titles.txt ../data/news_titles.xyz dense
# ./zig-out/bin/telexify ../data/fb_comments.txt ../data/fb_comments.dense.xyz dense ngram
# ./zig-out/bin/telexify ../data/vietai_sat.txt ../data/vietai_sat.dense.xyz dense
# ./zig-out/bin/telexify ../data/vi_wiki_all.txt ../data/vi_wiki_all.spare.xyz spare
# ./zig-out/bin/telexify ../data/opensub.vi ../data/opensub.xyz dense

# - - - - - - - - - - - - - - 
# Windows cross-platform build
# Wine Is Not an Emulator: translates Windows API calls into POSIX calls on-the-fly
# brew install wine-stable # wine64 file.exe
# ~/zig build -Dtarget=x86_64-windows -Drelease-safe=true
# wine64 zig-out/bin/telexify.exe data/sample_input.txt data/sample_output.txt