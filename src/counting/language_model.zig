// LÀM MÔ HÌNH TÁCH THÔ TRƯỚC ĐỂ ÁP DỤNG ĐƯỢC CHO WASM
// - count_n_gram cần xuất ra BinaryFuse format luôn
// - tìm cách đơn giản nhất để ước lượng 1-gram
// - language_model.zig load trực tiếp BinaryFuse cho 2,3,4-gram
// - dùng Stupid Backoff và điểm số 1,2,4,8 để tính điểm chuỗi tokens đầu vào
//   (xem `docs/n-gram_smoothing.md`)

// Tách thô để tiết kiệm MEM ta được:
// TOTAL 74 MB
// ```
// a/ không tồn tại
// b/ count=1,2   => `13_302_179` 3-grams => `14.3 mb BinaryFuse(u8)`
// c/ count=3,4,5 => ` 1_996_665` 3-grams => ` 4.3 mb BinaryFuse(u16)`
// d/ remains     => ` 2_003_518` 3-grams => ` 4.3 mb BinaryFuse(u16)`
//    TOTAL: 23MB
//
// count=1,2   => `1_444_648` 2-grams => `1.5 mb BinaryFuse(u8)`
// count=3,4,5 => `  424_664` 2-grams => `0.9 mb BinaryFuse(u16)`
// remains     => `  796_710` 2-grams => `1.7 mb BinaryFuse(u16)`
// TOTAL: 4.1MB
//
// count=1,2   => `33_287_534` 4-grams => `35.7 mb BinaryFuse(u8)`
// count=3,4,5 => ` 3_116_651` 4-grams => ` 6.7 mb BinaryFuse(u16)`
// remains     => ` 2_297_654` 4-grams => ` 4.9 mb BinaryFuse(u16)`
// TOTAL: 47MB
// ```
//
// Tính điểm khi so khớp với chuỗi tokens đầu vào
// ```
// a/ 1 điểm
// b/ 2 điểm
// c/ 4 điểm
// d/ 8 điểm
// ```
// TODO: Làm https://github.com/hexops/fastfilter#serialization

const BinaryFuse = @import("../fastfilter/binaryfusefilter.zig").BinaryFuse;
var n2_c2_filter = try BinaryFuse(u8).init(std.heap.page_allocator, 1_500_000);
var n2_c4_filter = try BinaryFuse(u16).init(std.heap.page_allocator, 500_000);
var n2_c8_filter = try BinaryFuse(u16).init(std.heap.page_allocator, 800_000);

var n3_c2_filter = try BinaryFuse(u8).init(std.heap.page_allocator, 13_500_000);
var n3_c4_filter = try BinaryFuse(u16).init(std.heap.page_allocator, 2_000_000);
var n3_c8_filter = try BinaryFuse(u16).init(std.heap.page_allocator, 2_100_000);

var n4_c2_filter = try BinaryFuse(u8).init(std.heap.page_allocator, 33_500_000);
var n4_c4_filter = try BinaryFuse(u16).init(std.heap.page_allocator, 3_500_000);
var n4_c8_filter = try BinaryFuse(u16).init(std.heap.page_allocator, 5_500_000);
