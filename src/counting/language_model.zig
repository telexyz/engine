// For 1..6-grams language model from `data/2{x}-grams.{bin|one|two}`
//
// * Let V = data/21-grams.bin
//
// * Absoluted Discount Smoothing + Stupid Backoff for the sake of Simplicity
//   See `docs/n-gram_smoothing.md` (Kneser-Ney is the best but require more
//   computation and the bigger the corpus is the nearer they are converged)

// Total Mem 531 MB
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// * 268 MB `BinaryFuseFilter`: 16-bits per key grams with count = 1
// *  60 MB `BinaryFuseFilter`: 32-bits per key grams with count = 2
// * 131 MB `HashCount456`: 7-bytes key represent + 2-byte count for 4,5,6-grams
// *  72 MB `HashCount123`: 6-bytes key represent + 3-byte count for 1,2,3-grams
// Note: thời gian khởi tạo BinaryFuseFilter lâu, có thể khởi tạo trước rồi load
//       16-bit BFF có tỉ lệ va chạm 1/2^16 (~0.0015%) và speed x2 bloom filter

const BinaryFuse = @import("../lib/fastfilter/binaryfusefilter.zig").BinaryFuse;
c1_filter = try BinaryFuse(u16).init(std.heap.page_allocator, size);
