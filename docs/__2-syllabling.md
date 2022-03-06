# Bộ tổng hợp âm tiết thành từ `syllables2words`

## Module 2c/ Tự động bỏ dấu và thanh tiếng Việt
(xem `docs/_them_dau_thanh.md`)

## Module 2b/ `syllables2words`: gộp âm tiết thành từ

### 2b.3 Thử áp `src/syllabling/ripple_down_rules.zig` xem có gì thú vị không?

### 2b.2 Huấn luyện được bộ tách từ. Tham khảo `docs/tach_tu_Nhat.md`

### 2b.1 Naive Impl

* Scoring dựa trên syllable n-grams, giữ lại 5-best

* Beam-search để chọn +10 khả năng tách từ mà ít âm tiết `mồ côi` nhất

* Dùng từ điển liệt kê mọi khả năng tách từ

* Từ `dict/34k.xyz` và hàm `parseXyzToGetSyllable()` chuyển thành 4-grams (từ <= 4 âm tiết) và định danh bằng phần còn lại của `u16` (sau khi đã trừ đi syllable ids và OOV BPE).  Khởi tạo từ điển giống như hash_count của n-gram nhưng đơn giản hơn vì chỉ cần chứa 32k items (2^15). Có lẽ chỉ cần `u24 hash` để map vào `2^16 slots`, mỗi slot chứa `u16` word id.

## Module 2a/ n-gram tinh gọn

[ >>> HERE I SHOULD BE, DOWN THE RABBIT HOLE <<< ]

* Cho 1 phrase (nhiều syllables), tính xác xuất dựa trên n-gram count

* `counting/language_model.zig` bản tinh gọn can load 18 filters from files

[ >>> DONE <<< ]

* Tìm một cách đơn giản để làm mượt n-grams (xem `docs/n-gram_smoothing.md`)

* Tìm cách tối ưu nhất, ít bộ nhớ nhất để load n-gram (xem `counting/language_model.zig`)

* Từ `data/{21,..28}-n_grams.txt` tìm cách load và hashing về `u64` xem có bị va chạm không?

* Tìm cách đếm, lưu n-gram (bao gồm từ điển) hiệu quả nhất `docs/n-gram_lookup_IFM_trie.md`

* Tham khảo kiến trúc tích hợp Jumanpp

- - -

# Syllable-based NLP & IR Tasks
/// Syllable(-ing): pronounce (a word or phrase) clearly, syllable by syllable.

Phần này tập trung khai thác tối đa âm tiết tiếng Việt, các từ không cấu thành bởi âm tiết tiếng dân tộc (dak lak), tiếng nước ngoài (ok), tiếng vay mượn (axít) tạm coi là OOV và sẽ được xử lý trong phần tiếp theo.


## Tại sao lại chỉ âm tiết tiếng Việt?

Vì đó là điểm khác biệt lớn nhất giữa tiếng Việt một ngôn ngữ đơn thể với tiếng Anh - ngôn ngữ giao thể. Xem:

* https://vi.wikipedia.org/wiki/Ngôn_ngữ_đơn_lập
* https://vi.wikipedia.org/wiki/Hình_vị

Các cách kỹ thuật xử lý hình vị tiếng Anh như stemming (trong IR), sub-word tokenizing (trong BERT language model) ... phần lớn sẽ không tương thích với tiếng Việt. Ngược lại các kỹ thuật xử lý hình vị tiếng Trung, Thái, Nhật, Hàn ... nhiều khả năng độ tương thích cao hơn. CHỈ TẬP TRUNG KHAI THÁC ÂM TIẾT TIẾNG VIỆT LÀ ĐỂ LÀM RÕ XEM KỸ THUẬT NÀO PHÙ HỢP.

Trong các ngôn ngữ trên, phân tích hình vị tiếng Nhật được làm chỉnh chu, có độ chính xác tới hơn 99% cho 1 lĩnh vực cụ thể như tin tức chẳng hạn. Nhiều bộ công cụ mã nguồn mở, kèm theo báo cáo kỹ thuật được tối ưu hoá và phát triển có tính kế thừa: từ JUMAN, ChaSen, MeCab, KyTea, Jumanpp, Sudachi ... Sử dụng đa dạng kỹ thuật như từ điển (vocab matching), dựa trên luật (rule-based), pointwise, máy học, mô hình ngôn ngữ (n-gram, nn). 


## Nền tảng

Sử dụng chung một kiến trúc nền tảng như sau: coi text là chuỗi tín hiệu đầu vào (tokens), chuỗi đầu vào có thể bị lỗi (thiếu / thừa / sai thông tin), hệ thống sẽ căn cứ vào một baseline (thường là từ điển) để đoán xem điểm nào của chuỗi là bất thường ((nghi có lỗi sai/thiếu/thừa). Với một điểm bất thường sẽ có một danh sách các ứng cử viên (candidates) để chữa điểm bất thường đó; ứng viên rỗng sẽ xoá điểm bất thường đó (lỗi thừa tt). Bước cuối cùng là làm cách nào để chọn ra tập ứng viên tốt nhất cho toàn bộ chuỗi tín hiệu và giúp người dùng lựa chọn được ứng viên cuối cùng một cách hiệu quả nhất. Các bước thực hiện bao gồm:

__Bước 1__: Tìm điểm bất thường (nghi có lỗi sai/thiếu/thừa). Cần cân bằng giữa số lượng điểm và bỏ sót càng ít điểm nghi vấn càng tốt. Ví dụ: coi mọi token đều làm điểm nghi vấn thì sẽ không bỏ sót nhưng khiến số lượng tính toán / xử lý tăng lên rất nhiều.

__Bước 2__: Với mỗi điểm tìm được sinh ra danh sách ứng cử viên cân bằng giữa độ lớn danh sách và độ tốt của ứng cử viên. Ví dụ với mỗi token nghi sai chính tả, coi mọi từ có thể có trong từ điển là candiates sẽ không bỏ sót ứng cử viên tốt nhưng khiến số lượng tính toán tăng lên rất nhiều.

__Bước 3__: Di chuyển từ đầu tới cuối chuỗi tín hiệu thì với mỗi điểm nghi vấn, mỗi candiate được coi là một nhánh trong không gian giải pháp. Không gian giải pháp này có thể được thể hiện dưới dạng hình cây (tree / branch / leaves), hoặc hình lưới (lattice). Cách thể hiện không gian tìm kiếm (data structure) cần đủ mềm dẻo để tích hợp được nhiều thông tin chung quanh điểm nghi vấn và các ứng viên để hỗ trợ việc tìm ra một/nhiều giải pháp tốt nhất và khiến việc tìm kiếm trở nên hiệu quả hơn.

__Bước 4__: Tạo lập một hàm mục tiêu để trong không gian giải pháp đó, tìm ra được một/nhiều giải pháp tốt nhất. Bước này quy về bài toán tìm kiếm theo chiều rộng (`beam search`), theo chiều sâu (`a-star search`), hoặc xử lý từng điểm nghi vấn một cách độc lập (`pointwise`).

__Bước 5__: Sau khi có hàm mục tiêu và dữ liệu đã được gán nhãn có thể dùng máy học để huấn luyện các tham số của mô hình tạo dựng được ở bước 3 và 4.

__Bước 6__: Từ tham số mô hình (bước 3+5), cấu trúc không gian tìm kiếm (bước 3), hàm mục tiêu và chiến lược tìm kiếm được lựa chọn (bước 4) tìm ra một/nhiều giải pháp tốt nhất. Bước này thường được gọi là xây dựng bộ giải mã (decoder).

__Bước 7__: Từ một/nhiều giải pháp tốt nhất đó tự động sửa lỗi / bổ xung thông tin hoặc gợi ý sửa lỗi / bổ xung thông tin (bán tự động).

__Bước 8__: Quay lại bước 1, dùng dữ liệu được chữa để nâng cao độ chính xác của mô hình và lặp lại như thế cho tới khi toàn bộ corpus được xử lý sạch đẹp.
