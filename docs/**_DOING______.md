# Định hướng và tính ứng dụng

**Telexyz nên theo hướng data-centric https://github.com/HazyResearch/data-centric-ai**

**Làm tốt dần / mịn dần từng bước một, có sự tham gia của con người ...**

**Lặp đi lặp lại để tăng dần chất lượng**


## Trong khi xây dựng engine, thử nghiệm trên 2 mảng ứng dụng:

### 1/ Bộ gõ telex cải tiến để gõ song ngữ dễ dàng hơn

- Làm trên web + wasm để thi triển và trình diễn dễ dàng hơn

- Làm bộ gõ native, đa nền tảng => Tham khảo bộ gõ https://github.com/tuyenvm/OpenKey

* Bỏ dấu `ôêâ` bằng `z` để thống nhất với cách bỏ dấu `w` + giảm thiểu nhầm lẫn
* Bỏ dấu `wz` thanh `sfrxj` ở cuối âm tiết để giảm thiểu nhầm lẫn với từ tiếng Anh
* Dùng từ điển song ngữ để gợi ý transform cuối cùng của chuỗi ký tự được gõ nên là tiếng Việt hay nguyên bản
* Dùng n-gram cho pointwise để re-ranking candidates
* Kết hợp phát hiện, cảnh báo và gợi ý sửa lỗi chính tả

### 2/ Áp dụng vào: (sửa lỗi, phân đoạn,) tìm topics cho từng đoạn của 150 bài pháp

_NOTE_: Phần này ko cần `n-gram`, không cần `syllables2words` mà cần `dict_matching`, `word2vec` ...

* Nhóm âm tiết thành từ
* Loại bỏ stopwords
* Áp dụng Hierarchical Topic Mining via Joint Spherical Tree and Text Embedding (xem https://github.com/telexyz/embed)

- - -

# Các giai đoạn chiến lược để hoàn thiện engine

## stage-1: Tokenizer cho TV đã gần xong (còn OOV)

## stage-2: Syllabling là cách nói chơi chữ, có nghĩa là tổng hợp các âm tiết thành từ.

stage-2 đã lên được một KIẾN TRÚC NỀN TẢNG sử dụng chung cho nhiều modules.

__Note__: Có 2 cách xây dựng LM: n-gram là đơn giản nhất. Ngược lại, phức tạp với độ chính xác cao là DL cần phần cứng và mềm chuyên dụng.

=> Chốt sử dụng n-gram trước để impl và triển khai đơn giản + đủ dùng. NNLM có thể khám phá sau từ thấp tới cao như RNN < LSTM < Transformer ... (VD: Jumanpp sử dụng RNN để reranking cho kết quả khá tốt)

## stage-3: Deploy and optimize

Triển khải trên wasm trước, cần những mô hình đơn giản đủ hiệu quả và tối thiểu hóa data, MEM và CPU cho phiên bản web.

Phần này tập trung vào sự đơn giản của mô hình, nhất quán trong kỹ thuật triển khai (ví dụ n-gram count chỉ dùng FuseFilter chứ không dùng hash_count), ưu tiên vào việc tương tác với người dùng và sử dụng input từ người dùng (kể cả hỏi đáp, tự chọn từ những gợi ý ...) để nâng cao chất lượng bộ gõ ...