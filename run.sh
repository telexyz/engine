#!/bin/sh

# ./clean.sh && 
# ~/zig build
~/zig build -Drelease-safe=true && cp ./zig-out/bin/telexify ~/bin
# ~/zig build -Drelease-fast=true && cp ./zig-out/bin/telexify ~/bin

# ./zig-out/bin/telexify data/news_titles.txt data/tknz.txt parts ngram # test run
# ./zig-out/bin/telexify data/news_titles.txt data/tknz.txt parts
# ./zig-out/bin/telexify data/news_titles.txt data/tknz.txt dense ngram
# ./zig-out/bin/telexify data/news_titles.txt data/tknz.txt dense
# ./zig-out/bin/telexify data/news_titles.txt data/tknz.txt spare ngram
# ./zig-out/bin/telexify data/news_titles.txt data/tknz.txt spare
./zig-out/bin/telexify ../data/fb_comments.txt ../data/fb_comments.dense.xyz dense
./zig-out/bin/telexify ../data/vietai_sat.txt ../data/vietai_sat.dense.xyz dense ngram

# ~/bin/telexify ~/repos/data/news_titles.txt ~/repos/data/news_titles.dense.xyz dense ngram
# ~/bin/telexify ~/repos/data/fb_comments.txt ~/repos/data/fb_comments.dense.xyz dense ngram
# ~/bin/telexify ~/repos/data/vietai_sat.txt ~/repos/data/vietai_sat.dense.xyz dense ngram
# ~/bin/telexify ~/repos/data/vi_wiki_all.txt ~/repos/data/vi_wiki_all.spare.xyz spare ngram
# ~/bin/telexify ~/repos/data/all.txt ~/repos/data/all.dense.xyz dense ngram

# ~/zig build
# ~/bin/telexify dict/VnVocab.txt dict/VnVocab.xyz dense ngram
# ~/zig run src/play_with_chars.zig

# - - - - - - - - - - - - - - 
# Windows cross-platform build
# Wine Is Not an Emulator: translates Windows API calls into POSIX calls on-the-fly
# brew install wine-stable # wine64 file.exe
# ./clean.sh && zig build -Dtarget=x86_64-windows -Drelease-safe=true
# wine64 zig-out/bin/telexify.exe data/news_titles.txt data/tknz.txt