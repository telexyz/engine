#!/bin/sh

# rm data/0*.txt
# rm data/1*.txt
# rm data/*tknz.txt

~/zig build -Drelease-fast=true
# ~/zig build -Drelease-safe=true
cp ./zig-out/bin/telexify ~/nlp
~/nlp/telexify data/news_titles.txt data/tknz.txt # warm up
~/nlp/telexify ../data/news_titles.txt data/tknz.txt
# ~/nlp/telexify ../data/vietai_sat.txt data/tknz.txt

# rm data/vocab data/codes data/tknz.bpe.txt
# ~/nlp/fast getvocab data/tknz.txt > data/vocab
# ~/nlp/fast learnbpe 4000 data/tknz.txt > data/codes
# ~/nlp/fast applybpe data/tknz.bpe.txt data/tknz.txt data/codes data/vocab

# touch data/blank.txt
# python3 ot_run.py --source_file data/tknz.bpe.txt --target_file data/blank.txt \
#   --token_candidate_file data/codes  --vocab_file data/vocab --max_number 8000 \
#   --interval 800  --loop_in_ot 300 --tokenizer subword-nmt --size_file data/size
