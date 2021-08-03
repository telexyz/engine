#!/bin/sh

rm data/0*.txt
rm data/1*.txt

~/zig build -Drelease-fast=true
# ~/zig build -Drelease-safe=true

# cp ./zig-out/bin/telexify ~/repos/results/bin
cp ./zig-out/bin/telexify ~/bin

# ~/bin/telexify data/news_titles.txt data/tknz.txt parts ngram # warm up
~/bin/telexify ~/repos/results/news_titles.txt data/news_titles.dense.xyz dense ngram

# ~/zig build
# ~/bin/telexify dict/VnVocab.txt dict/VnVocab.xyz dense ngram # warm up
# ~/zig run src/play_with_chars.zig

# - - - - - - - - - - - - - - 
# Windows cross-platform build
# Wine Is Not an Emulator: translates Windows API calls into POSIX calls on-the-fly
# brew install wine-stable # wine64 file.exe
# ./clean.sh && zig build -Dtarget=x86_64-windows -Drelease-safe=true
# wine64 zig-out/bin/telexify.exe data/news_titles.txt data/tknz.txt