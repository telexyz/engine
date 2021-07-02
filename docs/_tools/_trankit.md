https://www.reddit.com/r/LanguageTechnology/
https://trankit.readthedocs.io/en/latest/howitworks.html

```py

from trankit import Pipeline 
p = Pipeline('vietnamese', embedding='xlm-roberta-base')

doc_txt = "Giá trúng bìnhd quâen 13.011 đồng/cp, thu về hơn 1.300 tỷf. cp cp cp. Tuyến tránh TP.Long Xuyên sẽ 'khai tử' trạm BOT T2. https://vnexpress.net/cdc-tinh-dong-thap-dong-cua-4299620.html"

all = p(doc_txt)

sents = all['sentences']

```

# Light-weight Transformer-based Toolkit for multilingual NLP
http://nlp.uoregon.edu/trankit
http://nlp.uoregon.edu/publications
https://classes.cs.uoregon.edu/21W/cis410nlp/

 Built on a state-of-the-art pretrained language model, Trankit significantly outperforms prior multilingual NLP pipelines over sentence segmentation, part-of-speech tagging, morphological feature tagging, and dependency parsing while maintaining competitive performance for tokenization, multi-word token expansion, and lemmatization over 90 Universal Dependencies treebanks. 

 Despite the use of a large pretrained transformer, our toolkit is still EFFICIENT IN MEMORY USAGE AND SPEED. This is achieved by our novel plug-and-play mechanism with Adapters where a multilingual pretrained transformer is shared across pipelines for different languages.

Developed by Vietnamese, support Vietnamese very well :D

- - -

https://paperswithcode.com/paper/trankit-a-light-weight-transformer-based
https://arxiv.org/pdf/2101.03289v4.pdf

A large portion of existing multilingual systems has focused on downstream NLP tasks that critically depend on upstream linguistic features, ranging from basic information such as token and sentence boundaries for raw text to more sophisticated struc- tures such as part-of-speech tags, morphological features, and dependency trees of sentences (called fundamental NLP tasks). As such, building effective multilingual systems/pipelines for fundamental upstream NLP tasks to produce such information has the potentials to transform multilingual downstream systems.

Unlike previous work, our token and sentence splitter is wordpiece-based instead of character-based to better exploit contextual information, which are beneficial in many languages. Considering the following sentence:

“John Donovan from Argghhh! has put out a excellent slide show on what was actually found and fought for in Fallujah.”

Trankit correctly recognizes this as a single sentence while character-based sentence split- ters of Stanza and UDPipe are easily fooled by the exclamation mark “!”, treating it as two separate sentences. To our knowledge, this is the first work to successfully build a wordpiece-based token and sentence splitter that works well for 56 languages.

Joint tok & sent splitter => Multi-word token expander => joint model for POS ...

Multilingual Encoder with Adapters. This is our core component that is shared across different transformer-based components for different lan- guages of the system. Given an input raw text s, we first split it into substrings by spaces. After- ward, Sentence Piece, a multilingual subword tok- enizer (Kudo and Richardson, 2018; Kudo, 2018), is used to further split each substring into word- pieces. By concatenating wordpiece sequences for substrings, we obtain an overall sequence of word- pieces w = [w1,w2,...,wK] for s. In the next step, w is fed into the pretrained transformer, which is already integrated with adapters, to obtain the wordpiece representations:

- - -

There have been several NLP toolkits that concerns multilingualism for fundamental NLP tasks, featuring spaCy1, UDify (Kondratyuk and Straka, 2019), Flair (Akbik et al., 2019), CoreNLP (Manning et al., 2014), UDPipe (Straka, 2018), and Stanza (Qi et al., 2020).

