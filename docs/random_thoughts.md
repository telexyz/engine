## https://smerity.com/articles/2017/baselines_need_love.html

Controversial claim: In deep learning, most models are overpowered for what they need to achieve. This leads to slower and more complex models, misleading human intuition and poisoning forward progress, especially when compared against sub-optimal baselines. When we lose accurate baselines, we lose our ability to accurately measure our progress over time. If there are only four things you take away from this article:

1/ Adopt a baseline and give it the care that it deserves

2/ Ensure the baseline is fast and well tuned to provide as a bed for rapid experimentation

3/ Take deliberate and reasoned steps foward towards the state of the art or more complex models

4/ Unless you have strong proof that it's necessary, don't sacrifice speed

IT'S BETTER TO USE COMPUTE WISELY THAN TO THROW MORE OF IT AT A PROBLEM.

Take an existing baseline or write it yourself, ENSURE IT REMAINS SIMPLE AND FAST. Then take this simple and fast baseline and push it as far as possible. This means tuning hyperparameters extensively, trying a variety of REGULARIZATION TECHNIQUES, SANITY CHECKING AGAINST BUGS AND POTENTIALLY FLAWED ASSUMPTIONS, and delving into the "boring" data processing in detail. All these are made possible due to the simplicity of your baseline.

From this, you can then inch foward towards more complex models. Add a component, one at a time, evaluate, and then keep it or remove it, always trying to maintain as fast and minimal a baseline as possible. The hope is you'll know what you're trading off.

 "In the current baseline state of the art model for word level language modeling on Penn Treebank and WikiText-2, the QRNN can achieve comparable results to the LSTM in a fraction of the time of even the most highly optimized of implementations"

 Fun https://github.com/francescodisalvo05/66DaysOfData

## https://smerity.com/articles/2018/limited_compute.html

Irrational courage is a skill worth cultivating. Why? It may be irrational in the face of the community yet entirely rational in reality. When I was at university neural networks themselves were dismissed as [insane, stupid, wasteful, fanciful, only capable of "local optimimums"] and should therefore be forgetten. Reality took a long time (and many courageous souls) before that perception was overturned. What else is left to discover on the discarded fringes of impossible adjacent?

For machine learning, history has shown compute and data advantages rarely matter in the long run. The ongoing trends indicate this will only become more true over time than less. YOU CAN STILL CONTRIBUTE TO THIS FIELD WITH LIMITED COMPUTE AND EVEN DATA. IT IS ESPECIALLY TRUE THAT YOU CAN GET ALMOST ALL THE ADVANCES OF THE FIELD WITH LIMITED COMPUTE AND DATA. THOSE LIMITS MAY EVEN BE TO YOUR ADVANTAGE.

Is this true for every application? No. Yet I genuinely believe it true in most cases.


### MORE EFFICIENT USAGE OF THE DATA

Before the new fangled neural language models or even the resurgence of the neural network era, my obsession was with n-grams. They're the simplest things in the world. Take N words - let's say these five words right here. That's a five-gram. Imagine seeing all the possible five-grams on earth.

Google released an n-gram dataset that was enormous at the time. 24 gigabytes compressed - oh geez! Solid state disks weren't a thing and RAM was, as ever, far too few, especially for holding a dataset of that size just for random access.

Today, with a tiny slither of the data used to produce n-grams or even store the original n-gram dataset, a single desktop computer can give you a richer representation in under an hour. How? MORE EFFICIENT USAGE OF THE DATA. That was the word2vec and eventually unsupervised language modeling path.



## Chasing a ball of linguistic yarn as it rolls around a thousand dimensional space
https://state.smerity.com/direct/smerity/state/01E9FX6EC43F6CPV1NNST6DGW8

Through the lens of this language model I can search for the emotional residue of great works distilled into phrases I would never have been able to explicitly search for. It's not the language model that's bringing us this knowledge, it's simply connecting threads of an intricate web that we've assembled both implicitly and explicitly over thousands of years, billions of observations, and a multitude of encoded emotions.

Language is humanity's longest running program, capturing, producing, mirroring, and explaining our thoughts, fears, hopes and warnings. Every phrase and every utterance, as long as it's echoed forward in time, helps build out that web. This has always been true throughout history but applies now more than ever.

Half a century ago the indexes in books were manually written. A quarter of a century ago search engines began to automate this index. Today language models burn through sequences of abstract symbols and, thanks to all the links and anchors left by humans across such a haphazard sequence, are starting to assemble an index along dimensions we'd never have been able to elucidate or comprehend before.

## SHA-RNN: Single Headed Attention RNN
https://arxiv.org/abs/1911.11423

The leading approaches in language modeling are all obsessed with TV shows of my youth - namely Transformers and Sesame Street. Transformers this, Transformers that, and over here a bonfire worth of GPU-TPU-neuromorphic wafer scale silicon. We opt for the lazy path of old and proven techniques with a fancy crypto inspired acronym: the Single Headed Attention RNN (SHA-RNN). The author's lone goal is to show that the entire field might have evolved a different direction if we had instead been obsessed with a slightly different acronym and slightly different result. We take a previously strong language model based only on boring LSTMs and get it to within a stone's throw of a stone's throw of state-of-the-art byte level language model results on enwik8. This work has undergone no intensive hyperparameter optimization and lived entirely on a commodity desktop machine that made the author's small studio apartment far too warm in the midst of a San Franciscan summer. The final results are achievable in plus or minus 24 hours on a single GPU as the author is impatient. The attention mechanism is also readily extended to large contexts with minimal computation. Take that Sesame Street.

https://github.com/alisafaya/SHA-RNN.jl
