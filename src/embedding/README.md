Véc tơ hóa tokens, một bước rất quan trọng làm similary search, tìm từ đồng nghĩa, xác định topics ...

Có rất nhiều kỹ thuật từ đơn giản (word2vec) đến phức tạp như transformers ..

Bước đầu có thể dùng ngay thư viện C của word2vec nhúng vào trong zig để sử dụng ..

Quan trọng là hiểu thuật toán !!!

=> Có thể viết lại word2vec từ mã nguồn C để hiểu thuật toán !!!

_Word2Vec_ https://github.com/zhezhaoa/ngram2vec/blob/master/word2vec/word2vec.c

Một module quan trọng trong việc trình bày lại token dưới dạng vector trong không gian khoảng 300 chiều, quan trọng trong việc tìm kiếm token giống nhau, dùng để train NN/LM, re-ranking, re-scoring ...

https://aegis4048.github.io/optimize_computational_efficiency_of_skip-gram_with_negative_sampling