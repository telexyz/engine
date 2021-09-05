#!/bin/sh

rm data/temp* # data/0?-*.txt data/1?-*.txt data/3?-*.txt
# rm -rf ***/zig-cache ***/zig-out

# ~/zig build -Drelease-safe=true && cp ./zig-out/bin/telexify ~/bin
# ~/zig build

# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt spare
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt parts
# ./zig-out/bin/telexify data/sample_input.txt data/sample_output.txt dense
# ~/zig run src/count_n_gram.zig -- data/sample_output.txt.cdx

# ./zig-out/bin/telexify ../data/combined.txt ../data/combined.xyz dense ngram
~/zig run src/count_n_gram.zig -O ReleaseFast -- ../data/combined.xyz.cdx

# ./zig-out/bin/telexify ../data/news_titles.txt ../data/news_titles.xyz dense
# ./zig-out/bin/telexify ../data/fb_comments.txt ../data/fb_comments.dense.xyz dense ngram
# ./zig-out/bin/telexify ../data/vietai_sat.txt ../data/vietai_sat.dense.xyz dense
# ./zig-out/bin/telexify ../data/vi_wiki_all.txt ../data/vi_wiki_all.spare.xyz spare
# ./zig-out/bin/telexify ../data/opensub.vi ../data/opensub.xyz dense
