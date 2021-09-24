## Buig zig from source

https://github.com/ziglang/zig/wiki/Building-Zig-From-Source

```sh
cd ~/repos
git clone https://github.com/ziglang/zig.git
cd zig

brew install cmake gcc llvm
mkdir build && cd build

cmake .. -DCMAKE_PREFIX_PATH=$(brew --prefix llvm) \
    -DCMAKE_BUILD_TYPE=Release -DZIG_STATIC_LLVM=on
make install
ln -s ~/repos/zig/build/bin/zig ~/zig && ~/zig
```
NOTE: On macOS, since LLVM 12.0 release, Homebrew's packaged LLVM reports itself as a dynamic dependency while Zig's config system will expect a static dependency. This can lead to unexpected errors when trying to compile C/C++ with Zig. To force static linking of LLVM, use -DZIG_STATIC_LLVM=on flag.

__stage2__
```sh
cd zig
~/zig build --prefix $(pwd)/stage2 -Denable-llvm -Drelease=true
ln -s ~/repos/zig/stage2/bin/zig ~/zig2 && ~/zig2
```
