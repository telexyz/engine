## Choosen an indexing technique: Inverted Index

We've successfully mapping any Vietnamese syllable and it's variants to it's u17 (17-bits) unique-id or compact re-presentation.

Now we need to choose one (or two?) indexing technique that simple to implement but effective to use (small data but fast & accurate).

[ LATER ] Skip exploring to concentrate on the tokenizer first. There is no use to study this if there is no tokens to process. After finishing and polishing the tokenizer we will come back here to dig deeper into both Tantivy and PISA.

https://github.com/tantivy-search
A lot of sub projects that contain code examples of fst, string distance compare, bitpacking ... that corely related to FTS.

https://github.com/ot/ds2i
Origin if PISA. Code should be small, concise & straight forward.

### PISA: Performant Indexes and Search for Academia

=> Learn from the fastest search engine https://github.com/pisa-engine/pisa

In very simple terms, PISA is a text search engine. Starting with a corpus of documents, for example, Wikipedia, PISA can build an inverted index which allows us to rapidly search the Wikipedia collection. At the most basic level, Boolean AND and OR queries are supported. Imagine we wanted to find all of the Wikipedia documents matching the query "oolong tea" - we could run a Boolean conjunction (oolong AND tea). We might instead be interested in finding documents containing either oolong or tea (or both), in which case we can run a Boolean disjunction (oolong OR tea).

Beyond simple Boolean matching, as discussed above, we can actually rank documents. Without going into details, documents are ranked by functions that assume the more rare a term is, the more important the word is. These rankers also assume that the more often a word appears in a document, the more likely the document is to be about that word. Finally, longer documents contain more words, and are therefore more likely to get higher scores than shorter documents, so normalization is conducted to ensure all documents are treated equally. The interested reader may wish to examine the TF/IDF Wikipedia article to learn more about this method of ranking.


    1) Many index compression methods implemented;
    2) Many query processing algorithms implemented;
    3) Implementation of document reordering;

1) https://pisa.readthedocs.io/en/latest/compress_index.html

1.1) https://github.com/pisa-engine/mln

3) https://pisa.readthedocs.io/en/latest/document_reordering.html
The point of doing it is usually to decrease the index size or speed up query processing. This part is done on an uncompressed inverted index.


3.1) https://arxiv.org/pdf/1602.08820.pdf 

Recursive Graph Bisection (aka BP) algorithm: the state-of-the-art for minimizing the compressed space used by an inverted index (or graph) through document reordering.

The algorithm tries to minimize an objective function directly related to the number of bits needed to store a graph or an index using a delta-encoding scheme.

> the experiment indicates that BP outperforms Natural by around 50% and outperforms Minhash by around 30%

> While our primary motivation is compression, graph reordering plays an important role in a number of applications. In particular, various graph traversal algorithms can be accelerated if the inmemory graph layout takes advantage of the cache architecture. Improving vertex and edge locality is important for fast node/link access operations, and thus can be beneficial for generic graph algorithms and applications 

=> Dig deeper into Minhash vs BP ...


## Prefix fast-matching / indexing to support searching while you typing

For small text chunks like filename, urls, quotes, even paragraph, prefix indexing and (fast) searching is quite useful. By breaking any Vietnamese Syllable into 4 parts and encoding them indiviually: first-part (5-bits), middle-part (5-bits), last-part (4-bits), tone (3-bits) that mimic the user behavior when they typing a Vietnamese syllable using strick-telex method (explained below) on a alphabet keyboard, we can make use of them to present prefix in a compact and meaningfull way.

Now the documents is indexed using an inverted index that map tri-syllable into documents contains that tri-syllable. Each tri-syllable is re-presented by an u64. Prefix matching mean search for 1st-syllable with am dau is 0x10101, and am_giua is 0x11011 mean seaching for:

`0x10101_11011_????_??? 0x?????_?????_????_??? 0x?????_?????_????_???` 
`?: both 0 and 1 is ok`

Luckily the tri-syllable are sorted, and by re-define the compare fn to take into account of first ten bits only, we can apply range search to find out matched all tri-syllable.

https://afteracademy.com/blog/search-for-a-range-in-sorted-array


n-syllable variations below with no-tone variation is a prefix (without-tone) indexing already. And prefix is a sub-set of variant in general. We just need to dig the concept deeper. May be we can use a common ground / comment root to re-present all of them.

[ COOL USE-CASE ] shortcut-typing, e.g you can type only the first char of each syllable and let the system guesting which word / phrase (n-syllable) you have in your head. If we can do it nicely, in both data-tructure / alogrithm and user-interaction, it will be a KILLER feature for our Vietnamese keyboard and text seaching app !!!


## Mono/Bi/Tri-syllable variations and scoring

[ syllable >> syllableNoMark >> syllableNoMarkNoTone ]

```
s0  s0-  s0=
s1  s1-  s1=
s2  s2-  s2=

3 ^ 3 = 27 tri-syllable combinations
point = 0..-6

3 ^ 2 = 9 bi-syllable combinations
point = 0..-4
```

[ QUESTION ] How to select a subset of combinations that balance between coverage (bigger, better) & performance (smaller, faster)?

[ SOLUTION 1 ] Make a straight selection:

```
s0  s1  s2   99/1 points
s0  s1  s2-  99/2
s0  s1- s2-  99/3
s0  s1- s2=  99/4
s0  s1= s2=  99/5
s0- s1- s2-  99/6 points
s0- s1- s2=  99/7
s0- s1= s2=  99/8
s0= s1= s2=  99/9 points


s0  s1   35/1 points
s0  s1-  35/2
s0  s1=  35/2.5
s0- s1-  35/4 points
s0- s1=  35/6
s0= s1=  35/9 points

s0   10/1 points
s0-  10/2 points
s0=  10/4 points
```