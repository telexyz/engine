Viết lại thuật toán subword để xử lý OOV, không quá quan trọng việc tối ưu hay cân bằng số lượng subwords vì syllables mới là trọng tâm của tiếng Việt và đã được xử lý trọng vẹn.

Khi làm subwording cần lưu ý sử dụng lại các tri thức của syllables ví dụ như cấu trúc IMFT (Initial-Middle-Final+Tone). Hoặc thử tìm cách phiên âm từ nước ngoài thành các syllables để dùng syllable_id biểu diễn cho từ nước ngoài luôn chẳng hạn ...

* _BPE sub-word_ https://github.com/telexyz/tools/tree/master/vocab/fastBPE/fastBPE

BPE quan trọng trong việc chia nhỏ OOV và ánh xạ OOV về một tập tokens có số lượng định trước, nhờ đó kiểm soát tốt số lượng từ vựng, hợp với việc huấn luyện mô hình có tài nguyên hạn chế.
