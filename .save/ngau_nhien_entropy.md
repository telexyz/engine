Video giới thiệu dễ hiểu
https://www.youtube.com/watch?v=_PG-jJKB_do

https://www.youtube.com/watch?v=T6CxT4AESCQ

# Entropy nghĩa là gì?
https://forum.machinelearningcoban.com/t/hieu-ve-entropy/4443

Ý tưởng về Entropy ban đầu khá khó hiểu, có khá nhiều từ được dùng để mô tả nó: đó là sự hỗn loạn, không chắc chắc, độ bất định, độ bất ngờ, lượng thông tin hay những từ tương tự thế.

Năm 1948, Claude Shannon lần đầu nhắc tới khái niệm information entropy. Ông đã tìm cách để truyền tin hiệu quả mà không bị mất mát thông tin. Shannon đo lường độ hiểu quả dựa trên độ dài trung bình của 1 message. Bởi vậy, ông đã nghĩ tới việc mã hóa message vào cấu trúc dữ liệu nhỏ nhất có thể trước khi được gửi đi. Đồng thời, việc mã hóa đó không được phép làm mất, sai lệch thông tin nơi nhận. Bộ giải mã nơi nhận phải có khả năng khôi phục lại thông tin giống như thông tin gốc.

Shannon đã định nghĩa Entropy là kích cỡ (có thể hiểu là số bit) trung bình nhỏ nhất có thể để mã hóa mà không làm mất mát thông tin. Ông đã mô tả cách để tính entropy - rất hữu ích trong việc tính toán hiệu quả của kênh truyền dữ liệu.

### Cách mã hóa hiệu quả và không mất thông tin
...

### Cách để tính kích cỡ mã hóa trung bình (average encoding size)
...

# Tính chất của Entropy

Entropy cao đồng nghĩa với việc có rất nhiều loại thông tin với xác suất mỗi loại nhỏ. Mỗi 1 message mới xuất hiện, khả năng cao rằng message đó có nội dung khác với nội dung của message trước đó. Ta có thể gọi đó là sự bất định. Khi một loại thông tin với xác suất thấp bỗng nhiên xuất hiện, nó sẽ gây ra bất ngờ hơn so với các loại thông tin có xác suất cao khác. VD: với việc bạn chọn liều 1 trong 5 đáp án, xác suất xuất hiện là 80% sai, 20% đúng, việc bạn chọn đúng sẽ khiến bạn bất ngờ hơn nhiều so với việc chọn sai. Hay nói các khác, thông tin có xác suất càng thấp càng mang nhiều thông tin giá trị.

Hoặc 1 ví dụ khác, nếu phân phối là 90% mưa, 10% nắng thì thông tin dự báo thời tiết về 1 trận mưa sẽ không cung cấp nhiều thông tin (vì ta xác định sẵn tinh thần là trời sẽ mưa). Trong khí đó nếu phân phối là 50% mưa, 50% nắng thì thông tin về việc trời ngày hôm đó mưa hay nắng lại rất giá trị (chứa nhiều thông tin hơn).

Túm lại ta có thể hiểu entropy với các ý nghĩa sau:

* Entropy là lượng bit trung bình tối thiểu để mã hóa thông tin khi ta biết phân bố các loại thông tin trong đó.

* Entropy biểu thị cho sự hỗn độn, độ bất định, độ phức tạp của thông tin.

* Thông tin càng phức tạp càng entropy càng cao (hay công sức mã hóa lớn).

* Entropy là nền tảng trong việc công thức cross-entropy đo lường sai khác giữa các phân bố xác suất.

* Entropy nhạy cảm với thay đổi xác suất nhỏ, khi 2 phân bố càng giống nhau thì entropy càng giống nhau và ngược lại

* Entropy thấp đồng nghĩa với việc hầu hết các lần nhận thông tin, ta có thể dự đoán dễ hơn, ít bất ngờ hơn, ít bất ổn hơn và ít thông tin hơn.

https://naokishibuya.medium.com/demystifying-cross-entropy-e80e3ad54a8

What is it? Is there any relation to the entropy concept? Why is it used for classification loss? What about the binary cross-entropy?

Some of us might have used the cross-entropy for calculating classification losses and wondered why we use the natural logarithm. Some might have seen the binary cross-entropy and wondered whether it is fundamentally different from the cross-entropy or not. If so, reading this article should help to demystify those questions.

The word “cross-entropy” has “cross” and “entropy” in it, and it helps to understand the “entropy” part to understand the “cross” part.

!!! THIS VIDEO TELL IT ALL !!!
https://www.youtube.com/watch?v=ErfnhcEV1O8