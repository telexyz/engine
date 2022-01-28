#!/bin/sh

# cc word2vec.c -o word2vec -lm -pthread -O3 -march=native -Wall -funroll-loops -Wno-unused-result

rm word2vec
zig build-exe -lc word2vec.c # -O ReleaseFast

rm word2phrase
zig build-exe -lc word2phrase.c # -O ReleaseFast

# ./word2phrase -train Phaps.xyz -output Phrases.xyz -threshold 100 -debug 2