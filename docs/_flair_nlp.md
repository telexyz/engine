1/ A POWERFUL NLP LIBRARY

Flair allows you to apply SoTA NLP models to your text, such as named entity recognition (NER), part-of-speech tagging (PoS), special support for biomedical data, sense disambiguation and classification, with support for a rapidly growing number of languages.

2/ A TEXT EMBEDDING LIBRARY

Flair has simple interfaces that allow you to use and combine different word and document embeddings, including our proposed Flair embeddings, BERT embeddings and ELMo embeddings.

3/ A PYTORCH NLP FRAMEWORK

Our framework builds directly on PyTorch, making it easy to train your own models and experiment with new approaches using Flair embeddings and classes.


New: Most Flair sequence tagging models (named entity recognition, part-of-speech tagging etc.) are now hosted on the 🤗 HuggingFace model hub! You can browse models, check detailed information on how they were trained, and even try each model out online!


Flair is developed by German, hence it's perf best form German and Dutch 
(NER models Conll-03 (4-class) 92.31 vs 90.3 Best published).


https://www.analyticsvidhya.com/blog/2019/02/flair-nlp-library-python/

Until now, the words were either represented as a sparse matrix or as word embeddings such as GLoVe, Bert and ELMo, and the results have been pretty impressive. But, there’s always room for improvement and Flair is willing to stand up to it.

What Gives Flair the Edge?

1/ It comprises of popular and state-of-the-art word embeddings, such as GloVe, BERT, ELMo, Character Embeddings, etc. There are very easy to use thanks to the Flair API

2/ Flair’s interface allows us to combine different word embeddings and use them to embed documents. This in turn leads to a significant uptick in results

3/ ‘Flair Embedding’ is the signature embedding provided within the Flair library. It is powered by contextual string embeddings. We’ll understand this concept in detail in the next section

4/ Flair supports a number of languages – and is always looking to add new ones


https://medium.com/analytics-vidhya/practical-approach-of-state-of-the-art-flair-in-named-entity-recognition-46a837e25e6b

Today Let’s discuss about most popular use case in NLP, i.e. NER — Named Entity Recognition. In this post we will go through practical usage of one of the state of the art algorithm, Flair.

NER can be used to Identify Entities like Organizations, Locations, Persons and Other Entities in a given text.


!!! VERY GOOD, THOUGHTFUL, DETAILS ARTICLE !!!
NER algo benchmark: spaCy, Flair, m-BERT and camemBERT on anonymizing French commercial legal cases https://towardsdatascience.com/benchmark-ner-algorithm-d4ab01b2d4c3

We tested 4 algorithms, 2 are Transformer based, 1 is bi-LSTM based, 1 has an original architecture:

* spaCy v.2.2, this version introduces an interesting data augmentation mechanism similar to what we tried manually in our previous article, does it work better?

* Flair: bi-LSTM character-based model, it brought the highest scores last time, is this going to repeat again?

* multilingual BERT (mBERT): the famous Google model supporting 104 languages, can you do good work with such large support?

* camemBERT, a new mono-language BERT model for French, was it necessary to put energy to build such model when mBERT already supports French?

THE UNSUNG HEROES: ANNOTATION TOOLS AND QUALITY CONTROL

Prody.gy, Doccano, tagtog ...

camemBERT is much better than mBERT, and slightly better than Flair on some entities like ADDRESS. It is in line with the camemBERT paper findings (slightly better than 2018 Bi-LSTM CRF SOTA).

memory footprint of Flair is much lower, making possible to have larger batch during inference (= speeeeeed).

## Conclusion
In this benchmark, we have compared 4 models on a real-life dataset, and our main observations are the following:

* With its original architecture, spaCy provides much lower performance than other tested models, the data augmentation schema is not enough,

* mBERT is a huge (slow) transformer model. On our NER task, it doesn’t translate into high scores, this observation is in line with findings from camemBERT paper,

* Flair and camemBERT _PROVIDE SIMILAR RESULTS_ (slightly better for camemBERT) but camemBERT suffers from an annoying limitation regarding text size (the 512 token limit) and is slower than Flair on both training and inference.

* Our conclusion is that in our case and for this dataset, *FLAIR IS STILL THE BEST CHOICE*. Moreover, we think that with a larger dataset for pre-training (or a fine tuning step on in domain data), the results may be even higher, as found by our Supreme Court in its NER paper.

* Indeed, it appears that camemBERT has been pre-trained on 138 Gb of uncompressed text compared to Flair language model which only relies on French Wikipedia (more than 1 order of magnitude smaller).


We don’t think that our findings would generalize to other tasks like classification. Character based language models are very good at NER because suffixes and prefixes are powerful features, but in classification we would expect camemBERT to easily beat Flair language model.

Moreover, in line with Multifit paper, it also shows that *PRACTITIONERS SHOULD THINK TWICE BEFORE WORKING WITH mBERT*. It seems smart to use even simpler monolingual language model instead, when they exist.

Why we switched from Spacy to Flair to anonymize French case law |https://towardsdatascience.com/why-we-switched-from-spacy-to-flair-to-anonymize-french-legal-cases-e7588566825f

