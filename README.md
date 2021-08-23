Telexyz nên theo hướng data-centric https://github.com/HazyResearch/data-centric-ai

## TODO

Xem `docs/_0{1,2,3}-xxxx.md`

## REWRITE

_Viết lại modules quan trọng từ C sang Zig để hiểu thuật toán và nhuần nhuyễn Zig_

* _BPE sub-word_ https://github.com/telexyz/tools/tree/master/vocab/fastBPE/fastBPE

BPE quan trọng trong việc chia nhỏ OOV và ánh xạ OOV về một tập tokens có số lượng định trước, nhờ đó kiểm soát tốt số lượng từ vựng, hợp với việc huấn luyện mô hình có tài nguyên hạn chế.

* _Word2Vec_ https://github.com/zhezhaoa/ngram2vec/blob/master/word2vec/word2vec.c

Một module quan trọng trong việc trình bày lại token dưới dạng vector trong không gian khoảng 300 chiều, quan trọng trong việc tìm kiếm token giống nhau, dùng để train NN/LM, re-raking, re-scoring ...

Luận văn tiến sĩ của Mikolov, tác giả word2vec, cô đọng, dễ hiểu
https://www.fit.vutbr.cz/~imikolov/rnnlm/thesis.pdf

- - -

[ GOAL ] PHÁT HIỆN, TRÌNH BÀY LẠI VÀ INDEX TOKENS SAO CHO CÓ THỂ XEM+XÉT CORPUS THẬT NHANH, LOẠI BỎ DỮ LIỆU TRÙNG LẶP, PHÁT HIỆN CÁC TRƯỜNG HỢP BẤT THUÒNG, TỰ ĐỘNG SỬA LỖI, BỎ ĐI NHỮNG ĐOẠN TEXT KÉM CHẤT LƯỢNG

Dưới góc nhìn quản trị dữ liệu còn rất nhiều việc thú vị để làm như là phát hiện và loại bỏ trùng lặp, indexing để tìm kiếm và so sánh nhanh các câu trong corpus, phát hiện sự thiếu, thừa, sai / không hoàn chỉnh ... của dữ liệu.

Nếu coi corpus là một file text lớn, mỗi câu được chứa trên một dòng, mỗi dòng khoảng 12.5 tokens, thì 10 triệu dòng chiếm khoảng 600MB. Mỗi file text lớn có file index (.idx) riêng đi kèm, tương tự như có file thông tin trích xuất như định danh / mã hoá (.cdx) riêng đi kèm.

Dùng `u32` để định danh thì sẽ chứa được gần 4.3 tỉ đầu mục, tương đương với 1 file text copus 2.1Tb. Dư lớn vì dữ liệu https://pile.eleuther.ai, dữ liệu mở tiếng Anh lớn nhất để huấn luyện mô hình ngôn ngữ siêu khủng mới chỉ ở mức 0.8Tb (800GB).

## Thành tựu chính

* Dùng âm vị học để phân tích và định danh nhanh mọi âm tiết TV viết thường thành 16-bits mà không cần dùng dữ liệu đối chiếu (lookup-table, trie, ...) để chuyển từ dạng text thành định danh cũng như từ định danh 16-bits khôi phục lại dạng text của âm tiết. (xem `src/syllable_data_struct.zig`). 

Số lượng âm tiết tiếng Việt viết thường lọc từ corpus rơi vào khoảng 12k. http://www.hieuthi.com/blog/2017/03/21/all-vietnamese-syllables.html chỉ ra rằng có khoảng 18k âm tiết như vậy, chứng tỏ có khoảng 6k (33%) âm tiết có thể đúng về mặt ghép âm nhưng không được hoặc rất ít khi được sử dụng. Với khoảng 18k âm tiết viết thường phải dùng 15-bits để định danh. Cách định danh nhanh dùng 16-bits nhưng chỉ dùng 28_750 slots, còn dư `39_286 slots` để làm việc khác như lưu từ điển TV và chứa OOV ... (Từ điển khoảng `33_668` => còn `5618` cho OOV. Xem `docs/syllable_n_token_ids.md`).

* Thống kê và liệt kê token types theo freqs và length, phân chia thành token trong bảng chữ cái có dấu + thanh `alphamark`, token trong bảng chữ cái không dấu thanh `alpha0m0t`, token không thuộc bảng chữ cái `nonalpha`, nhờ đó phát hiện nhanh token bất thường, token lỗi ... (xem https://github.com/telexyz/results#readme)

* Thử nghiệm với gần 1Gb text trộn từ Facebook comments, news titles, viet opensub, wikipedia, sách, truyện .. Trong vòng 45 giây phân tách được: 
```r
 73% tokens âm tiết tiếng Việt  148_280_481 "của và có không là được cho các"
  6% tokens thuộc bảng chữ cái   11_953_258 "đ đc NĐ ĐH TP USD inbox shop"
 21% tokens ngoài bảng chữ cái   43_576_527 ". , - : ? ; '' "" 1 ! 2 / ... 2020 🤣 19000019"
- - - - - - - - - - - - - - - - - - - - - -
100% tổng tokens                203_810_266
```
=> TRUNG BÌNH MỘT GIÂY PHÂN TÁCH VÀ PHÂN LOẠI 5 TRIỆU TOKENS, ĐỊNH DANH 3.65 TRIỆU ÂM TIẾT TV

- - -

[ BY PRODUCT 1 ] Thống kê từ vựng và n-gram cơ bản, sửa lỗi chính tả đơn giản dựa trên phân tích âm vị học ...

[ BY PRODUCT 2 ] Cải tiến bộ gõ Telex, dùng `az,ez,oz` thay `aa,ee,oo` để thống nhất với cách bỏ dấu như `aw,ow,uw`; chỉ bỏ dấu và thanh cuối âm tiết `nuoc|ws`

__Câu hỏi đặt ra:__

Yếu điểm có thể coi là lớn nhất của Telex là viết song ngữ rất chậm,
vì hay bị hiểu lầm thành dấu mũ. Việc chuyển bàn phím thì cũng rất mất thời gian !!!
Làm thế nào để giảm thiểu sự nhầm lẫn khi gõ tiếng Anh lẫn lộn với tiếng Việt ???
Viết hoàn toàn không dấu và để máy tự bỏ dấu với sự trợ giúp từ người dùng ???