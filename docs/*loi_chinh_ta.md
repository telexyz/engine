https://github.com/arthurflor23/spelling-correction

1/ JamSpell mới dùng 3-gram đã đạt được độ chính xác tầm 69% [1]
2/ Các biến thể LSTM đều đạt ngưỡng tầm 79% [1]
3/ +10-gram với tác vụ word segment có hiệu quả tương đương với NN [2]

=> a/ Thử tăng n-gram với JamSpell xem có tăng độ chính xác lên nhiều không?

=> b/ Cân bằng giữa độ chính xác và tài nguyên sử dụng (Mem, CPU)

![1](files/03-gram_vs_nn_spelling_correction.png){width=500 height=410}

![2](files/12-gram_vs_nn_word_segment.png)
