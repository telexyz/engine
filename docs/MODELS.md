# eleuther.ai GPT-J-6B

https://www.reddit.com/r/MachineLearning/comments/nvkowg/p_gptj_6b_jaxbased_transformer_lm

Ben and I have released GPT-J, 6B JAX-based Transformer LM!

- Performs on par with 6.7B GPT-3

- Performs BETTER and decodes FASTER than GPT-Neo

- repo + colab + free web demo

- Trained on _400B tokens_ with TPU v3-256 for _five weeks_

- GPT-J performs much closer to GPT-3 of similar size than GPT-Neo

Bắt buộc phải dùng TPU của Google mới đủ nhanh. Nếu xài 1000 GPUs (cạc đồ họa) thì mất 20 tháng mới huấn luyện xong mô hình. Dùng TPU mất 5 tuần thôi.

https://www.reddit.com/r/MachineLearning/comments/oe6paj/d_gptj_for_text_generation_hardware_requirements/

mô hình https://6b.eleuther.ai chạy được trên PC nhé nhưng cần 40GB ram. Với 12 CPUs, mất 15 giây mới sinh ra được 50 từ :D

We tested it extensively at NLPCloud.io and the results for text generation are impressive.The hardware requirements are insane though...

At least 40GB to load it in memory + 12 CPUs in typical cases. Latency is quite high, even on a GPU. And actually even having it run on a GPU is hard because most affordable GPUs for inference only have 16GB of memory, which is not enough for GPT-J...

https://github.com/arrmansa/Basic-UI-for-GPT-J-6B-with-low-vram


https://cloud.google.com/blog/products/compute/introducing-cloud-tpu-vms

Ben Wang is an independent researcher who works on Transformer-based models for language and multimodal applications. He has published open-source code for training large-scale transformers on Cloud TPU VMs and for orchestrating training over several Cloud TPU VMs with Ray.

“JAX on Cloud TPU VMs enables high-performance direct access to TPUs along with the flexibility to build unconventional training setups, such as pipeline parallel training across preemptible TPU pod slices using Ray."— Ben Wang

Keno Fischer is a core developer of the Julia programming language and co-founder of Julia Computing, where he leads a team applying machine learning to scientific modeling and simulation. He is the author of significant parts of the Julia compiler, including Julia’s original TPU backend.

“The new TPU VM offering is a massive step forward for the usability of TPUs on the cloud. By being able to take direct advantage of the TPU hardware, we are no longer limited by the bandwidth and latency constraints of an intermediate network connection. This is of critical importance in our work where machine learning models are often directly coupled to scientific simulations running on the host machine.” — Keno Fischer 

Cloud TPU VMs are now available via preview in the us-central1 and europe-west4 regions. You can use single Cloud TPU devices as well as Cloud TPU Pod slices, and you can choose TPU v2 or TPU v3 accelerator hardware. Cloud TPU VMs are available for as little as $1.35 per hour per TPU host machine with our preemptible offerings. You can find additional pricing information here.


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