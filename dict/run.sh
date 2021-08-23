#!/bin/sh

../zig-out/bin/telexify tudien-ast.mod.txt 25k.xyz dense
ruby dict.rb 25k.xyz && git diff 25k.xyz

../zig-out/bin/telexify VnVocab.txt 34k.xyz dense
ruby vocab.rb 34k.xyz && git diff 34k.xyz

../zig-out/bin/telexify wordlist.txt 80k.xyz dense
ruby vocab.rb 80k.xyz && git diff 80k.xyz

# cat wordlist.txt wordlist-full.txt VnVocab.txt > combined.txt
../zig-out/bin/telexify combined.txt 88k.xyz
ruby vocab.rb 88k.xyz