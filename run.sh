#!/bin/sh

rm data/0*.txt
rm data/1*.txt

~/zig build && ./zig-out/bin/telexify data/news_titles.txt data/news_titles_tknz.txt

# ~/zig run telexify.zig -O ReleaseFast -- ../data/fb_comments_10m.txt ../data/fb_comments_10m_tknz.txt

# ~/zig run telexify.zig -O ReleaseFast -- ../data/best_vi_translation_train.txt ../data/best_vi_translation_train_tknz.txt

# ~/zig run telexify.zig -O ReleaseFast -- ../data/news_titles_10m.txt ../data/news_titles_10m_tknz.txt

# ~/zig run telexify.zig -- ../data/VNESEcorpus.txt ../data/VNESEcorpus_tknz.txt

# ~/zig run telexify.zig -O ReleaseSafe -- ../data/VNTQcorpus.txt ../data/VNTQcorpus_tknz.txt
