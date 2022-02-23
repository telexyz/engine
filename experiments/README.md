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

https://sites.cs.ucsb.edu/~tyang/class/240a17/slides/SIMD.pdf

Intel SSE / SSE2
SSE = streaming SIMD extensions

• SSE2/3/4, new 8 128-bit registers [1999]
• AVX, new 256-bit registers [2011]

SSE2 data types: anything that fits into 16 bytes, e.g.,


https://stackoverflow.blog/2020/07/08/improving-performance-with-simd-intrinsics-in-three-use-cases



https://www.eidos.ic.i.u-tokyo.ac.jp/~tau/lecture/parallel_distributed/slides/pdf/simd2.pdf