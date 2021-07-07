https://openclass.ai/catalog/nlp

- - -

https://www.reddit.com/r/LanguageTechnology/comments/o8uoqq/when_to_use_ner_and_pos_tagging/

In industry we're mostly pragmatic engineers who aren't aiming for SOTA but "WHATEVER WORKS AND IS CHEAPEST".

NER - perhaps in combination with some form of co-reference resolution can be useful in and of itself for some use cases: for example clients might want to group/filter documents by which people and organisations are mentioned most within them. Likewise POS tagging for identifying verb chunks and noun chunks for the purpose of metadata enrichment or to improve document retrieval is quite common. Both NER and POS are useful upstream tasks that help with co-reference resolution and entity linking.

At my company the philosophy is to start with simple models and move towards more complex modelling approaches only if you have to. If I can get 0.93 micro F1 on a text classification problem using bag-of-words features and a logistic regression model that will happily chug through 100k inferences/min on a $25/month virtual server, it is unlikely my customer will want to pay $500/month for the same throughput and 0.96 micro F1 using a fine-tuned huggingface BERTForClassification model.

In industry you might find you're using "old school" methods a lot more than you are new shiny models and in academia you might find that deeply understanding old models and new models helps you to unlock new ways to think about problems and model them like https://aclanthology.org/2020.acl-main.630.pdf by someone in my PhD cohort who found that combining "old school" LDA topic modelling with BERT contextual embeddings improved their model performance at semantic similarity detection.

- - -

Before transformers the CRFs (a graphical models that learns probabilistic transitions between inputs - similar to HMMs) was considered best in class for sequence classification tasks like NER and POS. I'd highly recommend the sklearn-crfsuite tutorial as a really nice accessible starting point for using CRF in a practical setting with a real NER corpus (CONLL 2002). If you'd like to know more about the theory behind CRF the original paper might be worth a read but I found it quite dense. this primer by Hannah Wallach is a pretty good summary of the key mechanisms at play.

https://sklearn-crfsuite.readthedocs.io/en/latest/tutorial.html
2001 https://repository.upenn.edu/cgi/viewcontent.cgi?article=1162&context=cis_papers
2004 https://people.cs.umass.edu/~wallach/technical_reports/wallach04conditional.pdf


SoTA NER performance was set by using an LSTM to encode your document and then passing the encoded sequence into a CRF. See here for one of the original papers and here for an example implementation in PyTorch.

2015 http://export.arxiv.org/pdf/1508.01991
https://pytorch.org/tutorials/beginner/nlp/advanced_tutorial.html

- - -

NER (let's say "token classification" for the general case, when you're just trying to label some set of tokens in your input text) can be very useful. Say you have a chatbot for cable customer support and you have a transcription like:

Reschedule my appointment on the 5th to 4:30 PM on the 12th.

In order to support automating rescheduling, you'd want to classify the utterance's intent (text classification) as well as understand specific tags.

You might label this as: reschedule_appointment for the class, and have tag labels like:

{"appointment_old_day": "5th", 
"appointment_new_day": "12th",
"appointment_new_time": "4:30 PM"}
This helps your bot 'parse out' details needed downstream.

I think that they're not seen as often for tutorials because text classification is easier to implement and understand (don't have to worry about CRF layers, worrying about matching up token offsets and subwords to per-word labels, etc.).

You can absolutely use transformer models with CRF layers for token classification. CRF layers make sense to include when there's usually some natural ordering, like maybe appointment_new_time entities often directly follow appointment_new_day entities in our dataset.


