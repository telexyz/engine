#!/bin/sh
~/zig build test
~/zig test src/lib/fastfilter/binaryfusefilter.zig --test-filter binaryFuse16 -O ReleaseFast
~/zig test src/lib/hash_map.zig