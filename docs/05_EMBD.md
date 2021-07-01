# EMBEDDING
https://github.com/flairNLP/flair/blob/master/resources/docs/TUTORIAL_3_WORD_EMBEDDING.md

## Stacked (Token) Embeddings

Stacked embeddings are one of the most important concepts of this library. You can use them to combine different embeddings together, for instance if you want to use both traditional embeddings together with contextual string embeddings. Stacked embeddings allow you to mix and match. We find that a COMBINATION OF EMBEDDINGS OFTEN GIVES BEST RESULTS.

## Document Embeddings
https://github.com/flairNLP/flair/blob/master/resources/docs/TUTORIAL_5_DOCUMENT_EMBEDDINGS.md

Document embeddings are different from word embeddings in that they give you one embedding for an entire text, whereas word embeddings give you embeddings for individual words.

* 1/ `DocumentPoolEmbeddings` do an average over all `word embeddings` in the sentence
* 2/ `DocumentRNNEmbeddings` train an RNN over all `word embeddings` in a sentence
* 3/ `TransformerDocumentEmbeddings` that use `pre-trained transformers` and are recommended for most text classification tasks
* 4/ `SentenceTransformerDocumentEmbeddings` that use `pre-trained transformers` and are recommended if you need A GOOD VECTOR REPRESENTATION OF A SENTENCE


https://github.com/flairNLP/flair/blob/master/resources/docs/TUTORIAL_9_TRAINING_LM_EMBEDDINGS.md


## Contextual String Embeddings
https://drive.google.com/file/d/17yVpFA7MmXaQFTe-HDpZuqw9fJlmzg56/view

Recent advances in language modeling using recurrent neural networks have made it viable to model language as distributions over characters. By learning to predict the next character on the basis of previous characters, such models have been shown to automatically internalize linguistic concepts such as words, sentences, subclauses and even sentiment.

Our proposed embeddings have the distinct properties that they (a) are TRAINED WITHOUT ANY EXPLICIT NOTION OF WORDS and thus fundamentally model words as sequences of characters, and (b) are CONTEXTUALIZED BY THEIR SURROUNDING TEXT, meaning that __THE SAME WORD WILL HAVE DIFFERENT EMBEDDINGS DEPENDING ON ITS CONTEXTUAL USE__.

### Intro

A large family of NLP tasks such as named entity recognition (NER) and part-of-speech (PoS) tagging may be formulated as sequence labeling problems; text is treated as a sequence of words to be labeled with linguistic tags. 

Current state-of-the-art approaches for sequence labeling typically use the LSTM variant of bidirectional recurrent neural networks (BiLSTMs), and a subsequent conditional random field (CRF) decoding layer.


A crucial component in such approaches are word embeddings, typically trained over very large collec- tions of unlabeled data to assist learning and generalization. Current state-of-the-art methods concatenate up to three distinct embedding types:

1. Classical word embeddings, pre-trained over very large corpora and shown to capture latent syntactic and semantic similarities.

2. Character-level features, which are not pre-trained, but trained on task data to capture task-specific subword features.

3. Contextualized word embeddings that capture word semantics in context to address the polysemous and context-dependent nature of words.

### Contextual string embeddings. 

In this paper, we propose a novel type of contextualized character- level word embedding which we hypothesize to combine the best attributes of the above-mentioned embeddings; namely, the ability to (1) pre-train on large unlabeled corpora, (2) capture word meaning in context and therefore produce different embeddings for polysemous words depending on their usage, and (3) model words and context fundamentally as sequences of characters, to both better handle rare and misspelled words as well as model subword structures such as prefixes and endings.

We present a method to generate such a contextualized embedding for any string of characters in a sentential context, and thus refer to the proposed representations as contextual string embeddings.

High level overview of proposed approach. A sentence is input as a character sequence into a pre-trained bidirec- tional character language model. From this LM, we retrieve for each word a contextual embedding that we pass into a vanilla BiLSTM-CRF sequence labeler, achieving robust state-of-the-art results on downstream tasks (NER in Figure).


## Paraphrastic Representations at Scale

"Paraphrastic representations at scale" is a strong, blazing fast package for sentence embeddings. Beats Sentence-BERT, LASER, USE on STS tasks, WORKS MULTILINGUALLY, AND IS UP TO 6,000 TIMES FASTER." 30/04/2021

https://arxiv.org/pdf/2104.15114.pdf

https://github.com/jwieting/paraphrastic-representations-at-scale


`paraphrastic` - altered by paraphrasing. altered - changed in form or character without becoming something else.

the resulting models surpass all prior work on __UNSUPERVISED SEMANTIC TEXTUAL SIMILARITY, SIGNIFICANTLY OUTPERFORMING__ even BERT-based models like SentenceBERT (Reimers and Gurevych, 2019). Additionally, our models are __ORDERS OF MAGNITUDE FASTER__ than prior work and can be used on CPU with little difference in inference speed (even improved speed over GPU when using more CPU cores), making these models an attractive choice for users without access to GPUs or for use on embedded devices.

Finally, we add SIGNIFICANTLY INCREASED FUNCTIONALITY TO THE CODE BASES FOR TRAINING PARAPHRASTIC SENTENCE MODELS, easing their use for both inference and for training them for any desired language with parallel data. We also include code to automatically download and preprocess training data.


Measuring sentence similarity is an important task in natural language processing, and has found many uses including paraphrase detection.

semantic similarity reward when fine-tuning language generation models on tens of millions of training examples. These tasks are much more feasible when using approaches that are fast, can be run on CPU, and use little RAM allowing for increased batch size.

Train an English model on 25.85 million paraphrase pairs from ParaNMT


### Cross-Lingual Semantic Similarity and Semantic Similarity in Non-English Languages

Most previous work for cross-lingual representations has focused on models based on encoders from neural machine translation

Training. The training data consists of a sequence of parallel sentence pairs (si, ti) in source and target languages respectively. Note that for training our English model, the source and target languages are both English as we are able to make use of an existing paraphrase corpus.

Encoder. Our sentence encoder g simply averages the embeddings of subword units generated
by sentencepiece. This means that the sentence piece embeddings themselves are the only learned parameters of this model.