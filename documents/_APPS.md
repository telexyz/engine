# 1/ Gõ nhang TV bằng tự động "Thêm dấu và thanh điệu"

Input: "toi la nguoi vietnam"
Desired output: "Tôi là người Việt Nam"

## Approach #1: Tận dụng pre-train models

Từ input tạo ra nhiều variants có dấu và thanh, sau đó embed variants vào một model có sẵn để scoring và tìm ra 1-3 variants tiềm năng nhất.

## Approach #2: bài toán translation từ ko dấu sang có dấu

Với mỗi sent của corpus, tạo 1 phiên bản ko dấu tương ứng. Dùng phiên bản ko dấu làm đầu vào, phiên bản có dấu làm đầu ra để train

## Approach #3: bài toán sửa lỗi chính tả

https://discuss.huggingface.co/t/pre-training-fine-tuning-seq2seq-model-for-spelling-and-or-grammar-correction-in-french/7090

https://www.microsoft.com/en-us/research/blog/speller100-zero-shot-spelling-correction-at-scale-for-100-plus-languages/

Pre-train a Seq2Seq model for a Quick Vietnamese Input Method by mapping Ascii syllables that missing marke and tones to UTF-8 syllables. E.g. toi noi tieng Viet => tôi nói tiếng Việt.

Problem: Most popular Vietnamese input method is Telex, that require additional keypress to create marks and tones for Vietnamese syllable. E.g: tooi => tôi, nois => nói, tieengs => tiếng, Vieetj => Việt. It's work just fine it you have are using laptop, desktop that have a physical QWERTY keyboard (typing with 8 fingers). But it's slow and error-prone while using smartphones (virtual keyboard typing with 2 fingers) or featured-phones (using T9 with only 0-9 keys). By using ML to map the minimal Ascii version of syllables to utf-8 with full marks and tone syllables, I hope that we can improve the situation. Beside pre-train the model using big data from pre-defined text corpus, on-the-fly learning / adapting from the document user is typing also help to improve the accuracy since we tend to repeating the same terms, keywords or phrases ...

Model: I'm quite new to the field so have no idea which model is best for Vietnamese in general. Please discuss.

Data: https://github.com/binhvq/news-corpus
around 18.6 GB of internet news/articles crawled from 130 Vietnamese online news websites.

Method: As you see from the example in the project title. We can treat the project as a sub-problem of spelling correction (deletion only). So we can follow below project proposal step-by-step.

https://discuss.huggingface.co/t/pre-training-fine-tuning-seq2seq-model-for-spelling-and-or-grammar-correction-in-english/7101

"The models who used to take weeks to train on GPU or any other hardware can put out in hours with TPU." TPU is only used for TensorFlow projects by researchers and developers.



# 2/ Gõ song ngữ Việt - Anh, hoặc tổng quát hơn Việt v.s Non-Việt

[ IMPORTANT ] Yếu điểm có thể coi là lớn nhất của Telex là viết song ngữ rất chậm,
vì hay bị hiểu lầm thành dấu mũ. Việc chuyển bàn phím thì cũng rất mất thời gian !!!

[ QUESTION ] Làm thế nào để giảm thiểu sự nhầm lẫn khi gõ tiếng Anh lẫn lộn với tiếng Việt ???

Mọi bộ gõ Telex, tới 1 ngưỡng nào đó đều phải QUYẾT ĐỊNH xem chuỗi keystrokes đầu vào nên được giữ-nguyên-như-nó-là hay convert thành marks & tone của tiếng Việt?

=> Dùng Classifier để classify chuỗi keystrokes xem nó là Việt hay Non-Việt.

Note #1: Input keystrokes là của từng syllable (với Vi) hoặc word (với En), có thể sử dụng context của chuỗi keystrokes trước, nhưng có lẽ ko có nhiều tác dụng bởi khi gõ lẫn lộn Vi+En ko thể đoán định xem từ tiếp theo liên quan tới từ trước ntn? Thậm chí người dùng có thể THỬ bộ gõ bằng cách gõ lẫn lộn ngẫu nhiên En words và Vi syllables.

Note #2: Càng hạn chế cách gõ Telex bao nhiêu càng giúp ích cho việc phân loại bởi số biến thể của syllable sẽ giảm đi. Ví dụ: quy định chỉ bỏ mark ngay sau nguyên âm và chỉ bỏ tone ở cuối syllable chẳng hạn.

Với bài toán binary-classification như trên có rất nhiều lựa chọn hiệu quả như Logistic Regression, k-Nearest Neighbors, Decision Trees, Support Vector Machine, Naive Bayes.

https://machinelearningmastery.com/types-of-classification-in-machine-learning/

Some algorithms are specifically designed for binary classification and do not natively support more than two classes; examples include Logistic Regression and Support Vector Machines.

## Challenging

DD: Với mỗi chuỗi keystrokes, hiện cả 2 phiên bản Vi vs Non-Vi rồi để người dùng lựa chọn trong trường hợp bộ gõ ko chắc chắn 100% về kq đầu ra. Challenge ở đây sẽ ở UI / UX.

VD: Thu thập data để train, cần build dần dần từ bản thân bộ gõ, khi người dùng cho phép nó "học" cách họ gõ để dự đoán tốt hơn.

BD: Dùng từ điển tiếng Anh, làm input, chọn ra những word có khả năng qua bộ gõ trở thành tiếng Việt. Nghĩ cách train classifier và hạn chế nhầm lẫn ở nhiều tầng mức, từ tầng mức bộ gõ cho tới ui/ux

## LightGBM (Light Gradient Boosting Machine)
https://github.com/microsoft/LightGBM nhanh-nhiều-tốt-rẻ

https://medium.com/@invest_gs/classifying-tweets-with-lightgbm-and-the-universal-sentence-encoder-2a0208de0424

https://www.sciencedirect.com/science/article/pii/S0895435621000147


## ThunderSVM (Fast SVM Library on GPUs and CPUs)
https://github.com/Xtra-Computing/thundersvm
