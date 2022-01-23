# Deploy to Applications
https://github.com/telexyz/fivefingers


# Optimizing

## Use SIMD

https://github.com/michal-z/zig-gamedev/blob/main/libs/common/zmath.zig

https://github.com/travisstaloch/simdjzon

* Có hàm `parse_number` để lưu number_token thành `u32` chẳng hạn
  https://github.com/travisstaloch/simdjzon/blob/main/src/number_parsing.zig


## Use Fast Filters

https://github.com/hexops/fastfilter#benchmarks

Chỉ dùng `BinaryFuse` để lưu và tính n-gram language-model
xem `src/counting/language_model.zig`