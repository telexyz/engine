# Bộ tách token và phân tích âm vị học tiếng Việt

## Module 1d/ Tách các âm tiết dính liền nhau (thiếu dấu cách)

Xem `*token_repairs.md`

### Token repair ideas

* Dùng `trans_offets` để transit token_info được tách `Sốngsansẻ` sang mảng `splitted_tokens_infos` (nội dung splitted_tokens được lưu tại `splitted_bytes`). Thêm `splitted` vào `token_info.category`

* Dùng `transit sang splitted_tokens_infos` có điểm dở là chỉ đi tiến, ko đi lùi được nên khi matching với 1 đoạn token và cần matching theo cả 2 chiều thì dùng `TokensChunk = [64]*TokenInfo` để có để di chuyển tiến và lùi.


## Module 1e/ OOS, OOV handling

OVV gồm tiếng dân tộc thiểu số (như Đắk Lắk) và tiếng nước ngoài 
=> Treat OOV as first-class citizen

* Những từ, cách viết tắt hay dùng như "Đắk Lắc", UBND, HĐND ... và các biến thể cần được map vào slot riêng trong `u15` (cùng phân khu với syllable_ids)

* Dùng BPE để phân tách và chứa OOV
  
  https://github.com/telexyz/fastBPE
 
  Xem https://everdark.github.io/k9/notebooks/ml/natural_language_understanding/subword_units/subword_units.nb.html

* Dùng rule-based để tách ngày, tháng, số đếm, công thức ...

[ >>> HERE I SHOULD BE, DOWN THE RABBIT HOLE <<< ]

[ >>> DONE <<< ]

## CHANGELOG

* Kiểm tra tính đúng đắn của syllable_id, đảm bảo càng nhiều chỗ trống càng tốt cho OOV

* Thêm luật để lọc từ ko có nghĩa `chuẩm, quyểng, quyểm, quyếc ..`

* Loại bỏ câu có lượng âm tiết + alphamark < 50% (tính theo bytes length)

* 18/08/2021: Dùng base64 để ghi syllable_ids, ghi token's attrs và syllable_ids ở 1 dòng riêng

* Tối ưu hoá tốc độ ghi ra bằng cách thêm length vào đầu type's value, bỏ qua line có too long token

* Tối ưu hoá tốc độ ghi ra bằng cách bỏ qua syllable_id khi đọc tokens_infos

* Viết thẳng tknz output ra file, bỏ qua bộ đệm để không phải khởi tạo nhiều bộ nhớ đệm

*  08/08/2021: Nén input vào bộ tự điển `alphabet_types` và `nonalpha_types` vừa giữ được đầu vào nguyên bản của `token` vừa đếm `types`. Dùng `trans_offset + alphabet_bytes/nonalpha_bypes` để tính ra `trans_ptr`. `trans` viết tắt của `transit` (dịch chuyển) hoặc `transform` (biến đổi), hoặc `translate` (dịch (ngôn ngữ))

* Tối ưu hoá việc nhận dạng ký tự đặc trưng tiếng Việt (kí tự có dấu + thanh): khi mã hoá bằng utf-8, dùng tới 2-3 bytes để lưu trữ rồi phải chuyển đổi thành `u21` mới trở thành dạng mã hoá cuối cùng của một ký tự utf-8. Tìm cách không phải chuyển đổi mà dùng trực tiếp giá trị của 1 hoặc 2 byte đầu tiên để tra xét nhanh. Trình bày lại một dạng ký tự tiếng Việt bằng `u10` đã tách thanh điệu, đánh dấu viết hoa vs viết thường để tối ưu việc phân tích âm vị (xem `src/telex_utils.zig`). Xử lý cả mã unicode tổ hợp lẫn cách viết telex ...

* Dự đoán ký tự utf-8 nào thuộc bảng chữ cái tiếng Việt để segment văn bản thật nhanh thành `alphamark`, `alph0m0t`, `nonalpha`

* Parse `alphamark` và `alph0m0t` có độ dài <= 10 bytes để tìm ra các `syllables` tiếng Việt

* Mỗi `syllable` được gán với 1 universal id 16-bits. Từ id này có thể dựng lại âm tiết tiếng Việt không dấu mà không cần từ điển

* Khi parse syllable tiếng Việt tự động sửa lỗi những trường hợp hiển nhiên như `tiéng => tiếng` (`ie,ye` chỉ có thể bỏ dấu `iê,yê`), `mưón => mướn`, chuẩn hoá `thuở => thủa` ...

* `syllable pasing` hỗ trợ nhiều bảng mã, nhiều kiểu viết tiếng Việt, có dấu và không dấu ...

* `syllables` có thể được trình bày lại dưới nhiều dạng khác nhau:
    - utf-8 `điếng`
    - dạng telex `đieengs`
    - dạng telex cải tiến `ddieng|zs`
    - dạng tách biệt âm đầu + vần + âm cuối + thanh điệu `_dd iez ng s`

* Thống kê đầu ra gồm `types + freqs` âm tiết tiếng Việt, các `tokens` được phân loại `alphamark, alph0m0t, nonalpha` để tiện tìm hiểu và phân tích thêm. Ví dụ các từ sai chính tả tiếng Việt thường rơi vào các `alphamark tokens` ...

* Thống kê `bi,tri, four-grams ...`
