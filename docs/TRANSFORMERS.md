## Transformers: State-of-the-Art Natural Language Processing
https://arxiv.org/pdf/1910.03771.pdf

- - -

https://pytorch.org/tutorials/beginner/transformer_tutorial.html

- - -

https://pytorch.org/tutorials/beginner/nlp/advanced_tutorial.html

`LSMT` 			Long Short-Term Memory
`CRF` 			Conditional Random Field
`Bi-LSMT` 		Bidirectional LSMT
`Bi-LSMT-CRF`	Bidirectional LSMT with a CRF layer

Pytorch is a dynamic neural network kit. The opposite is the static tool kit, which includes Theano, Keras, TensorFlow, etc. The core difference is the following:

* In a static toolkit, you define a computation graph once, compile it, and then stream instances to it.

* In a dynamic toolkit, you define a computation graph for each instance. It is never compiled and is executed on-the-fly.

## Bidirectional LSTM-CRF Models for Sequence Tagging
http://www.cs.columbia.edu/~mcollins/crf.pdf
2015 http://export.arxiv.org/pdf/1508.01991

Bi-LSTM-CRF model can efficiently use both past and future input features thanks to a bidirectional LSTM component. It can also use sentence level tag information thanks to a CRF layer. The BI-LSTM-CRF model can produce state of the art (or close to) accuracy on POS, chunking and NER data sets. In addition, it is robust and has less dependence on word embedding as compared to previous observations.
