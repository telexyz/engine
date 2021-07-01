## Making text a first-class citizen in TensorFlow
https://github.com/tensorflow/text

## Delete-only spellchecker https://github.com/wolfgarbe/SymSpell
https://wolfgarbe.medium.com/1000x-faster-spelling-correction-algorithm-2012-8701fcd87a5f

Tries have a comparable search performance to our approach. But a Trie is a prefix tree, which requires a common prefix. This makes it suitable for autocomplete or search suggestions, but not applicable for spell checking. If your typing error is e.g. in the first letter, than you have no common prefix, hence the Trie will not work for spelling correction.

If you need a very fast auto-complete then try my Pruning Radix Trie.
https://github.com/wolfgarbe/PruningRadixTrie

https://towardsdatascience.com/the-pruning-radix-trie-a-radix-trie-on-steroids-412807f77abc

- - -

## https://github.com/huggingface/tokenizers
💥 Fast State-of-the-Art Tokenizers optimized for Research and Production
```sh
pip3 install tokenizers
python3 huggingface_tknz_train.py
python3
# =>
from tokenizers import Tokenizer
tokenizer = Tokenizer.from_file("models/hf_tknz/telexified-bpe.json")
encoded = tokenizer.encode("khoong cos gi quys hown ddoocj laapjtuwj do")
encoded.tokens
encoded.ids
```
https://github.com/huggingface/tokenizers/tree/master/bindings/python#build-your-own

- - - 

http://www.phontron.com/kytea | https://github.com/neubig/kytea

KyTea employ Pointwise, provide Japanese and Chinese models for performing word segmentation, pronunciation estimation, and POS tagging (Japanese only), and can be trained to perform other tasks if you have data. The most interesting technical point of KyTea is that it can be trained from partially annotated data, which means that you only have to annotate the important or difficult parts of sentences, instead of whole sentences like traditional methods.

http://www.phontron.com/paper/neubig11aclshort.pdf
Pointwise Prediction for Robust, Adaptable Japanese Morphological Analysis

- - -

DongDu 1.0 (release 03/10/2012)  http://viet.jnlp.org/dongdu

https://filedn.com/lit4DCIlHwxfS1gj9zcYuDJ/SNOW/DongDu-src.zip
https://filedn.com/lit4DCIlHwxfS1gj9zcYuDJ/SNOW/DongDu-code.pdf


Trong tiếng Việt, dấu cách không mang ý nghĩa phân tách các từ mà chỉ mang ý nghĩa phân tách các âm tiết với nhau. có khá nhiều các ngôn ngữ khác cũng gặp phải bài toán này, ví dụ như : tiếng Nhật, tiếng Trung, tiêng Hàn, … Mỗi một ngôn ngữ có 1 đặc điểm cú pháp khác nhau, nhưng nhìn chung, hướng tiếp cận chủ đạo ở tất cả các ngôn ngữ này là sử dụng máy học.

Pointwise là phương pháp mới được nghiên cứu gần đây. Phương pháp này đang được ứng dụng rộng rãi trong tiếng Nhật và tiếng Trung và thu được những kết quả rất tốt. Ngoài ra, nó còn ứng dụng tốt cho nhiều vấn đề khác nhau trong xử lý ngôn ngữ tự nhiên. Trong tiếng Việt, phương pháp này được ứng dụng trong bài toán thêm dấu cho tiếng Việt không dấu và thu được kết quả khá tốt ( gần 95%).

Trong phương pháp pointwise, các nhãn sẽ được đánh giá một cách độc lập, và không tham khảo kết quả của các nhãn trước đó. Chính vì việc đánh giá độc lập như thế, mà phương pháp pointwise chỉ cần 1 từ điển vừa phải, và khá hiệu quả khi xác định những từ mới không có trong từ điển. Vì thế, phương pháp pointwise rất phù hợp với những ngôn ngữ không có nhiều dữ liệu như tiếng Việt.

Ngoài ra, vì các vị trí được đánh giá độc lập, các đặc trưng chỉ là thông tin văn bản xung quanh vị trí đó, nên pointwise có thể thực hiện được trên những dữ liệu không đầy đủ.

Phương pháp thích hợp nhất để thực hiện việc đánh giá độc lập này là sử dụng Support Vector Machine (SVM). SVM là phương pháp học máy đơn giản nhưng rất hiệu quả cho tập trung vào từng nhãn một cách độc lập, ít bị ảnh hưởng bởi các ví dụ sai trong dữ liệu huấn luyện. Ngoài ra, SVM cũng khá dễ dàng để thực hiện việc chọn lựa đặc trưng (features selection) để giảm kích thước dữ liệu model.

Phương pháp tiếp cận dạng pointwise sử dụng những thông tin xung quanh vị trí cần đánh giá, và thực hiện một cách độc lập với nhau. Chúng tôi sử dụng 3 dạng đặc trưng cơ bản trong phương pháp pointwise là : n-gram âm tiết, n-gram chủng loại của âm tiết, và đặc trưng từ điển.

N-gram âm tiết : sử dụng n-gram của những âm tiết xung quanh vị trí đang đánh giá. Ở đây, chúng tôi sử dụng một cửa sổ có độ dài W, và chúng tôi chỉ sử dụng những âm tiết nằm trong cửa sổ này.

Với tiếng Việt, có khoảng 70các từ gồm 2 âm tiết, và 14các từ gồm 3 âm tiết. Vì lý do này, chúng tôi sẽ sử dụng W là 3. Ngoài ra, n thường là 1 và 2. Trong thực nghiệm, chúng tôi có sử dụng cả n = 3, nhưng kết quả không được cải thiện nhiều, và kích thước file model cũng tăng lên đáng kể.

N-gram chủng loại của âm tiết : sử dụng chủng loại của các âm tiết trong cửa sổ. Trong nghiên cứu này, chúng tôi định nghĩa 4 chủng loại :
   o Âm tiết viết hoa (U) : những âm tiết tiếng Việt có bắt đầu bằng chữ hoa.
   o Âm tiết viết thường (L) : những âm tiết tiếng Việt chỉ gồm những chữ cái thường.
   o Số (N): gồm các chữ số.
   o Các loại khác (O) : những kí hiệu, tiếng nước ngoài, và những âm tiết không nằm trong 3 loại trên.

Đặc trưng từ điển : là những từ có trong từ điển

=> DongDu cho độ chính xác cao hơn vnTokenizer khoảng 1%. Về tốc độ xử lý, DongDu cũng nhanh hơn vnTokenizer khoảng 8 lần. Ngoài ra, DongDu đòi hỏi lượng RAM ít hơn vnTokenizer


- - -


https://github.com/taku910/mecab

https://towardsdatascience.com/mecab-usage-and-add-user-dictionary-to-mecab-9ee58966fc6

Mecab là 1 công cụ phân tách từ tiếng Nhật rất nổi tiếng và hiệu quả (trên 99với tiếng Nhật). Ưu điểm tuyệt với của Mecab là tính mềm dẻo và ứng dụng rất cao. Mecab được xây dựng với  phương hướng là tách biệt hoàn toàn chương trình và dữ liệu (từ điển, corpus huấn luyện, các định nghĩa và tham số). Vì thế, chỉ cần thay đổi dữ liệu trong Mecab, ta có thể nhận được những ứng dụng mới một cách hiệu quả. 

Trong phần giới thiệu về Mecab, tác giá Kudo Taku đã đưa ra 1 loạt các ví dụ về những ứng dụng của mecab như: 

- thêm nguyên âm cho tiếng Nhật, ví dụ "nhg" sẽ thêm nguyên âm thành "nihongo" (tiếng Nhật). 

- đổi từ bàn phím 9 số sang chữ. Ví dụ chuỗi "226066" sẽ đổi thành "cam on". (phím 2 tương ứng với abc, phím 6 tương ứng với mno).


Từ đặc điểm rất hiệu quả đó của mecab, tôi đang thực hiện việc Việt hoá Mecab bằng cách thay thế các dữ liệu của mecab từ tiếng Nhật sang tiếng Việt. 

Khó khăn hiện tại là sự khan hiếm về dữ liệu, khi mà có rất ít từ điển và corpus huấn luyện được công khai trên mạng. 

Bằng cách sử dụng dữ liệu của các phầm mềm mở cho tiếng Việt, tôi đã lấy được 1 số dữ liệu cần thiết như từ điển (khoảng 30.000 từ), corpus (khoảng 5000 câu đã tách từ - quá ít so với yêu cầu cần thiết). 

Ngoài các ứng dụng tách từ, tôi sẽ tìm hiểu thêm về cách sử dụng mecab để thêm dấu cho tiếng Việt, hay ứng dụng tạo bàn phím gõ tiếng Việt trên điện thoại. 


Việt hoá Mecab http://viet.jnlp.org/nghien-cuu-cua-tac-gia/c

Đây là kết quả ban đầu khi tôi thay thế từ điển tiếng Nhật bằng từ điển tiếng Việt (153433 từ) và huấn luyện máy học với corpus khoảng 6000 câu. Với dữ liệu như trên, kết quả thu được có lẽ không tốt, nhưng đây là 1 bằng chứng cho thấy hoàn toàn có thể ứng dụng Mecab vào phân tích tiếng Việt.