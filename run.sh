#!/bin/sh

rm data/0*.txt
rm data/1*.txt
rm data/*tknz.txt

~/zig build -Drelease-fast=true
./zig-out/bin/telexify data/news_titles.txt data/tknz.txt # warm up
./zig-out/bin/telexify ../corpus/vietai_sat.txt ../corpus/_tknz.txt
