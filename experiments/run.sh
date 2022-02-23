#!/bin/sh
zig run simd.c -O ReleaseFast -Dcpu=x86_64+avx
# x86_64