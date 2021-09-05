# N-gram Language Models
https://web.stanford.edu/~jurafsky/slp3/3.pdf
https://youtu.be/8BxqdxXT2M8

## smoothing, discounting

To keep a language model from assigning zero probability to these unseen events, we’ll have to shave off a bit of probability mass from some more frequent events and give it to the events we’ve never seen. This modification is called smoothing or discounting. In this section and the following ones we’ll introduce a variety of ways to do smoothing: `Laplace (add-one) smoothing`, `add-k smoothing`, `stupid backoff`, and `Kneser-Ney smoothing`.

## Backoff and Interpolation

If we are trying to compute `P(wn|w_n−2 w_n−1)` but we have no examples of a particular trigram `w_n−2 w_n−1 w_n`, we can instead estimate its probability by using the bigram probability `P(w_n|w_n−1)`. Similarly, if we don’t have counts to compute `P(w_n|w_n−1)`, we can look to the unigram `P(w_n)`.

In `backoff`, we use the trigram if the evidence is sufficient, otherwise we use the bigram, otherwise the unigram. In other words, we only “back off” to a lower-order n-gram if we have zero evidence for a higher-order n-gram. By contrast, in `interpolation`, we always mix the probability estimates from all the n-gram estimators, weighing and combining the trigram, bigram, and unigram counts.

## Kneser-Ney Smoothing

One of the most commonly used and best performing n-gram smoothing methods is the interpolated Kneser-Ney algorithm. Kneser-Ney has its roots in a method called `absolute discounting`. Recall that discounting of the counts for frequent n-grams is necessary to save some probability mass for the smoothing algorithm to distribute to the unseen n-grams.

To see this, we can use a clever idea from Church and Gale (1991). Consider an n-gram that has count 4. We need to discount this count by some amount. But how much should we discount it? Church and Gale’s clever idea was to look at a held-out corpus and just see what the count is for all those bigrams that had count 4 in the training set.

They computed a bigram grammar from 22 million words of AP newswire and then checked the counts of each of these bigrams in another 22 million words. On average, a bigram that occurred 4 times in the first 22 million words occurred 3.23 times in the next 22 million words. Fig. 3.8 from Church and Gale (1991) shows these counts for bigrams with c from 0 to 9.

Notice in Fig. 3.8 that except for the held-out counts for 0 and 1, all the other bigram counts in the held-out set could be estimated pretty well by just subtracting 0.75 from the count in the training set! Absolute discounting formalizes this intu- ition by subtracting a fixed (absolute) discount d from each count. The intuition is that since we have good estimates already for the very high counts, a small discount d won’t affect them much.

![](files/absolute_discount.png)
Note: P(W) cuối công thức là P(Wi); Với c=0 => 0 + interplated prob
d1  = 0.5
d2+ = 0.75


# https://www.marekrei.com/pub/Machine_Learning_for_Language_Modelling_-_lecture2.pdf
![](files/stupid_backoff.png)

# Towards Competitive N-gram Smoothing
http://proceedings.mlr.press/v108/falahatgar20a/falahatgar20a.pdf
