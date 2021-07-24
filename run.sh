#!/bin/sh

rm data/0*.txt
rm data/1*.txt
rm data/2*.txt
rm data/*tknz.txt

~/zig build -Drelease-fast=true
# ~/zig build -Drelease-safe=true
cp ./zig-out/bin/telexify ~/nlp
~/nlp/telexify data/news_titles.txt data/tknz.txt # warm up
# ~/nlp/telexify ../results/news_titles.aa ../results/news_titles.aa.xyz

# Windows cross-platform build
# Wine Is Not an Emulator: translates Windows API calls into POSIX calls on-the-fly
# brew install wine-stable # wine64 file.exe
# ./clean.sh && zig build -Dtarget=x86_64-windows -Drelease-safe=true
# wine64 zig-out/bin/telexify.exe data/news_titles.txt data/tknz.txt