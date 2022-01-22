// LÀM MÔ HÌNH TÁCH THÔ TRƯỚC ĐỂ ÁP DỤNG ĐƯỢC CHO WASM
// - count_n_gram cần xuất ra BinaryFuse format luôn
// - tìm cách đơn giản nhất để ước lượng 1-gram
// - language_model.zig load trực tiếp BinaryFuse cho 2,3,4-gram
// - dùng Stupid Backoff và điểm số 1,2,4,8 để tính điểm chuỗi tokens đầu vào
//   (xem `docs/n-gram_smoothing.md`) 

// For 1..6-grams language model from `data/2{x}-grams.{bin|one|two}`
//
// * Let V = data/21-grams.bin
//
// * Absoluted Discount Smoothing + Stupid Backoff for the sake of Simplicity
//   See `docs/n-gram_smoothing.md` (Kneser-Ney is the best but require more
//   computation and the bigger the corpus is the nearer they are converged)

//   531 MB TOTAL
// * 268 MB `BinaryFuseFilter`: 16-bits per key grams with count = 1
// *  60 MB `BinaryFuseFilter`: 32-bits per key grams with count = 2
// * 131 MB `HashCount456`: 7-bytes key represent + 2-byte count for 4,5,6-grams
// *  72 MB `HashCount123`: 6-bytes key represent + 3-byte count for 1,2,3-grams
// Note: thời gian khởi tạo BinaryFuseFilter lâu, có thể khởi tạo trước rồi load
//       16-bit BFF có tỉ lệ va chạm 1/2^16 (~0.0015%) và speed x2 bloom filter


// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// Tách thô hơn nữa để tiết kiệm MEM ta được:
// TOTAL 74 MB
// ```
// a/ không tồn tại
// b/ count=1,2   => `13_302_179` 3-grams => `14.3 mb BinaryFuse(u8)`
// c/ count=3,4,5 => ` 1_996_665` 3-grams => ` 4.3 mb BinaryFuse(u16)`
// d/ remains     => ` 2_003_518` 3-grams => ` 4.3 mb BinaryFuse(u16)`
//    TOTAL: 23MB
// ```
// Tính điểm khi so khớp với chuỗi tokens đầu vào
// ```
// a/ 1 điểm
// b/ 2 điểm
// c/ 4 điểm
// d/ 8 điểm
// ```
// => !!! Cần đo xem cách tách thô này làm giảm độ hiệu quả của mô hình đi bao nhiêu ???
// ```
// count=1,2   => `1_444_648` 2-grams => `1.5 mb BinaryFuse(u8)`
// count=3,4,5 => `  424_664` 2-grams => `0.9 mb BinaryFuse(u16)`
// remains     => `  796_710` 2-grams => `1.7 mb BinaryFuse(u16)`
// TOTAL: 4.1MB
// ```
// ```
// count=1,2   => `33_287_534` 4-grams => `35.7 mb BinaryFuse(u8)`
// count=3,4,5 => ` 3_116_651` 4-grams => ` 6.7 mb BinaryFuse(u16)`
// remains     => ` 2_297_654` 4-grams => ` 4.9 mb BinaryFuse(u16)`
// TOTAL: 47MB
// ```

const BinaryFuse = @import("../lib/fastfilter/binaryfusefilter.zig").BinaryFuse;
c1_filter = try BinaryFuse(u16).init(std.heap.page_allocator, size);
