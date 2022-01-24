# Deploy to Applications
https://github.com/telexyz/fivefingers


# Optimizing


RULE OF THUMBS

Ở phần càng cơ bản càng tránh dùng Supervised Machine learning vì cần phải gán nhãn dữ liệu và bộ ML decoder chạy khá chậm.

Áp dụng tối đa pattern matching, kết hợp với dynamic programming để ra kết quả tối ưu toàn cục.

- - -

NÊN DÙNG

## Dùng rule-based thay cho IMF Trie để dự đoán âm tiết đang gõ

* Giảm kích thước chương trình do không phải tích hợp trie lib

* Tốc độ chạy cực nhanh do rules được hard-coded


## Sử dụng Fast(est) Filters
   https://github.com/hexops/fastfilter#benchmarks

Chạy nhanh gấp đôi bloom filter, dung lượng lưu trữ nhỏ và xác xuất trùng lặp đủ tốt nếu dùng `BinaryFuse(u16)` (100k mẫu sẽ có 1.5 mẫu bị nhận nhầm)

* Làm pattern-matching (đối sánh với từ điển ...)

* Lưu trũ và tính điểm cho n-gram language model
  xem  `src/counting/language_model.zig`


## Tối giản n-gram

* Bỏ các 3,4-gram có count == 1 để giảm dung lượng lưu trữ còn 1/2


- - -


## Use SIMD (wait until wasm support it officially)

https://github.com/michal-z/zig-gamedev/blob/main/libs/common/zmath.zig

https://github.com/travisstaloch/simdjzon

* Có hàm `parse_number` để lưu number_token thành `u32` chẳng hạn
  https://github.com/travisstaloch/simdjzon/blob/main/src/number_parsing.zig