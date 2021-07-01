# TASKS

“For machines to perform these complex applications, they need to perform several smaller, more bite-sized NLP tasks. In other words, to build successful commercial NLP applications, we must master the NLP tasks that serve as building blocks for those applications.”

These tasks are:

## Tokenization

“Tokenization is the process of splitting text into minimal meaningful units such as words, punctuation marks, symbols, etc. Tokenization is a necessary step because the machine needs to break down natural language data into the most basic elements (or tokens) so that it can analyze each element in context of the other elements”

“Just like a beginner student of a language breaks down a sentence into smaller bits to learn and process the information word by word, a machine needs to do the same. Even with complex numerical calculations, machines break down the problem into basic elements, performing tasks such as addition, subtraction, multiplication, and division of two sets of numbers. The major advantage that the machine has is that it can do this at a pace and scale that no human can.”

AFTER TOKENIZATION BREAKS DOWN THE TEXT INTO MINIMAL MEANINGFUL UNITS, THE MACHINE NEEDS TO ASSIGN METADATA TO EACH UNIT, PROVIDING IT MORE INFORMATION ON HOW TO PROCESS EACH UNIT IN THE CONTEXT OF OTHER UNITS.

## Part-of-Speech Tagging
. . .

## Dependency Parsing

“labeling the relationships between individual tokens, assigning a syntactic structure to the sentence. Once the relationships are labeled, the entire sentence can be structured as a series of relationships among sets of tokens. It is easier for the machine to process text once it has identified the inherent structure among the text.”

https://demo.allennlp.org/dependency-parsing/

## Chunking

“combining related tokens into a single token, creating related noun groups, related verb groups, etc. For example, “New York City” could be treated as a single token/chunk instead of as three separate tokens.

Chunking is important to perform once the machine has broken the original text into tokens, identified the parts of speech, and tagged how each token is related to other tokens in the text. 

Chunking combines similar tokens together, making the overall process of analyzing the text a bit easier to perform. For example, instead of treating “New,” “York,” and “City” as three separate tokens, we can infer that they are related and group them together into a single group (or chunk). Then, we can relate the chunk to other chunks in the text. Once we’ve done this for the entire set of tokens, we will have a much smaller set of tokens and chunks to work with.”

## Named entity recognition
. . .

## Entity linking

the process of disambiguating entities to an external database, linking text in one form to another. This is important both for entity resolution applications (e.g., deduping datasets) and information retrieval applications. 

In the George W. Bush example, we would want to resolve all instances of “George W. Bush” to “George W. Bush,” but not to “George H. W. Bush,” George W. Bush’s father and also a former US President. This resolution and linking to the correct version of President Bush is a tricky, thorny process, but one that a machine is capable of performing given all the textual context it has. 

ONCE A MACHINE HAS PERFORMED ENTITY RECOGNITION AND LINKING, INFORMATION RETRIEVAL BECOMES A CINCH, WHICH IS ONE OF THE MOST COMMERCIALLY RELEVANT APPLICATIONS OF NLP TODAY.

https://developers.google.com/knowledge-graph


# LANGUAGE MODELS

A language model is a function that takes in a sequence of words and returns a probability distribution over all the possible next words in that sequence. THIS TASK IS CONSIDERED ONE OF THE MOST IMPORTANT IN NLP BECAUSE, AS THE REASONING GOES, TO PREDICT THE NEXT WORD IN A SENTENCE, YOU MUST HAVE A GOOD UNDERSTANDING OF THE LANGUAGE. 

Language models learn the features and characteristics of language to guess what the next word should be after any given phrase or sentence. They are the backbone of NLP today because they do not require explicit annotations (labels) and can be trained on massive corpuses without material data preparation. Once they learn the properties of language well, language models can be fine-tuned to perform more specific NLP tasks such as text classification, which is what we’re going to do in this chapter.”

# https://huggingface.co/transformers/task_summary.html


- - - - - - - - -

Understand how exactly modern NLP works from FIRST PRINCIPLES.

+ 1/ Tokenizers (*)
+ 2/ Embeddings (*)
+ 3/ Recurrent neural networks (RNNs)
+ 4/ Transformers
+ 5/ Transfer learning

# 1/ TOKENIZER

“The type of tokenizers we’re interested in as deep learning practitioners, though, usually don’t give us parse trees. What we want is a tokenizer that reads the text and generates a sequence of one-hot vectors.”

“That is the most important thing to understand about tokenizers from our top-down perspective. The input is raw text, and the output is a sequence of vectors. To be even more specific, the vectors, in our case, are simply one-hot encoded PyTorch tensors that we pass into an nn.Embedding layer. Once we get to that stage, where we can pass something to an embedding layer (which we’ll discuss in the next chapter), we’re done with tokenization.”

“There are two tools for tokenization that are superior to most of the others–spaCy’s tokenizer and the Hugging Face tokenizers library.

spaCy’s tokenizer is more widely used, is older, and is somewhat more reliable. It has its own unique tokenization algorithm that tends to work well for common NLP tasks. 

The tokenizers library is a slightly more modern package that focuses on implementing the newest algorithms from the newest research.”

“The tokenizers library further subdivides the task of tokenizations into smaller, more manageable steps. Here’s Hugging Face’s description of the components of the tokenization process in its library:

## Normalizer
Executes all the initial transformations over the initial input string. For example, when you need to lowercase some text, maybe strip it, or even apply one of the common Unicode normalization processes, you will add a Normalizer.

## PreTokenizer
In charge of splitting the initial input string. That’s the component that decides where and how to pre-segment the origin string. The simplest example would be like we saw before, to split on spaces.

## Model
Handles all the subtoken discovery and generation. This part is trainable and really dependent of your input data.

## Post-Processor
Provides advanced construction features to be compatible with some of the Transformer-based SOTA models. For instance, for BERT it would wrap the tokenized sentence around [CLS] and [SEP] tokens.

## Decode
In charge of mapping back a tokenized input to the original string. The decoder is usually chosen according to the PreTokenizer we used previously.

## Trainer
Provides training capabilities to each model.

Each of those logical modules has multiple options/implementations in the library:
Normalizer
Lowercase, Unicode (NFD, NFKD, NFC, NFKC), Bert, Strip…

## PreTokenizer
ByteLevel, WhitespaceSplit, CharDelimiterSplit, Metaspace, …

## Model
WordLevel, BPE, WordPiece, …

## Post-Processor
BertProcessor, …

## Decoder
WordLevel, BPE, WordPiece, …

https://huggingface.co/docs/tokenizers/python/latest/

## SubWord

“the simplest character-based tokenizers will generally never produce unknown tokens but will also break up a word into many small pieces, which may cause some loss of information. On the other hand, you can fully and accurately represent words with word-level tokenization, but then you’ll need a very large vocabulary, or you risk having many unidentified tokens.”

“So, the goal here is twofold:
* Increase the amount of information per token.
* Decrease the total number of tokens (vocabulary size).

Subword tokenizers achieve this effectively by FINDING A GOOD BALANCE BETWEEN CHARACTERS, SUBWORDS, AND WORDS.”

Note: “Subword tokenization algorithms (the newer ones, at least) are not set in stone. There is a “training” phase before we can actually tokenize the text. This is not the training of the language model itself, but rather a process we run to find the optimal balance between character-level and word-level tokenization.”

## Conclusion
“If you have a custom dataset with a lot of domain-specific vocabulary (like in legal or medical applications) it makes sense to retrain an established tokenizer algorithm like WordPiece or SentencePiece.”

“can’t pass raw tokens into the model. Tokens are still essentially indices in dictionaries, which is not semantically useful for a deep learning model. Instead, we pass what are called “embeddings” of the tokens, which is what the next chapter is all about.”

# 2/ EMBEDDINGS

“If tokenizers are what our models will use to read text, embeddings are what they use to understand it.”

There are servaral way to encode text
https://upload.wikimedia.org/wikipedia/commons/1/1b/ASCII-Table-wide.svg

“A computer is a machine that can only manipulate 1s and 0s. So WHEN WE SAY “UNDERSTAND,” WHAT WE REALLY MEAN IS THAT WE NEED A NEW WAY OF ENCODING TEXT INTO NUMBERS THAT EMPHASIZES THE MEANING OF THE TEXT RATHER THAN THE RAW CHARACTERS.”

“To recap: we know that we can encode raw text accurately using established methods like ASCII and Unicode. However, we noted that having the raw text alone is not sufficient to create NLP models that dazzle investors. So, we need a way to map text to numbers that encode the meaning of the words rather than the raw information. We know that there’s no perfect way to do this, but we’re hoping that we can do it in a way that’s at least useful to solve the NLP tasks”

One-hot vector has size of vocab (ten-thounsand for example)
    W1 ..... Wn
W1 [ 1 0 ..  0 ]
W2 [ 0 1 ..  0 ]
.
.
Wn [ 0 0 ... 1 ]

Token2Vec, Glove are used to map one-hot vec to lower dimension (300 for example) that present meaningful information about token.

“Word2vec and GloVe are falling out of fashion because there are newer, sleeker systems that do the same thing. To be specific, when we refer to Word2Vec, we’re essentially talking about the giant embedding matrix. If you download a Word2Vec model online, you’re basically getting a function that takes in words and returns vectors. But newer, faster, better-documented solutions like Flair and fastText are probably better choices.”

Token2Vec, Glove are out-of-date.
=> FLAIR and fastText is better choices

## Embeddings in the Age of Transfer Learning

## Embedding Things That Aren’t Words
