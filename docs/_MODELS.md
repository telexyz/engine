# Models: FiT vs Transformers

https://nlp.fast.ai | https://github.com/fastai/fastai

Multilingual Fine-Tuning (MultiFiT) is different in a number of ways from the current main stream of NLP models: We do not build on BERT, but leverage a more efficient variant of an LSTM architecture. Consequently, our approach is much cheaper to pretrain and more efficient in terms of space and time complexity. Lastly, we emphasize having nimble monolingual models vs. a monolithic cross-lingual one. We also show that we can achieve superior zero-shot transfer by using a cross-lingual model as the teacher. This highlights the potential of combining monolingual and cross-lingual information.

MultiFiT extends ULMFiT to make it more efficient and more suitable for language modelling beyond English: It utilizes tokenization based on subwords rather than words and employs a QRNN rather than an LSTM. In addition, it leverages a number of other improvements.

## MultiFiT
https://github.com/n-waves/multifit

## ULMFiT

https://github.com/floleuerer/fastai_ulmfit

Motivation: Why even bother with a non-BERT / Transformer language model? Short answer: you can train a state of the art text classifier with ULMFiT with limited data and affordable hardware. The whole process (preparing the Wikipedia dump, pretrain the language model, fine tune the language model and training the classifier) takes about 5 hours on my workstation with a RTX 3090. The training of the model with FP16 requires less than 8 GB VRAM - so you can train the model on affordable GPUs.

https://github.com/fastai/course-nlp/blob/master/nn-vietnamese.ipynb

## Low-Resource NLP

https://ruder.io/nlp-beyond-english

https://ruder.io/recent-advances-lm-fine-tuning

https://thegradient.pub/the-benderrule-on-naming-the-languages-we-study-and-why-it-matters

https://github.com/fastai/course-nlp

https://lena-voita.github.io/nlp_course.html

https://github.com/neubig/lowresource-nlp-bootcamp-2020

https://stanfordnlp.github.io/stanza/available_models.html

https://universaldependencies.org/treebanks/vi_vtb/index.html

### https://medium.com/@pierre_guillou/faster-than-training-from-scratch-fine-tuning-the-english-gpt-2-in-any-language-with-hugging-f2ec05c98787 ###