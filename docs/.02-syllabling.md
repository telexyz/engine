# Vietnamese Syllable-based NLP & IR Tasks
/// Syllable(-ing): pronounce (a word or phrase) clearly, syllable by syllable.


## TODOs

* Huấn luyện mô hình ngôn ngữ lightweight RNN cho âm tiết tiếng Việt

* Xây dựng kiến trúc lattice tích hợp được nhiều features & methods

* Viết beam-search decoder cho kiến trúc nói trên

[ >>> HERE I SHOULD BE, DOWN THE RABBIT HOLE <<< ]

* Từ `data/{21,..28}-n_grams.txt` tìm cách load và hashing về `u64` xem có bị va chạm không?

* Từ `dict/25k.xyz.cdx` hoặc `dict/34k.xyz.cdx` chuyển thành 4-grams (chỉ giữ lại từ <= 4 âm tiết) và mapping vào TokenId u16 dựa trên alphabet hoặc tần suất sử dụng (match với thống kê n-grams). Khởi tạo từ điển là một mapping 2 chiều từ `u16 <=> u64`

* Dùng từ điển `u16 <=> u64` để sinh ra n-best khả năng nhóm syll2word

* Thử áp `src/syllabling/ripple_down_rules.zig` xem có gì thú vị không?

[ >>> DONE <<< ]


* Tham khảo kiến trúc tích hợp Jumanpp


Phần này tập trung khai thác tối đa âm tiết tiếng Việt, các từ không cấu thành bởi âm tiết tiếng dân tộc (dak lak), tiếng nước ngoài (ok), tiếng vay mượn (axít) tạm coi là OOV và sẽ được xử lý trong phần tiếp theo.


## Tại sao lại chỉ âm tiết tiếng Việt?

Vì đó là điểm khác biệt lớn nhất giữa tiếng Việt một ngôn ngữ đơn thể với tiếng Anh - ngôn ngữ giao thể. Xem:

* https://vi.wikipedia.org/wiki/Ngôn_ngữ_đơn_lập
* https://vi.wikipedia.org/wiki/Hình_vị

Các cách kỹ thuật xử lý hình vị tiếng Anh như stemming (trong IR), sub-word tokenizing (trong BERT language model) ... phần lớn sẽ không tương thích với tiếng Việt. Ngược lại các kỹ thuật xử lý hình vị tiếng Trung, Thái, Nhật, Hàn ... nhiều khả năng độ tương thích cao hơn. CHỈ TẬP TRUNG KHAI THÁC ÂM TIẾT TIẾNG VIỆT LÀ ĐỂ LÀM RÕ XEM KỸ THUẬT NÀO PHÙ HỢP.

Trong các ngôn ngữ trên, phân tích hình vị tiếng Nhật được làm chỉnh chu, có độ chính xác tới hơn 99% cho lĩnh vực cụ thể như tin tức chẳng hạn. Nhiều bộ công cụ mã nguồn mở, kèm theo báo cáo kỹ thuật được tối ưu hoá và phát triển có tính kế thừa: từ JUMAN, ChaSen, MeCab, KyTea, Jumanpp, Sudachi ... Sử dụng đa dạng kỹ thuật như từ điển (vocab matching), dựa trên luật (rule-based), pointwise, máy học, mô hình ngôn ngữ (n-gram, nn). 


## Nền tảng

Phần nền tảng chia sẻ chung một kiến trúc nền tảng coi text là chuỗi tín hiệu đầu vào (tokens), chuỗi đầu vào có thể bị lỗi (thiếu / thừa / sai thông tin), hệ thống sẽ căn cứ vào một baseline (thường là từ điển) để đoán xem điểm nào của chuỗi là bất thường (lỗi sai/thừa), điểm nào cần bổ xung thêm thông tin (lỗi thiếu). Với một điểm bất thường sẽ có một danh sách các ứng cử viên (candidates) để chữa điểm bất thường đó (ứng viên rỗng sẽ xoá điểm bất thường đó để sửa lỗi thừa thông tin). Tương tự với mỗi điểm cần bổ xung thông tin (tagging, NER, syntax parser ...) cũng có một danh sách ứng viên để lựa chọn. Bước cuối cùng là làm cách nào để chọn ra tập ứng viên tốt nhất cho toàn bộ chuỗi tín hiệu. Các bước thực hiện bao gồm:

__Bước 1__: Tìm điểm bất thường, và tìm điểm cẩn bổ xung thông tin. Cần cân bằng giữa số lượng điểm và  bỏ sót càng ít điểm nghi vấn càng tốt. Ví dụ: coi mọi token đều làm điểm nghi vấn thì sẽ không bỏ sót nhưng khiến số lượng tính toán / xử lý tăng lên rất nhiều.

__Bước 2__: Với mỗi điểm tìm được sinh ra danh sách ứng cử viên cân bằng giữa độ lớn danh sách và độ tốt của ứng cử viên. Ví dụ với mỗi token nghi sai chính tả, coi mọi từ có thể có trong từ điển là candiates sẽ không bỏ sót ứng cử viên tốt nhưng khiến số lượng tính toán tăng lên rất nhiều.

__Bước 3__: Di chuyển từ đầu tới cuối chuỗi tín hiệu thì với mỗi điểm nghi vấn, mỗi candiate được coi là một nhánh trong không gian giải pháp. Không gian giải pháp này có thể được thể hiện dưới dạng hình cây (tree / branch / leaves), hoặc hình lưới (lattice). Cách thể hiện không gian tìm kiếm (data structure) cần đủ mềm dẻo để tích hợp được nhiều thông tin chung quanh điểm nghi vấn và các ứng viên để hỗ trợ việc tìm ra một/nhiều giải pháp tốt nhất và khiến việc tìm kiếm trở nên hiệu quả hơn.

__Bước 4__: Tạo lập một hàm mục tiêu để trong không gian giải pháp đó, tìm ra được một/nhiều giải pháp tốt nhất. Bước này quy về bài toán tìm kiếm theo chiều rộng (beam search), theo chiều sâu (a-star search), hoặc xử lý từng điểm nghi vấn một cách độc lập (pointwise).

__Bước 5__: Sau khi có hàm mục tiêu và dữ liệu đã được gán nhãn có thể dùng máy học để huấn luyện các tham số của mô hình tạo dựng được ở bước 3 và 4.

__Bước 6__: Từ tham số mô hình (bước 3+5), cấu trúc không gian tìm kiếm (bước 3), hàm mục tiêu và chiến lược tìm kiếm được lựa chọn (bước 4) tìm ra một/nhiều giải pháp tốt nhất. Bước này thường được gọi là xây dựng bộ giải mã (decoder).

__Bước 7__: Từ một/nhiều giải pháp tốt nhất đó tự động sửa lỗi / bổ xung thông tin hoặc gợi ý sửa lỗi / bổ xung thông tin (bán tự động).

__Bước 8__: Quay lại bước 1, dùng dữ liệu được chữa để nâng cao độ chính xác của mô hình và lặp lại như thế cho tới khi toàn bộ corpus được xử lý sạch đẹp.

- - -


### Module 0/ n-gram nâng cao

* Làm mượt n-gram `data/2{n}_{n}-grams.txt`

* Tìm một thuật toán hashing để encode n-gram (n > 4) về u64 (hoặc nhỏ hơn) để tiết kiệm bộ nhớ khi đếm n-gram


### Module 1/ `syllables2words`: gộp âm tiết thành từ

* Step 1: Dùng từ điển liệt kê mọi khả năng tách từ, 
          scoring dựa trên syllable n-grams, giữ lại 5-best

* Step 2: Huấn luyện được bộ tách từ. Tham khảo `docs/tach_tu_Nhat.md`


### Module 2/ Tự động bỏ dấu và thanh tiếng Việt
(xem `docs/.them_dau_thanh.md`)


### Module 3/ Làm bộ chữa lỗi chính tả 
(xem `doc/.loi_chinh_ta.md`)
*  Sinh ra candidates từ edit-distances rồi áp dụng n-gram/nn + beam-search như thêm dấu+thanh
*  Tìm hiểu các phương pháp khác ...


### Module 4/ Tách các âm tiết dính liền nhau (thiếu dấu cách)
(xem `doc/.token_repairs.md`)


### Module 5/ Viết BPE để định danh OOV 
OVV gồm tiếng dân tộc thiểu số (như Đắk Lắk) và tiếng nước ngoài 

## Mở rộng

Phần mở rộng kế thừa các `modules` trong phần nền tảng để xây dựng công cụ có thể tìm kiếm và xem dữ liệu trong corpus thật nhanh, phát hiện các trường hợp bất thuòng, gợi ý sửa lỗi, gợi ý bỏ đi những đoạn text kém chất lượng ... để làm dữ liệu thật tốt cho các tác vụ nâng cao.

### Module a/ Làm search-engine dựa trên token_ids

Định đanh được tới đâu thì search được tới đó, làm xong `module 1/` thì sẽ có syllable_ids và word_ids, có n-best word_ids thì index hết n-best. Làm xong `module 5/` thì phải hỗ trợ  positional indexing thì mới search được word dựa trên sub-word tokens. Điều này cũng không ảnh hưởng tới perf  nhiều vì OOV chiếm khoảng 25% tổng tokens và chỉ cần làm positional indexing cho sub-word tokens thôi (khoảng 2.8k)

*  inverted index, compressed index, searching, scoring ...
*  chỉ index và search syllables (có gộp syllables thành words) cho nhỏ và nhanh
*  dùng n-gram/nn để auto suggest search terms
*  áp dụng bộ sửa lỗi chính tả lên input search terms


### Module b/ Làm word2vec

Cách tiếp cận hệt như search-engine: Định đanh được tới đâu thì search được tới đó, làm xong `module 1/` thì sẽ có syllable_ids và word_ids, có n-best word_ids thì vectorlize hết n-best.

Viết lại word2vec từ C sang Zig sẽ rất thú vị và hiểu thêm về NN. Làm tiền đề cho RNNLM.

Tìm hiểu https://github.com/zhezhaoa/ngram2vec để nhúng được nhiều phương án (n-best) vào trong không gian vector


### Module c/ Làm sent2vec

Để tìm câu gần giống nhau về ngữ nghĩa.