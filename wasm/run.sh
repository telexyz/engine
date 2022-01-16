#!/bin/sh

# ln -s ../src .

zig build-lib vn_telex.zig -target wasm32-freestanding -dynamic -Drelease-fast=true

node vn_test.js