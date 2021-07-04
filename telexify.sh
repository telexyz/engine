#!/bin/sh

rm output/*.txt

~/zig run telexify.zig -O ReleaseFast -- input/fb_comments_10m.txt input/fb_comments_10m_tknz.txt

# ~/zig run telexify.zig -O ReleaseFast -- input/best_vi_translation_train.txt input/best_vi_translation_train_tknz.txt

# ~/zig run telexify.zig -O ReleaseFast -- input/corpus-title.txt input/corpus-title_tknz.txt

# ~/zig run telexify.zig -- input/VNESEcorpus.txt input/VNESEcorpus_tknz.txt

# ~/zig run telexify.zig -O ReleaseSafe -- input/VNTQcorpus.txt input/VNTQcorpus_tknz.txt

# zig run telexify.zig -- input/corpus-title-sample.txt input/corpus-title-sample_tknz.txt 1000
