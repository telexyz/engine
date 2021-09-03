# KEYWORDS

Smoothing, Interpolation
Goodman, Kneser-Ney, Stupid-backoff
Bloom filter, Hash, Cache

- - -

Rất nhiều thông tin về n-gram LM
http://demo.clab.cs.cmu.edu/11711fa18 | http://www.cs.cmu.edu/~tbergkir/11711fa17

- - -

## Smoothed Bloom filter language models: Tera-Scale LMs on the Cheap
https://aclanthology.org/D07-1049.pdf

We assign a small cache to the BF-LM models (between 1 and 2MBs depending on the order of the model) to store recently retrieved statistics and derived probabilities. Translation takes between **2 to 5 times longer** using the BF-LMs as compared to the corresponding SRILM models.

## Randomized Language Models via Perfect Hash Functions
https://aclanthology.org/P08-1058.pdf

Our randomized LM is based on the Bloomier filter (Chazelle et al., 2004). We assume the n-grams and their associated parameter values have been precomputed and stored on disk. We then encode the model in an array such that each n-gram’s value can be retrieved. Storage for this array is the model’s only significant space requirement once constructed.

The model uses randomization to map n-grams to fingerprints and to generate a perfect hash function that associates n-grams with their values. The model can erroneously return a value for an n-gram that was never actually stored, but will always return the correct value for an n-gram that is in the model.

The proposed randomized LM can encode parameters estimated using any smoothing scheme (e.g. Kneser-Ney, Katz etc.). Here we choose to work with stupid backoff smoothing (Brants et al., 2007) since this is significantly more efficient to train and deploy in a distributed framework than a context-dependent smoothing scheme such as Kneser-Ney. Previous work (Brants et al., 2007) has shown it to be appropriate to large-scale language modeling.

![](files/bloomier_n-gram_false_pos.png)

## KenLM: Faster and Smaller Language Model Queries
https://kheafield.com/papers/avenue/kenlm.pdf
https://kheafield.com/papers/avenue/kenlm_talk.pdf
https://kheafield.com/papers/edinburgh/estimate_paper.pdf
https://kheafield.com/papers/edinburgh/estimate_talk.pdf

Maximize speed and accuracy subject to memory. 
Probing > Trie > Chop > RandLM Stupid for both speed and memory.

## Faster and Smaller N-Gram Language Models
http://nlp.cs.berkeley.edu/pubs/Pauls-Klein_2011_LM_paper.pdf

Berkeley Java; slower and larger than KenLM
https://github.com/adampauls/berkeleylm

N -gram language models are a major resource bottleneck in machine translation. We present several language model impl that are both highly compact and fast to query. Our fastest impl is as fast as the widely used SRILM while requiring only 25% of the storage. 

Our most compact representation can store all 4 billion n-grams and associated counts for the Google n-gram corpus in 23 bits per n-gram, the most compact lossless representation to date, and even more compact than recent lossy compression techniques. We also discuss techniques for improving query speed during decoding, including a simple but novel LANGUAGE MODEL CACHING technique that improves the query speed of our language models (and SRILM) by up to 300%.

Overall, we are able to store the 4 billion n-grams of the Google Web1T corpus, with associated counts, in 10 GB of memory, which is smaller than state-of-the-art lossy language model implementations (Guthrie and Hepple, 2010). 


## A Bayesian Interpretation of Interpolated Kneser-Ney
https://www.stats.ox.ac.uk/~teh/research/compling/hpylm.pdf
https://www.gatsby.ucl.ac.uk/~ywteh/research/compling/acl2006.pdf

Interpolated Kneser-Ney is one of the best smoothing methods for n-gram language models. Previous explanations for its superiority have been based on intuitive and empirical justifications of specific properties of the method. We propose a novel interpretation of interpolated Kneser-Ney as approximate inference in a hierarchical Bayesian model consisting of Pitman-Yor processes. As opposed to past explanations, our interpretation can recover exactly the formulation of interpolated Kneser-Ney, and performs better than interpolated Kneser-Ney when a better inference procedure is used.

- - -

https://www.edwardraff.com/publications/hash-grams-faster.pdf

The results are presented in Table 1, where we see that the exact n-gram and hash-gram models have indistinguishable accuracy on both of the test sets. All scores are close, and fluctuated between slightly better and worse on individual numbers. The slight changes in results are not unexpected due to the hash collisions, but is clearly of equivalent predictive quality to the exact n-gram model.

The Hash-Gram approach was 68.8 times faster in extracting the top-k features compared to the n-gram approach, allowing us to reduce a two week job on a cluster down to under three days on a single node. We note that the code used for the exact n-gram is highly optimized Java code that has gone through three years of performance tuning and improvements to scale up the n-gram processing.


## Recursive Hashing Functions for n-Grams
https://www.csee.umbc.edu/courses/graduate/676/recursivehashingp291-cohen


## Efficient Indexing of Repeated n-Grams
https://ciir-publications.cs.umass.edu/getpdf.php?id=939


## Enhancing N-Gram-Hirschberg Algorithm by Using Hash Function
https://booksc.org/book/32036707/87c78d


n-gram http://web.stanford.edu/~jurafsky/slp3
