# stage-3

Phần này kế thừa các `modules` trong phần nền tảng ở stage-2 để xây dựng công cụ có thể tìm kiếm và xem dữ liệu trong corpus thật nhanh, phát hiện các trường hợp bất thường, gợi ý sửa lỗi, gợi ý bỏ đi những đoạn text kém chất lượng ... để làm dữ liệu thật tốt cho các tác vụ nâng cao.

## Module 3a/ Làm search-engine dựa trên token_ids
Xem `docs/*indexing.md`

Định đanh được tới đâu thì search được tới đó, làm xong `module 2b/` thì sẽ có `syllable_ids` và `word_ids`, có `n-best word_ids` thì index hết `n-best`. Làm xong `module 2f/` thì phải hỗ trợ  `positional indexing` thì mới search được word dựa trên sub-word tokens. Điều này cũng không ảnh hưởng tới perf nhiều vì OOV chiếm khoảng 25% tổng tokens và chỉ cần làm `positional indexing` cho `sub-word tokens` thôi (khoảng 2.8k)

*  inverted index, compressed index, searching, scoring ...
*  chỉ index và search syllables (có gộp syllables thành words) cho nhỏ và nhanh
*  dùng n-gram/nn để auto suggest search terms
*  áp dụng bộ sửa lỗi chính tả lên input search terms

## Module 3b/ Kiểm soát chất lượng corpus

### 3b.1/ Loại bỏ trùng lặp
* Loại bỏ nhanh những câu trùng lặp nhau (fb comments lặp nhiều)
  Xem `_similar_detect.md`

* Giảm dung lượng corpus, tránh bias

### 3b.2/ Phát hiện token bất thường và gợi ý sửa lỗi

* Dùng từ điển tiếng Việt + Anh

* Phát hiện token bất thường
  - Nếu là từ đúng thì bổ xung vào từ điển người dùng
  - Nếu là lỗi chính tả thì gợi ý sửa lỗi chính tả
  - Nếu là lỗi ngữ pháp thì gợi ý sửa lỗi ngữ pháp
  - ...

## Module 3c/ Zoom-in, zoom-out copus cực nhanh

Tích hợp thêm các UI hoặc commandline tools để quản trị data and meta-data trong copus