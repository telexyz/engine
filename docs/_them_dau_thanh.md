## Cách 1: Sử dụng 2,3,4...-syllgrams để scoring

Từ âm tiết không dấu, sinh ta các trường hợp âm tiết có dấu (maximum 18 trường hợp)
an => an,án...ạn, ân,ấn...ận, ăn,ắn..ặn

Xây dựng mạng lưới search forward liên kết các trường hợp âm tiết có dấu có thể có
Dùng viterbi search để tìm best n-candiates

Cho người dùng chọn trong best n-candidates đó.


## Cách 2: Huấn luyện kiểu sequence tagging (CRF, SVM / pointwise ...)

Với tags là tổ hợp dấu (3) + thanh (6) (tổng 18 tags)

- - -

http://viet.jnlp.org/nghien-cuu-cua-tac-gia/bai-toan-them-dau-cho-tieng-viet

* Hơn 95% từ tiếng Việt có chứa dấu. Trong khi ở tiếng Pháp là 15%, tiếng Romanian là 35%. 

* Hơn 80% âm tiết mất dấu bị trùng lặp và không rõ ràng (ví dụ "cho" có thể hiểu là "chó", "chợ", ... âm tiết rõ ràng ví dụ như "nghieng" chỉ có 1 cách thêm dấu là "nghiêng"). Trong tiếng Pháp là 50%, và tiếng Romanian là 25%

* Với 1 âm tiết hay 1 từ, sẽ có 1 số cách nhất định để thêm dấu. Tỉ lệ trung bình về số cách thêm dấu của các từ trong tiếng Pháp và tiếng Romanian là khoảng 1.2, trong khi tiếng Việt là >2

* Ngoài ra, tiếng Việt còn không có dấu phân tách từ. 
  
Với đặc điểm tiếng Việt như thế, chúng tôi đề xuất một phương pháp mới nhằm giải quyết vấn đề này. Phương pháp này tiến hành thêm dấu ở từng âm tiết một cách độc lập. Bản chất của phương pháp này là chuyển bài toán thêm dấu về bài toán gán nhãn chuỗi và sử dụng máy học để thêm dấu. Độ chính xác của phương pháp này lên đến 94.7%. 

https://ongxuanhong.wordpress.com/2016/09/02/gan-nhan-tu-loai-part-of-speech-tagging-pos