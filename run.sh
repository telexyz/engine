#!/bin/sh

rm data/0*.txt
rm data/1*.txt

~/zig build && ./zig-out/bin/telexify data/titles_1k.txt data/titles_1k_tknz.txt

# ~/zig run telexify.zig -O ReleaseFast -- ../corpus/fb_comments_10m.txt ../corpus/fb_comments_10m_tknz.txt

# ~/zig run telexify.zig -O ReleaseFast -- ../corpus/best_vi_translation_train.txt ../corpus/best_vi_translation_train_tknz.txt

# ~/zig run telexify.zig -O ReleaseFast -- ../corpus/corpus-title.txt ../corpus/corpus-title_tknz.txt

# ~/zig run telexify.zig -- ../corpus/VNESEcorpus.txt ../corpus/VNESEcorpus_tknz.txt

# ~/zig run telexify.zig -O ReleaseSafe -- ../corpus/VNTQcorpus.txt ../corpus/VNTQcorpus_tknz.txt

# ~/zig run telexify.zig -- ../corpus/corpus-title-sample.txt ../corpus/corpus-title-sample_tknz.txt 1000
