# Định hướng và tính ứng dụng

**Telexyz nên theo hướng data-centric https://github.com/HazyResearch/data-centric-ai**

**Làm tốt dần / mịn dần từng bước một, có sự tham gia của con người ...**

**Lặp đi lặp lại để tăng dần chất lượng**

- - -

# Các giai đoạn để hoàn thiện engine

## stage-1: Tokenizer cho TV đã gần xong (còn OOV)

## stage-2: Syllabling (cách nói chơi chữ) có nghĩa là tổng hợp các âm tiết thành từ.

stage-2 đã lên được một kiến trúc có thể sử dụng chung cho nhiều modules.

__Note__: Có 2 cách xây dựng LM: n-gram là đơn giản nhất. Ngược lại, phức tạp với độ chính xác cao là Deep Learning cần phần cứng và mềm chuyên dụng.

=> Sử dụng n-gram trước để impl và triển khai đơn giản + đủ dùng (baseline). Tiếp theo khám phá NNLM từ thấp tới cao như RNN < LSTM < Transformer 

## stage-3: Deploy and optimize

Triển khải trên wasm trước, cần những mô hình đơn giản đủ hiệu quả và tối thiểu hóa data, MEM và CPU cho phiên bản web.

Phần này tập trung vào sự đơn giản của mô hình, nhất quán trong kỹ thuật triển khai (ví dụ n-gram count chỉ dùng FuseFilter chứ không dùng hash_count), ưu tiên vào việc tương tác với người dùng và sử dụng input từ người dùng (kể cả hỏi đáp, tự chọn từ những gợi ý ...) để nâng cao chất lượng bộ gõ ...