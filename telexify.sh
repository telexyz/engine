#!/bin/sh

rm _output/*.txt

~/zig run telexify.zig -O ReleaseFast -- _input/fb_comments_10m.txt _input/fb_comment_10m_tknz.txt

# ~/zig run telexify.zig -O ReleaseFast -- _input/best_vi_translation_train.txt _input/best_vi_translation_train_tknz.txt

# ~/zig run telexify.zig -O ReleaseFast -- _input/corpus-title.txt _input/corpus-title_tknz.txt

# zig run telexify.zig -O ReleaseSafe -- _input/VNESEcorpus.txt _input/VNESEcorpus_tknz.txt

# zig run telexify.zig -O ReleaseSafe -- _input/VNTQcorpus-big.txt _input/VNTQcorpus_tknz.txt

# zig run telexify.zig -- _input/corpus-title-sample.txt _input/corpus-title-sample_tknz.txt 1000
