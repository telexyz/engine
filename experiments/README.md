# Dùng SIMD để phân tích âm vị học âm tiết tiếng Việt

Mục tiêu cuối phân tách âm tiết utf-8 thành `âm đầu + âm giữa + âm cuối + thanh điệu`


## Bài toán nhập môn: phân tách âm tiết ở dạng ascii-telex

* Để làm quen với lập trình hệ thống và SIMD

* Tập làm quen với phân tích ngữ âm

`tuoizr` => `t` + `uoz` + `i` + `r`
- âm đầu `t`
- âm giữa `uoz` (`uô`)
- âm cuối `i`
- thanh điệu `r` (hỏi)


- - -


## Tài liệu SIMD

http://0x80.pl/articles/simd-byte-lookup.html


- - -


http://0x80.pl/articles/simd-strfind.html | https://github.com/WojciechMula/sse4-strstr


The main problem with these standard algorithms is a silent assumption that comparing a pair of characters, looking up in an extra table and conditions are cheap, while comparing two substrings is expansive. But current desktop CPUs do not meet this assumption, in particular:


* There is no difference in comparing one, two, four or 8 bytes on a 64-bit CPU. When a processor supports SIMD instructions, then comparing vectors (it means 16, 32 or even 64 bytes) is as cheap as comparing a single byte. => Thus comparing short sequences of chars can be faster than fancy algorithms which avoids such comparison.

* Looking up in a table costs one memory fetch, so at least a L1 cache round (3 cycles). Reading char-by-char also cost as much cycles.

* Mispredicted jumps cost several cycles of penalty (10-20 cycles).

* There is a short chain of dependencies: read char, compare it, conditionally jump, which make hard to utilize out-of-order execution capabilities present in a CPU.


- - -


https://github.com/michal-z/zig-gamedev/tree/main/libs/zmath


https://sites.cs.ucsb.edu/~tyang/class/240a17/slides/SIMD.pdf

Intel SSE / SSE2
SSE = streaming SIMD extensions

• SSE2/3/4, new 8 128-bit registers [1999]
• AVX, new 256-bit registers [2011]

SSE2 data types: anything that fits into 16 bytes, e.g.,


https://www.eidos.ic.i.u-tokyo.ac.jp/~tau/lecture/parallel_distributed/slides/pdf/simd2.pdf