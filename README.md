# Vietnamese Telex Input Method and Anything Related

[ GOAL ] RE-PRESENTING + INDEXING SAO CHO CÓ THỂ VIEW CORPUS THẬT NHANH, PHÁT HIỆN CÁC TRƯỜNG HỢP BẤT THUÒNG, TỰ ĐỘNG SỬA LỖI, BỎ ĐI NHỮNG ĐOẠN TEXT KÉM CHẤT LƯỢNG ...

[ BY PRODUCT 1 ] token repair, basic n-gram, phoneme based spelling error correction ...

[ BY PRODUCT 2 ] Cải tiến bộ gõ Telex, dùng z thay aa,ee,oo; chỉ bỏ dấu thanh cuối âm tiết

[ IMPORTANT ] Yếu điểm có thể coi là lớn nhất của Telex là viết song ngữ rất chậm,
vì hay bị hiểu lầm thành dấu mũ. Việc chuyển bàn phím thì cũng rất mất thời gian !!!

[ QUESTION ] Làm thế nào để giảm thiểu sự nhầm lẫn khi gõ tiếng Anh lẫn lộn với tiếng Việt ???

[ POSIBLE SOLUTION ] Viết hoàn toàn không dấu và để máy tự bỏ dấu với sự trợ giúp từ người dùng.


## TODOs

* Sử dụng stream input từ file để giảm thiểu áp lực lên bộ nhớ

[ >>> HERE I SHOULD BE, DOWN THE RABBIT HOLE <<< ]

* Tối ưu hoá tốc độ ghi ra bằng cách thêm length vào đầu type's value

* Ghi kèm invisible token's attrs char, base32 syllable_id ra file text output

[ >>> DONE <<< ]

* Tối ưu hoá tốc độ ghi ra bằng cách bỏ qua syllable_id khi đọc tokens_infos

* Viết thẳng tknz output ra file, bỏ qua bộ đệm để không phải khởi tạo nhiều bộ nhớ đệm

*  08/08/2021: Nén input vào bộ tự điển `alphabet_types` và `nonalpha_types` vừa giữ được đầu vào nguyên bản của `token` vừa đếm `types`. Dùng `trans_offset + alphabet_bytes/nonalpha_bypes` để tính ra `trans_ptr`. `trans` viết tắt của `transit` (dịch chuyển) hoặc `transform` (biến đổi), hoặc `translate` (dịch (ngôn ngữ))

* Sử dụng thuật toán heuristic dự đoán ký tự utf-8 nào thuộc bảng chữ cái tiếng Việt để segment văn bản thật nhanh thành `alphamark`, `alph0m0t`, `nonalpha`

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

* Thống kê `bi,tri và four-grams`