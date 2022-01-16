__NOTE__: Bộ nhớ wasm nhỏ, nền web, data to load xuống local khó trôi nên cần sử dụng những models có dung lượng nhỏ (vài MB) => n-gram không thích hợp. Các lựa chọn khác bao gồm:

* Pattern matching
* Rule-based
* Pointwise
* NN


## Module 3a/ Làm giao diện web để có đất thử nghiệm bộ gõ
* Sử dụng `simple.css`
* Tách phần code từ `stp/e` ra để có ngay một bộ gõ đơn giản, có các tính năng nâng cao ở dạng prototye và cải tiến từ đấy


## Module 3b/ Triển khai bộ viet_tknz to wasm
* Gọi được hàm phân tích syllable từ js
* Áp dụng triệt để trong bộ gõ telex cải tiến để gõ song ngữ Anh-Việt
* Ghi nhớ các gõ của người dùng, lập thành pattern database để cải tiến cách gõ


## Module 3c/ Dict matching
* Load từ điển đã được encoded bằng `4-syllable_ids` từ file ngoài trên server
* Dùng từ điển để làm `syllables2words`
* Dùng từ điển để gợi ý sửa lỗi chính tả
* Phân tích nhanh văn bản để hiểu được patterns người dùng thường gõ là gì

### 3c.1: Dữ liệu từ điển âm tiết tiếng Việt

[1] Thống kê từ điển thấy rằng từ tiếng Việt bao gồm: 
* 16% một âm tiết
* 71% hai âm tiết
* 13% là 3+ âm tiết
Nếu bỏ từ một âm tiết, thì số lượng 3+ âm tiết chiếm khoảng 15% (13 / 84)

[2] Thống kê file `data/VnVocab.txt`
								  TOTAL `154KB`
* 28_522 từ 2 âm tiết = 28k * 4-bytes = `112kb`
*  2_320 từ 3 âm tiết =  3k * 6-bytes = ` 18kb`
*  2_831 từ 4 âm tiết =  3k * 8-bytes = ` 24kb`
*    424   +5 âm tiết (phần lớn là thành ngữ, có thể tách nhỏ)
Số lượng 3+ âm tiết chiếm 15.1% (5.1k / 33.6k)

[3] Thống kê file [`data/wordlist.txt`](https://github.com/binhvq/vietdict106k)
								  TOTAL `426KB` (file gốc 1.4MB)
* 64_220 từ 2 âm tiết = 64k * 4-bytes = `256kb`
* 14_786 từ 3 âm tiết = 15k * 6-bytes = ` 90kb`
* 10_258 từ 4 âm tiết = 10k * 8-bytes = ` 80kb`
*  3_555   +5 âm tiết
Số lượng 3+ âm tiết chiếm 27.7% (25k / 90k)


## Module 3d/ Sửa lỗi chính tả, lỗi cú pháp dùng rule-based
