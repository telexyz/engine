https://www.edwardraff.com/publications/hash-grams-faster.pdf

The results are presented in Table 1, where we see that the exact n-gram and hash-gram models have indistinguishable accuracy on both of the test sets. All scores are close, and fluctuated between slightly better and worse on individual numbers. The slight changes in results are not unexpected due to the hash collisions, but is clearly of equivalent predictive quality to the exact n-gram model.

The Hash-Gram approach was 68.8 times faster in extracting the top-k features compared to the n-gram approach, allowing us to reduce a two week job on a cluster down to under three days on a single node. We note that the code used for the exact n-gram is highly optimized Java code that has gone through three years of performance tuning and improvements to scale up the n-gram processing.


Recursive Hashing Functions for n-Grams
https://www.csee.umbc.edu/courses/graduate/676/recursivehashingp291-cohen


Efficient Indexing of Repeated n-Grams
https://ciir-publications.cs.umass.edu/getpdf.php?id=939


Enhancing N-Gram-Hirschberg Algorithm by Using Hash Function
https://booksc.org/book/32036707/87c78d


n-gram http://web.stanford.edu/~jurafsky/slp3
