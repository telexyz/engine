https://github.com/Jingjing-NLP/VOLT/tree/master/POT

```sh
# cython and numpy need to be installed prior to installing POT
pip3 install numpy cython
pip3 install POT
```

- - -

## VOcabulary Learning via optimal Transport | https://arxiv.org/pdf/2012.15671.pdf

AN alternative understanding of the role of vocabulary from the perspective of information theory.

On WMT-14 English-German translation, VOLT only takes 30 GPU hours to find vocabularies, while the traditional BPE-Search solution takes 384 GPU hours.

### Algorithm 1: VOLT
```js
// Input: A sequence of token candidates L ranked by frequencies, an incremental 
// integer sequence S where the last item of S is less than |L|, 
// a character sequence C, a training corpus Dc
// Parameters: u ∈ R|C|+, v ∈ R|T|+
// Output v∗ from vocabularies satisfying Eq. 3
// 
vocabularies = []
for item in S do
// Begin of Sinkhorn algorithm Initialize u = ones() and v = ones()
T = L[:item]

Calculate token frequencies P(T) based on `Dc` 
Calculate char frequencies P(C) based on `Dc` Calculate D

while not converge do
	u = P(T)/Dv
	v = P(C)/D^Tu

optimal matrix = u.reshape(-1, 1) * D * v.reshape(1, -1)

// End of Sinkhorn algorithm
entropy, vocab = get vocab(optimal matrix) vocabularies.append(entropy,vocab)

```

Algorithm 1 lists the process of VOLT. First, we rank all token candidates according to their frequencies. For simplification, we adopt BPE- generated tokens (e.g. BPE-100K) as the token candidates. It is important to note that any seg- mentation algorithms can be used to initialize token candidates.

After generating the vocabulary, VOLT uses a greedy strategy to encode text similar to BPE. To encode text, it first splits sentences into character-level tokens. Then, we merge two consecutive to- kens into one token if the merged one is in the vocabulary. This process keeps running until no tokens can be merged. Out-of-vocabulary tokens will be split into smaller tokens.



- - -

Vocabularies Searched by VOLT are Better than Widely-used Vocabularies on Bilingual MT Settings. Ding et al. (2019) find that 30K-40K is the most popular range for the number of BPE merge actions.

VOLT for vi: 8.4k vocab vs BPE 30k vocab got the same accuracy. 

- - -

BPE-1K, recommended by Ding et al. (2019) for low-resource datasets.

Vocabularies Searched by VOLT are on Par with Heuristically-searched Vocabularies on Low-resource Datasets in terms of BLEU scores.

BPE-1K for vi is 1.4k vocab, VOLT is 8.4k vocab same as above setting.

Note that BPE-1K is selected based on plenty of experiments. In contrast, VOLT only requires one trials for evaluation and only takes 0.5 CPU hours plus 30 GPU hours to find the optimal vocabulary.


BPE WITH VOLT SIZE IS ALSO A GOOD CHOICE: VOLT Vocabularies and BPE Vocabularies are Highly Overlapped. For simplification, VOLT starts from BPE-segmented tokens. We take WMT En-De as an example to see the difference be- tween VOLT vocabulary and BPE vocabulary. The size of VOLT vocabulary is around 9K and we adopt BPE-9K vocabulary for comparison. We find that these two vocabularies are highly over- lapped, especially for those high-frequency words. They also have similar downstream performance. Therefore, from an empirical perspective, BPE WITH VOLT SIZE IS ALSO A GOOD CHOICE.

