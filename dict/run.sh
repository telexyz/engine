#!/bin/sh

../zig-out/bin/telexify VnVocab.txt VnVocab.xyz dense
ruby vocab.rb VnVocab.xyz && git diff VnVocab.xyz

# ../zig-out/bin/telexify wordlist.txt wordlist.xyz dense
# ruby vocab.rb wordlist.xyz && git diff wordlist.xyz

# cat wordlist.txt wordlist-full.txt VnVocab.txt > vn_wordlist.txt
# ../zig-out/bin/telexify vn_wordlist.txt vn_wordlist.xyz
# ruby vocab.rb vn_wordlist.xyz