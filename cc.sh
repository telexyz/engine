#!/bin/sh
scc --exclude-dir src/lib --exclude-dir .save -M \.txt --no-cocomo
rm -rf zig-cache zig-out
ls
time ~/zig build test