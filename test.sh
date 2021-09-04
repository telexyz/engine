#!/bin/sh
~/zig build test
~/zig test src/lib/fastfilter/binaryfusefilter.zig
~/zig test src/lib/hash_map.zig