__NOTE__: Bộ nhớ wasm nhỏ, nền web, data to load xuống local khó trôi nên cần sử dụng những models có dung lượng nhỏ (vài MB) => n-gram không thích hợp. Các lựa chọn khác bao gồm:
* Rule-based
* Pointwise
* RNN

### Module 3a/ Triển khai bộ viet_tknz to wasm
* Gọi được hàm phân tích syllable từ js
* Áp dụng triệt để trong bộ gõ telex cải tiến để gõ song ngữ Anh-Việt

### Module 3b/ Dict matching
* Load từ điển đã được encoded bằng `4-syllable_ids` từ file ngoài trên server
* Dùng từ điển để làm `syllables2words`
* Dùng từ điển để gợi ý sửa lỗi chính tả
