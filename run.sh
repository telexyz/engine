#!/bin/sh

zig build && ./zig-out/bin/telex nguyeenx
# zig build run # performance test by default

cd wasm
zig build-lib vn_telex.zig -target wasm32-freestanding -dynamic -Drelease-fast=true && node vn_test.js
cd ..