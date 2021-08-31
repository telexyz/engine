## Sửa lỗi thiếu hoặc thừa dấu cách (tknz errors)

tknz errors có mặt trong 15% số lỗi chính tả Kukich (1992). Nói cách khác cứ 100 lỗi chính tả có 15 lỗi thiếu hoặc thừa dấu cách.

VD `Bươỉtàilộc => Bưởi tài lộc`

Bài toán hẹp tknz âm tiết tiếng Việt, và tknz errors chỉ là lỗi thiếu dấu cách, ta sẽ có một số căn cứ như sau để băt đầu:

* Biết rằng mọi âm tiết đều có nguyên âm làm hạt nhân, từ nguyên âm đó mở rộng trái phải sẽ có được âm tiết

* Một đoạn âm tiết dính nhau sẽ có nhiều cách gỡ, cách gỡ nào TỐT NHẤT cần có một hàm mục tiêu để xác định, ví dụ như mục tiêu so khớp nhiều nhất với từ điển, mục tiêu tối đa hoá xác suất với mô hình ngôn ngữ n-gram/nn ...

Điểm mạnh của từ điển là đơn giản, chạy nhanh, có thể bổ xung ... Điểm yếu của từ điển cứng nhắc, vừa thừa, vừa thiếu nếu không xét tới domain, không xét tới ngữ cảnh ...

Điểm mạnh của n-gram là xây dựng được từ chính tập dữ liệu đó, không cần định nghĩa trước ... Điểm yếu của n-gram là tốn bộ nhớ do độ rời rạc cao (vài Gb), ngữ cảnh hẹp ...

Điểm mạnh của NN là cover được ngữ cảnh rộng, mà không tốn nhiều bộ nhớ như n-gram (vài trăm MB) mà chứa được nhiều thông tin hơn n-gram. Điểm yêu của NN là tốn resource để training (phải có GPU hoặc phần cứng chuyên dụng)