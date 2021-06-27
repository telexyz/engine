## Buig zig from source

https://github.com/ziglang/zig/wiki/Building-Zig-From-Source

```sh
cd ~/repos
git clone https://github.com/ziglang/zig.git
cd zig

mkdir build
cd build
cmake .. -DCMAKE_PREFIX_PATH=$(brew --prefix llvm) 
# To compile in release mode use the -DCMAKE_BUILD_TYPE=Release flag
# cmake .. -DCMAKE_PREFIX_PATH=$(brew --prefix llvm) -DCMAKE_BUILD_TYPE=Release
make install
sudo ln -s ~/repos/zig/build/bin/zig ~/zig
~/zig
```

```

### Useful Zig utils to processing text

https://github.com/ziglang/zig/blob/master/lib/std/mem.zig

```js
pub fn startsWith(comptime T: type, haystack: []const T, needle: []const T) bool {

pub fn endsWith(comptime T: type, haystack: []const T, needle: []const T) bool {

pub fn join(allo..: *Allocator, separator: []const u8, slices: []const []const u8) ![]u8 {

pub fn concat(allocator: *Allocator, comptime T: type, slices: []const []const T) ![]T {

pub fn replace(comptime T: type, input: []const T, needle: []const T, replacement: []const T, output: []T) usize {

replacements = replace(u8, "Favor reading code over writing code.", "code", "", outp..);
expected = "Favor reading  over writing .";

/// Returns true if lhs < rhs, false otherwise
pub fn lessThan(comptime T: type, lhs: []const T, rhs: []const T) bool {
    return order(T, lhs, rhs) == .lt;
}
test "mem.lessThan" {
    try testing.expect(lessThan(u8, "abcd", "bee"));
    try testing.expect(!lessThan(u8, "abc", "abc"));
    try testing.expect(lessThan(u8, "abc", "abc0"));
    try testing.expect(!lessThan(u8, "", ""));
    try testing.expect(lessThan(u8, "", "a"));
}

/// Compares two slices and returns whether they are equal.
pub fn eql(comptime T: type, a: []const T, b: []const T) bool {

/// Compares two slices and returns the index of the first inequality.
/// Returns null if the slices are equal.
pub fn indexOfDiff(comptime T: type, a: []const T, b: []const T) ?usize {

/// Remove values from the beginning of a slice.
pub fn trimLeft(comptime T: type, slice: []const T, values_to_strip: []const T) []const T

/// Remove values from the end of a slice.
pub fn trimRight(comptime T: type, slice: []const T, values_to_strip: []const T) []const T

/// Remove values from the beginning and end of a slice.
pub fn trim(comptime T: type, slice: []const T, values_to_strip: []const T) []const T {

pub fn indexOf(comptime T: type, haystack: []const T, needle: []const T) ?usize {

pub fn lastIndexOf(comptime T: type, haystack: []const T, needle: []const T) ?usize {

pub fn count(comptime T: type, haystack: []const T, needle: []const T) usize {

pub fn containsAtLeast(comptime T: type, haystack: []const T, expected_count: usize, needle: []const T) bool {
```
```js
test "mem.split (multibyte)" {
    var it = split("a, b ,, c, d, e", ", ");
    try testing.expect(eql(u8, it.next().?, "a"));
    try testing.expect(eql(u8, it.next().?, "b ,"));
    try testing.expect(eql(u8, it.next().?, "c"));
    try testing.expect(eql(u8, it.next().?, "d"));
    try testing.expect(eql(u8, it.next().?, "e"));
    try testing.expect(it.next() == null);
}

test "mem.tokenize (multibyte)" {
    var it = tokenize("a|b,c/d e", " /,|");
    try testing.expect(eql(u8, it.next().?, "a"));
    try testing.expect(eql(u8, it.next().?, "b"));
    try testing.expect(eql(u8, it.next().?, "c"));
    try testing.expect(eql(u8, it.next().?, "d"));
    try testing.expect(eql(u8, it.next().?, "e"));
    try testing.expect(it.next() == null);
}
```

### Finding Suitable Data Structures to store inverted index array

#### Exploring Zig's PackedIntArray

First build reverted index using normal arrays

Second pack normal arrays into `PackedIntArray` struct to save memory. Number of memory saved depend on how the diff between max and min elements you have in the normal array and the number of padding bit you need to store them in bytes (that the smallest unit memory working on). Let say: you have an array of term => doc_ids: 

`{ "machine":  [500, 301, 600, 1000] }` Then `min = 500; max = 1000; diff = 500;` so `2^9` is enough to store diff. Unfortunately memory only understand bytes, which is 8-bits, so you need at least 2-bytes to store diff values. So 4 elements above need `4 * 2 = 8 bytes` to store.

By using PackedIntArray, you only need `(4 * 9 + 7) / 8 = 5 bytes` to store. You save 38% of memory. The more bytes you need to store the diff, the less efficient PackedIntArray is. Since the padding bits is just a tiny fraction compare to the main bit sequence. In the other words, `PackedIntArray` is very good to store small values and those values do not fit to bytes nicely(not `u8`, `u16`, `u32` ... for example).

Let say we don't need to index billions of documents. And `u28` (268,435,456) is enough.
Let say each search-term-to-document-ids array store 1000 random ids. Normally we need 
`1000 * 32 / 8 = 4kb` using PackedIntArray we need `(1000 * 28 + 7) / 8 = 3.5kb` => 12.5% saved. Since the # of document is high and # of words in each document is low, there are good chance that the diff between min and max values is not big, let say on average we can cut 1-bit per value by storing diffs instead of real values, then we need `(1000 * 27 + 7) / 8 = 3.38kb` => 15.5% saved. Not sinificant enough! We expect 30-to-50% saved to make it a worth implementation. Am I right?


```js Source: pack_int_array.zig
a = PackedIntArray(i3, 8);
a.init([1,2,3]);
a.len(); // => 8
a.get(2); // => 3
a.set(2, 5);
a.get(2); // => 5

// Unfortunately PackedIntArray did not work for wasm32 yet!
test "PackedIntArray" {
    // TODO @setEvalBranchQuota generates panics in wasm32. Investigate.
    if (builtin.target.cpu.arch == .wasm32) return error.SkipZigTest;
    // ...

```

[ QUESTION ] How about wasm64? Can PackedIntArray works with wasm64? Do browsers support wasm64?

I got it. The PackedIntArray is efficient when the values needed to store is small and specific enough to make bit padding make a significant impact. For example `u16` is perfect to fit into to bytes so PackedIntArray is not needed. Or a very big value `u257` (for example) that make `7-padding-bits` look tiny compare to the main bits `7/257=2.7%`. am i right?


## Read, write string zig <=> js

https://blog.bitsrc.io/a-complete-introduction-to-webassembly-and-its-javascript-api-3474a9845206

https://stackoverflow.com/questions/41353389/how-can-i-return-a-javascript-string-from-a-webassembly-function


## (Zig) Memory Management

What's a Memory Allocator Anyway? - Benjamin Feng
https://www.youtube.com/watch?v=vHWiDx_l4V0

https://ziglearn.org/chapter-2/#allocators


## A half-hour to learn Zig

https://ikrima.dev/dev-notes/zig/zig-metaprogramming/

https://gist.github.com/ityonemo/769532c2017ed9143f3571e5ac104e50

https://news.ycombinator.com/item?id=25618302

Hey man, first of all thanks a lot for you efforts. This and ziglearn.org are just great as a starting point.

If I may here are three additional pieces of information that if added to your documentation will clarify some more things for the beginner/reader:

1) Arrays and Slices section

Arrays in Zig are values. They store the pointer and the length, but an array is a value so the raw pointer can never be accesses unless....

You coerce the array to a slice. A slice reveals a pointer to you.

2) Add tagged unions (I do not understand what they are but they exist, maybe some fellow reader here could help me)

3) If, for, while and switch can ALSO BE EXPRESSIONS!
