#!/bin/sh

rm data/0*.txt
rm data/1*.txt

~/zig build -Drelease-fast=true
# ./zig-out/bin/telexify data/news_titles.txt data/news_titles_tknz.txt

./zig-out/bin/telexify ../data/fb_comments.txt ../data/fb_comments_tknz.txt

# ./zig-out/bin/telexify ../data/vietai_sat.txt ../data/vietai_sat_tknz.txt

# ./zig-out/bin/telexify ../data/news_titles.txt ../data/news_titles_tknz.txt

# ~/zig run telexify.zig -- ../data/VNESEcorpus.txt ../data/VNESEcorpus_tknz.txt

# ~/zig run telexify.zig -O ReleaseSafe -- ../data/VNTQcorpus.txt ../data/VNTQcorpus_tknz.txt

