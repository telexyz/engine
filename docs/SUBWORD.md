## BPE

https://leimao.github.io/blog/Byte-Pair-Encoding/

In information theory, byte pair encoding (BPE) or diagram coding is a simple form of data compression in which the most common pair of consecutive bytes of data is replaced with a byte that does not occur within that data. On Wikipedia, there is a very good example of using BPE on a single string. It was also employed in natural language processing models, such as Transformer (trained on standard WMT 2014 English-German dataset) and GPT-2, to tokenize word sequences.

BPE in used https://github.com/google/sentencepiece

> “Sentencepiece, a language-independent subword tokenizer and detokenizer designed for Neural-based text processing” — SentencePiece Paper


## YTTM: Fatest BPE | https://github.com/VKCOM/YouTokenToMe

Fastest Byte Pair Encoding (BPE) [Sennrich et al.] much faster in training and tokenization than Hugging Face, fastBPE and SentencePiece. In some test cases, it is 90 times faster. Check out our benchmark results.

Just like in SentencePiece, all space symbols were replaced by meta symbol "▁" (U+2581). It allows sequences of tokens to be converted back to text and for word boundaries to be restored. For example, the phrase Blazingly fast tokenization! can be tokenized into ['▁Bl', 'az', 'ingly', '▁fast', '▁token', 'ization', '!']

Extra features: BPE-dropout (https://arxiv.org/pdf/1910.13267.pdf, 2019)

```sh
pip3 install youtokentome
# 600MB mất khoảng 60 secs (15 secs x 4-cpus)
 yttm bpe --data input/corpus/corpus-title.txt --model _models/yttm-utf8.model --vocab_size 20000
 yttm encode --model _models/yttm-telexified.model --output_type subword
```

- - -

Byte Pair Encoding is Suboptimal for Language Model Pretraining
https://arxiv.org/pdf/2004.03720.pdf

Subword Models | https://web.stanford.edu/class/archive/cs/cs224n/cs224n.1194/slides/cs224n-2019-lecture12-subwords.pdf

- - -

https://github.com/nguyenvulebinh/vietnamese-roberta

RoBERTa is an improved recipe for training BERT models that can match or exceed the performance of all of the post-BERT methods. The different between RoBERTa and BERT:
* Training the model longer, with bigger batches, over more data.
* Removing the next sentence prediction objective.
* Training on longer sequences.
* Dynamically changing the masking pattern applied to the training data.

Data to train this model is Vietnamese corpus crawled from many online newspapers: 50GB of text with approximate 7.7 billion words that crawl from many domains on the internet including news, law, entertainment, wikipedia and so on. Data was cleaned using visen library and tokenize using sentencepiece

```sh
spm_encode --model=models/roberta-case-nguyenvulebinh/sentencepiece.bpe.model
```
- - -

https://huggingface.co/transformers/tokenizer_summary.html

### Byte-level BPE
A base vocabulary that includes all possible base characters can be quite large if e.g. all unicode characters are considered as base characters. To have a better base vocabulary, GPT-2 uses bytes as the base vocabulary, which is a clever trick to force the base vocabulary to be of size 256 while ensuring that every base character is included in the vocabulary. With some additional rules to deal with punctuation, the GPT2’s tokenizer can tokenize every text without the need for the <unk> symbol. GPT-2 has a vocabulary size of 50,257, which corresponds to the 256 bytes base tokens, a special end-of-text token and the symbols learned with 50,000 merges.

**WordPiece**
WordPiece is the subword tokenization algorithm used for BERT, DistilBERT, and Electra. The algorithm was outlined in Japanese and Korean Voice Search (Schuster et al., 2012) and is very similar to BPE. WordPiece first initializes the vocabulary to include every character present in the training data and progressively learns a given number of merge rules. In contrast to BPE, WordPiece does not choose the most frequent symbol pair, but the one that maximizes the likelihood of the training data once added to the vocabulary.

So what does this mean exactly? Referring to the previous example, maximizing the likelihood of the training data is equivalent to finding the symbol pair, whose probability divided by the probabilities of its first symbol followed by its second symbol is the greatest among all symbol pairs. E.g. "u", followed by "g" would have only been merged if the probability of "ug" divided by "u", "g" would have been greater than for any other symbol pair. Intuitively, WordPiece is slightly different to BPE in that it evaluates what it loses by merging two symbols to make ensure it’s worth it.


- - -

https://leimao.github.io/blog/Byte-Pair-Encoding/

https://support.prodi.gy/t/can-you-explain-how-exactly-hashembed-works/564/2

- - -

https://www.lighttag.io/blog/character-level-NLP/

**Characters are Semantically Void**

Giving up on the semantic content of words is a non-trivial decision and not one you see frequently in state of the art systems. At the time of writing, Googles BERT models set state of the art, and come pre-trained on a 100 languages (including Vietnamese). Not many organizations have the compute capacity to run BERT pretraining so forgoing these models is a non-trivial decision. Having said that, it is interesting to note that the BERT model for Asian languages effectively works at the character level.

BERT-Base, Multilingual Cased (New, recommended): 104 languages, 12-layer, 768-hidden, 12-heads, 110M parameters | https://storage.googleapis.com/bert_models/2018_11_23/multi_cased_L-12_H-768_A-12.zip


On the input side of things, the main issue that character level models solve is the ability to handle an arbitrarily large vocabulary, including resilience to spelling mistakes and other anachronisms of human text. There exist two other commonly used approaches, and likely a few we aren't aware of.

**Subword Embeddings**
These are a class of embedding techniques that account for subword units during embedding pretraining. One of the first papers that made use of these was Neural Machine Translation of Rare Words with Subword Units which opens with:

making the NMT model capable of open-vocabulary translation by encoding rare and unknown  words as sequences of subword units. This is based on the intuition that various word classes are translatable via smaller units than words, for instance names (via character copying or transliteration), compounds (via compositional translation), and cognates and loanwords (via phonological and morphological transformations).

Systems in this genre including Facebooks fastText, Google's SentencePiece and SpaCy's HashEmbed which relies on Bloom Embedding.

**Combining word embeddings with character representations**
Another approach that's gaining significant traction is to input both word embeddings and process the characters of each word, then concatenate the result of processing with the corresponding words vector. Characters and words combined from Named Entity Recognition with Bidirectional LSTM-CNNs

- - -

https://arxiv.org/pdf/1804.10959.pdf

**Subword Regularisation**
There is, however, one small problem with the tokenisation process — which is what happens when you have multiple ways to split up the word based on the vocabulary list.

Subword regularization aims to “employ multiple subword segmentations to make the NMT model accurate and robust”. Here, NMT simply means “Neural Machine Translation”, referring to the use of neural networks in translating from one language to another in this context. Furthermore, “multiple subword segmentations” refer to our segmentation model considering the different ways in which a sentence can be split.

A new subword segmentation algorithm based on language models, which the paper calls ‘n-best decoding’. This simply refers to when given n-best segmentations, we choose the best to maximise a specific score. This score’s formula for those who are interested is:

So what does this all have to do with transformer architectures? How does this apply to models like T5/Reformer/XLNET?

- - -

## Train telexified corpus

```sh
spm_train --input=input/corpus/corpus-title-telexified.txt --model_prefix=telexified --num_threads=4

# =>

trainer_interface.cc(456) LOG(INFO) all chars count=591885298
trainer_interface.cc(467) LOG(INFO) Done: 99.9525% characters are covered.
trainer_interface.cc(477) LOG(INFO) Alphabet size=75
trainer_interface.cc(478) LOG(INFO) Final character coverage=0.999525
trainer_interface.cc(510) LOG(INFO) Done! preprocessed 9487382 sentences.

# Interactive mode
spm_encode --model=models/spm/telexified.model

echo "khoong cos gi quys hown ddoocj laapjtuwj do" | spm_encode --model=models/spm/telexified.model
# =>
▁khoong ▁cos ▁gi ▁quys ▁hown ▁ddoocj ▁laapj tuwj ▁do
```

## SentencePiece Subword Tokenizer / Detokenizer
https://github.com/google/sentencepiece

SentencePiece is an unsupervised text tokenizer and detokenizer mainly for Neural Network-based text generation systems where the vocabulary size is predetermined prior to the neural model training.

SentencePiece implements subword units and unigram language model with the extension of direct training from raw sentences. SentencePiece allows us to make a purely end-to-end system that does not depend on language-specific pre/postprocessing.


```sentpiece-build
brew install gperftools gcc
git clone https://github.com/google/sentencepiece.git 
cd sentencepiece
mkdir build
cd build
cmake ..
make -j $(nproc)
sudo make install
sudo update_dyld_shared_cache
```

```sh sentpiece-install
Install the project...
-- Install configuration: ""
-- Installing: /usr/local/lib/pkgconfig/sentencepiece.pc
-- Installing: /usr/local/lib/libsentencepiece.0.0.0.dylib
-- Installing: /usr/local/lib/libsentencepiece.0.dylib
-- Installing: /usr/local/lib/libsentencepiece.dylib
-- Installing: /usr/local/lib/libsentencepiece_train.0.0.0.dylib
-- Installing: /usr/local/lib/libsentencepiece_train.0.dylib
-- Installing: /usr/local/lib/libsentencepiece_train.dylib
-- Installing: /usr/local/lib/libsentencepiece.a
/Library/Developer/CommandLineTools/usr/bin/ranlib: file: /usr/local/lib/libsentencepiece.a(io_win32.cc.o) has no symbols
-- Installing: /usr/local/lib/libsentencepiece_train.a
-- Installing: /usr/local/bin/spm_encode
-- Installing: /usr/local/bin/spm_decode
-- Installing: /usr/local/bin/spm_normalize
-- Installing: /usr/local/bin/spm_train
-- Installing: /usr/local/bin/spm_export_vocab
-- Installing: /usr/local/include/sentencepiece_trainer.h
-- Installing: /usr/local/include/sentencepiece_processor.h
```

```sh sentpiece-usage
spm_train --input=input/corpus/corpus-title.txt --model_prefix=vn578mb --vocab_size=15000 --num_threads=4
echo "chào mọi người" | spm_encode --model=vn578mb.model

% echo "Hello world." | spm_encode --model=spm.model --output_format=id
151 88 21 887 6

% echo "_He ll o _world ." | spm_decode --model=spm.model
Hello world.

% echo "151 88 21 887 6" | spm_decode --model=spm.model --input_format=id
Hello world.
```

https://github.com/google/sentencepiece/blob/master/doc/experiments.md

* SentencePiece (Unigram/BPE) outperforms word-based methods (Moses/KyTea/MeCab/neologd) even with a smaller vocabulary (10% of word-based methods).

* The number of tokens to represent Japanese sentences is almost comparable between SentencePiece (unigram) and KyTea, though the vocabulary of SentencePiece is much smaller. It implies that Sentencepiece can effectively compress the sentences with a smaller vocabulary set.

* Pretokenization can slightly improve the BLEU scores in English to Japanese. In Japanese to English translation, pretokenization doesn't help to improve BLEU.

* Neologd shows poor BLEU score. Tokenizing sentences with a large named entity dictionary might not be effective in neural-based text processing.

* SentencePiece(Unigram) shows slightly better text compression ratio than BPE, but no significant differences in BLEU score.

* The selection of vocabulary size for SentencePiece is sensitive in English to Japanese. This is probably because the vocabulary size will drastically affect the tokenization results in Japanese which has no explicit spaces between words.

* MosesPretok does not always improve BLEU scores. Comparable accuracy can be obtained without using language-dependent resources in many language pairs.

* Whitespace pretokenization is a reasonable choice. It does not use language-specific resources.

* NoPretok shows poor BLEU scores. Unigrams are more robust than BPE when no pretokenizer is applied.

- - -

NFKC-based normalization: SentencePiece performs NFKC-based text normalization.
https://towardsdatascience.com/difference-between-nfd-nfc-nfkd-and-nfkc-explained-with-python-code-e2631f96ae6c

https://medium.com/the-artificial-impostor/nlp-four-ways-to-tokenize-chinese-documents-f349eb6ba3c3

- - -

https://blog.floydhub.com/tokenization-nlp/
Có tutorials về cách dùng SentPiece và HugingFace Tokenizer trong thực tế.
https://github.com/choran/sentencepiece


SentPiece Paper https://arxiv.org/pdf/1808.06226.pdf

larger performance improvements when applying it to raw Japanese data (w/o pre-tok). The segmentation speed of SentencePiece is about 380 times faster than that of subword-nmt in this setting. This result strongly supports our claim that SentencePiece is fast enough to be applied to raw data and the pre-tokenization is not always necessary. 

Consequently, SentencePiece helps to build a purely data-driven and language-independent system. The segmentation speed of SentencePiece is around 21k and 74k sentences/sec. in English and Japanese respectively, which is fast enough to be executed on-the-fly

. . . 

In this paper, we introduced SentencePiece, an open-source subword tokenizer and detokenizer designed for Neural-based text processing. SentencePiece not only performs subword tokenization, but directly converts the text into an id sequence, which helps to develop a purely end-toend system without replying on language specific resources.

The model file of SentencePiece is designed to be self-contained to guarantee perfect reproducibility of the normalization and subword segmentation. 

We hope that SentencePiece will provide a stable and reproducible text processing tool for production use and help the research community to move to more language-agnostic and multilingual architectures.

- - -

Neural Machine Translation models typically operate with a fixed vocabulary. Unlike most unsupervised word segmentation algorithms, which assume an infinite vocabulary, SentencePiece trains the segmentation model such that the final vocabulary size is fixed, e.g., 8k, 16k, or 32k.

SentencePiece is an unsupervised text tokenizer and detokenizer mainly for Neural Network-based text generation systems where the vocabulary size is predetermined prior to the neural model training. SentencePiece implements subword units (e.g., byte-pair-encoding (BPE) [Sennrich et al.]) and unigram language model [Kudo.]) with the extension of direct training from raw sentences. SentencePiece allows us to make a purely end-to-end system that does not depend on language-specific pre/postprocessing.

Purely data driven: SentencePiece trains tokenization and detokenization models from sentences. Pre-tokenization (Moses tokenizer/MeCab/KyTea) is not always required.

Language independent: SentencePiece treats the sentences just as sequences of Unicode characters. There is no language-dependent logic.

Multiple subword algorithms: BPE [Sennrich et al.] and unigram language model [Kudo.] are supported.

Subword regularization: SentencePiece implements subword sampling for subword regularization and BPE-dropout which help to improve the robustness and accuracy of NMT models.

Fast and lightweight: Segmentation speed is around 50k sentences/sec, and memory footprint is around 6MB.

Self-contained: The same tokenization/detokenization is obtained as long as the same model file is used.

Direct vocabulary id generation: SentencePiece manages vocabulary to id mapping and can directly generate vocabulary id sequences from raw sentences.

- - -

**Subword tokenization**
https://gist.github.com/atinsood/6d185dfe025cbb5d55f158d4d17bc142

- more frequent words should be given unique ids while less frequent words should be decomposed into subword units that best retain their meaning. the idea is that the common words would appear enough in our dataset and the model will be able to learn its meaning.

- 4 major subword tokenization algs
    - byte-pair encoding
    - wordpiece
    - unigram lang model
    - sentencepiece

- limitations of subword tokenizer
    - better off using rule based tokenizer when data is less (why??)
    - hard to learn a model for subword tokenizer even though the tokenization itself might be cheap
    - tokenizer that operate on character/byte level might allocate vocab space to variations of the same word; eg. dog , dog!, dog?


all the algs so far require pre-tokenization (they operate at word level and the sentence will still need to be tokenized before feeding it to the algorithms), which makes it harder for languages like chinese that are hard to tokenize on say whitespaces.

can be hard to de-tokenize

resolves both these by treating input as a raw stream of unicode characters and then using either BPE or unigram LM at character level to construct vocab. this means that the whitespaces are also included in tokenization.

For example, depending on the trained model, "I like natural language processing" might be tokenized like

"I", "_like", "_natural", "_lang", "uage", "_process", "ing" |_|

where the whitespace character is replaced with the underscore ("_") for clarity. Note the distinction with BPE, where the above sequence with the same subwords might be tokenized as

"I", "like", "natural", "lang", "##uage", "process", "##ing"

where subwords are prepended with a special marker.

Prepending subwords with a special marker only makes sense with a model that pretokenizes, since the sentencepiece model does not know anything about word boundaries.

why sentencepiece can afford to treat the input as a single stream of characters when we established earlier that finding the most frequent symbol bigram is a prohibitibly expensive operation in BPE. The reason is that sentencepiece uses a priority queue-based algorithm, reducing the asymtopic runtime from O(N^2) to O(NlogN).

sentence piece also applies unicode normalization.