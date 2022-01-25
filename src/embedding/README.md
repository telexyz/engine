![](ngram2vec.png) 

https://github.com/zhezhaoa/ngram2vec

https://aclanthology.org/D17-1023.pdf

ngram2vec toolkit could be used for learning text embedding. Text embeddings trained by ngram2vec are very competitive. They outperform many deep and complex neural networks and achieve state-of-the-art results on a range of datasets. 


TODO

* Gắp comments từ bản gốc sang `word2vec.c` để hiểu hơn về cách cài đặt thuật toán

  https://github.com/chrisjmccormick/word2vec_commented/blob/master/word2vec.c


* Đọc hiểu thuật toán SGNS (skip-gram negative sampling)

  https://www.cs.upc.edu/~padro/ahlt/2020/lectures/06-wordvectors.pdf

  https://aegis4048.github.io/optimize_computational_efficiency_of_skip-gram_with_negative_sampling


* Vẫn chưa hiểu thì mua book về mà đọc

  https://www.chrismccormick.ai/word2vec-ebook


* Tìm hiểu về `word2phrase`

  https://github.com/chrisjmccormick/word2vec_commented/blob/master/word2phrase.c

	Each run of the word2phrase tool looks at combinations of two words (or tokens), so the first pass would turn "New York" into "New_York" and the second pass would turn "New_York City" into "New_York_City".

