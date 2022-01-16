# Định hướng và tính ứng dụng

**Telexyz nên theo hướng data-centric https://github.com/HazyResearch/data-centric-ai**

**Làm tốt dần / mịn dần từng bước một, có sự tham gia của con người ...**

**Lặp đi lặp lại theo hình xoán ốc đi lên.**


## Trong khi xây dựng engine, thử nghiệm trên 2 mảng ứng dụng:

### 1/ Bộ gõ telex cải tiến để gõ song ngữ dễ dàng hơn

Làm bộ gõ native, đa nền tảng => Tham khảo bộ gõ https://github.com/tuyenvm/OpenKey

* Bỏ dấu `ôêâ` bằng `z` để thống nhất với cách bỏ dấu `w` + giảm thiểu nhầm lẫn
* Bỏ dấu `wz` thanh `sfrxj` ở cuối âm tiết để giảm thiểu nhầm lẫn với từ tiếng Anh
* Dùng từ điển song ngữ để gợi ý transform cuối cùng của chuỗi ký tự được gõ nên là tiếng Việt hay nguyên bản
* Dùng n-gram cho pointwise để re-ranking candidates
* Kết hợp phát hiện, cảnh báo và gợi ý sửa lỗi chính tả

### 2/ Áp dụng vào: (sửa lỗi, phân đoạn,) tìm topics cho từng đoạn của 150 bài pháp

_NOTE_: Phần này ko cần `n-gram`, không cần `syllables2words` mà cần `dict_matching`, `word2vec` ...

* Nhóm âm tiết thành từ
* Loại bỏ stopwords
* Áp dụng Hierarchical Topic Mining via Joint Spherical Tree and Text Embedding

- - -

# Các giai đoạn chiến lược để hoàn thiện engine

## stage-1: Tokenizer cho TV đã gần xong (còn OOV)

## stage-2: Syllabling là cách nói chơi chữ, có nghĩa là tổng hợp các âm tiết thành từ.

stage-2 đã lên được một KIẾN TRÚC NỀN TẢNG sử dụng chung cho nhiều modules.

__Note__: Có 2 cách xây dựng LM: n-gram là đơn giản nhất. Ngược lại, phức tạp với độ chính xác cao là DL cần phần cứng và mềm chuyên dụng.

=> Chốt sử dụng n-gram trước để impl và triển khai đơn giản + đủ dùng. NNLM có thể khám phá sau từ thấp tới cao như RNN < LSTM < Transformer ... (VD: Jumanpp sử dụng RNN để reranking cho kết quả khá tốt)

# YOU SHOULD REWRITE

_Viết lại modules quan trọng từ C sang Zig để hiểu thuật toán và nhuần nhuyễn Zig_

* _BPE sub-word_ https://github.com/telexyz/tools/tree/master/vocab/fastBPE/fastBPE

BPE quan trọng trong việc chia nhỏ OOV và ánh xạ OOV về một tập tokens có số lượng định trước, nhờ đó kiểm soát tốt số lượng từ vựng, hợp với việc huấn luyện mô hình có tài nguyên hạn chế.

* _Word2Vec_ https://github.com/zhezhaoa/ngram2vec/blob/master/word2vec/word2vec.c

Một module quan trọng trong việc trình bày lại token dưới dạng vector trong không gian khoảng 300 chiều, quan trọng trong việc tìm kiếm token giống nhau, dùng để train NN/LM, re-ranking, re-scoring ...

https://aegis4048.github.io/optimize_computational_efficiency_of_skip-gram_with_negative_sampling