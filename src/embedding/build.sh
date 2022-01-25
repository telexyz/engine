#!/bin/sh

# cc word2vec.c -o word2vec -lm -pthread -O3 -march=native -Wall -funroll-loops -Wno-unused-result

rm word2vec
~/z build-exe -lc word2vec.c -O ReleaseFast