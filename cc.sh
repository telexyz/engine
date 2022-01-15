#!/bin/sh
scc --exclude-dir src/lib --exclude-dir .save -M \.txt --no-cocomo
rm -rf zig-cache zig-out
lsd -F --group-dirs=first src
time /Users/t/repos/zig/build/zig build test