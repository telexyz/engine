#!/bin/sh

rm data/0*.txt
rm data/1*.txt

~/zig build -Drelease-fast=true
# ./zig-out/bin/telexify data/news_titles.txt data/tknz.txt
./zig-out/bin/telexify ../corpus/vietai_sat.txt data/tknz.txt
