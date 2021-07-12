#!/bin/sh

rm data/0*.txt
rm data/1*.txt
rm data/*tknz.txt

~/zig build -Drelease-fast=true
# ./zig-out/bin/telexify data/news_titles.txt data/tknz.txt # warm up
# ./zig-out/bin/telexify ../corpus/vietai_sat.txt data/tknz.txt

./zig-out/bin/telexify ~/repos/phap/corpus/all.txt data/tknz.txt

rm data/vocab data/codes data/tknz.bpe.txt
./fast getvocab data/tknz.txt > data/vocab
./fast learnbpe 4000 data/tknz.txt > data/codes
./fast applybpe data/tknz.bpe.txt data/tknz.txt data/codes data/vocab

# touch blank.txt
# python3 ot_run.py --source_file tknz.bpe.txt --target_file blank.txt \
#   --token_candidate_file codes  --vocab_file vocab --max_number 8000 \
#   --interval 800  --loop_in_ot 300 --tokenizer subword-nmt --size_file size
