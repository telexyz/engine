# Bộ tách token và phân tích âm vị học âm tiết tiếng Việt và trình bày lại thành kiểu gõ Telex cải tiến

[ GOAL ] PHÁT HIỆN, TRÌNH BÀY LẠI VÀ INDEX TOKENS SAO CHO CÓ THỂ XEM+XÉT CORPUS THẬT NHANH, PHÁT HIỆN CÁC TRƯỜNG HỢP BẤT THUÒNG, TỰ ĐỘNG SỬA LỖI, BỎ ĐI NHỮNG ĐOẠN TEXT KÉM CHẤT LƯỢNG


## Thành tựu chính

* Tối ưu hoá việc nhận dạng ký tự đặc trưng tiếng Việt (kí tự có dấu + thanh): khi mã hoá bằng utf-8, dùng tới 2-3 bytes để lưu trữ rồi phải chuyển đổi thành `u21` mới trở thành dạng mã hoá cuối cùng của một ký tự utf-8. Tìm cách không phải chuyển đổi mà dùng trực tiếp giá trị của 1 hoặc 2 byte đầu tiên để tra xét nhanh. Trình bày lại một dạng ký tự tiếng Việt bằng `u10` đã tách thanh điệu, đánh dấu viết hoa vs viết thường để tối ưu việc phân tích âm vị (xem `src/telex_utils.zig`). Xử lý cả mã unicode tổ hợp lẫn cách viết telex ...

* Dùng âm vị học để phân tích và định danh nhanh mọi âm tiết TV viết thường thành 16-bits mà không cần dùng dữ liệu đối chiếu (lookup-table, trie, ...) để chuyển từ dạng text thành định danh cũng như từ định danh 16-bits khôi phục lại dạng text của âm tiết. (xem `src/syllable_data_struct.zig`)

* Dùng 16-bits đủ để định danh token types. Số lượng âm tiết tiếng Việt viết thường rơi vào khoảng 12k. Như vậy ít nhất phải dùng 14-bits để định danh. Cách định danh nhanh trên dùng 16-bits nhưng chỉ dùng 28_750 slots, còn dư 36_786 để làm việc khác như lưu từ điển TV và chứa OOV ... (xem `docs/16-bits_syllable_encoding.md`)

* Thống kê và liệt kê token types theo freqs và length, phân chia thành token trong bảng chữ cái có dấu + thanh `alphamark`, token trong bảng chữ cái không dấu thanh `alpha0m0t`, token không thuộc bảng chữ cái `nonalpha`, nhờ đó phát hiện nhanh token bất thường, token lỗi ... (xem https://github.com/telexyz/results#readme)

- - -

[ BY PRODUCT 1 ] Thống kê từ vựng và n-gram cơ bản, sửa lỗi chính tả đơn giản dựa trên phân tích âm vị học ...

[ BY PRODUCT 2 ] Cải tiến bộ gõ Telex, dùng `az,ez,oz` thay `aa,ee,oo` để thống nhất với cách bỏ dấu như `aw,ow,uw`; chỉ bỏ dấu và thanh cuối âm tiết `nuoc|ws`

Yếu điểm có thể coi là lớn nhất của Telex là viết song ngữ rất chậm,
vì hay bị hiểu lầm thành dấu mũ. Việc chuyển bàn phím thì cũng rất mất thời gian !!!
Làm thế nào để giảm thiểu sự nhầm lẫn khi gõ tiếng Anh lẫn lộn với tiếng Việt ???
Viết hoàn toàn không dấu và để máy tự bỏ dấu với sự trợ giúp từ người dùng ???


## Viết lại modules quan trọng từ C sang Zig để hiểu thuật toán và nhuần nhuyễn Zig

* _BPE sub-word_ https://github.com/telexyz/tools/tree/master/vocab/fastBPE/fastBPE

BPE quan trọng trong việc chia nhỏ OOV và ánh xạ OOV về một tập tokens có số lượng định trước, nhờ đó kiểm soát tốt số lượng từ vựng, hợp với việc huấn luyện mô hình có tài nguyên hạn chế.

* _Word2Vec_ https://github.com/zhezhaoa/ngram2vec/blob/master/word2vec/word2vec.c

Một module quan trọng trong việc trình bày lại token dưới dạng vector trong không gian khoảng 300 chiều, quan trọng trong việc tìm kiếm token giống nhau, dùng để train rnnlm, dùng trong re-raking, re-scoring ...

Luận văn tiến sĩ của Mikolov, tác giả word2vec, cô đọng, dễ hiểu rất đáng để đọc
https://www.fit.vutbr.cz/~imikolov/rnnlm/thesis.pdf

## TODOs

[ >>> HERE I SHOULD BE, DOWN THE RABBIT HOLE <<< ]

* Kiểm tra tính đúng đắn của syllable_id

[ >>> DONE <<< ]

- - -

* 18/08/2012: Dùng base64 để ghi syllable_ids, ghi token's attrs và syllable_ids ở 1 dòng riêng

* Tối ưu hoá tốc độ ghi ra bằng cách thêm length vào đầu type's value, bỏ qua line có too long token

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

* Thống kê `bi,tri, four-grams ...`