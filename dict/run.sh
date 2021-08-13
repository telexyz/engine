#!/bin/sh

# ../zig-out/bin/telexify VnVocab.txt VnVocab.xyz dense ngram
# ruby vocab.rb VnVocab.xyz && git diff VnVocab.xyz
# ../zig-out/bin/telexify wordlist.txt wordlist.xyz dense ngram
# ruby vocab.rb wordlist.xyz && git diff wordlist.xyz

cat wordlist.txt wordlist-full.txt VnVocab.txt > my_dict.txt
../zig-out/bin/telexify my_dict.txt my_dict.xyz
ruby vocab.rb my_dict.xyz