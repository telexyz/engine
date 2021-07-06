## https://www.zeta-alpha.com/post/news-research-and-code-in-ml-july-2021

https://github.com/speechbrain/speechbrain

https://github.com/sooftware/OpenSpeech

# Aran Komatsuzaki

https://twitter.com/arankomatsuzaki | https://www.reddit.com/user/Aran_Komatsuzaki

https://arankomatsuzaki.wordpress.com/about-me/



## Retrieval Resolves Many Limitations Other Approaches Suffer From
https://arxiv.org/pdf/2009.06857.pdf

retrieval-based models, such as Fusion-in-Decoder and MARGE, often substantially outperform the Transformer language models that either have a larger model size or spend more computes on various tasks, which implies that it is not only sufficient to scale up a model but also equip it with a retriever to improve the performance
of language model. 


efficient attention and recurrence have limited range of context both within the same sample and outside of it. However, retrieval can achieve indefinite context length within the same sample and the entire training dataset. For example, knn-LM achieves the state-of-the-art in Wikitext-103 for the amount of computes thanks to its context over the entire training dataset enabled by kNN search with FAISS.

Retrieval can also self-supervise few-shot learning of GPT-3 by feeding retrieved relevant samples. In fact, our proposed modified MARGE presented below trains the retriever that retrieves few-shot learning examples with the language model jointly, so that both components can benefit from the improvement of each other.

=>

https://www.parl.ai/docs/agent_refs/tfidf_retriever.html

https://www.parl.ai/docs/agent_refs/fid.html (Fusion in Decoder)

https://www.parl.ai/docs/agent_refs/rag.html (Retrieval-Augmented Generation)


=>

https://arxiv.org/pdf/1911.00172.pdf

https://github.com/urvashik/knnlm

https://nn.labml.ai/transformers/knn

=>

https://deepai.org/publication/bert-knn-adding-a-knn-search-component-to-pretrained-language-models-for-better-qa