# Apply

### 2nd try
https://github.com/hexops/xorfilter

`keys` phải biết từ trước, ko online update được :'(

https://lemire.me/blog/2019/12/19/xor-filters-faster-and-smaller-than-bloom-filters

Xor filters offer better accuracy for a given memory budget. With only 9 bits per entry, you can get a false positive probability much less than 1%.

### 1st try
https://raw.githubusercontent.com/kristoff-it/zig-cuckoofilter/master/src/cuckoofilter.zig => zig 0.5.0, outdated code, compile error


# Cuckoo Filter, Count-Min-Log, HyperLogLog

Cuckoo-Filter => Membership

Count-Min-Log => Frequency

HyperLogLog => `cardinality` "number of elements"

- - -

https://aras-p.info/blog/2016/08/09/More-Hash-Function-Tests

- - -

https://www.kdnuggets.com/2019/08/count-big-data-probabilistic-data-structures-algorithms.html

- - -

https://towardsdatascience.com/hashes-power-probabilistic-data-structures-d1398d1335c6

(**) In fact, I’m a huge proponent of designing your code around the data, rather
than the other way around, and I think it’s one of the reasons git has been fairly successful (**)

(**) I will, in fact, claim that the difference between a bad programmer
and a good one is whether he considers his code or his data structures
more important. Bad programmers worry about the code. Good programmers
worry about data structures and their relationships. (**)

PROBABILISTIC DATA STRUCTURES. They compromise precision with quite impressive resource requirements. If you’re solving a small problem where memory space isn’t limited, computation isn’t a bottleneck, and exact precision is a must, then you may think twice before using them. If that’s not the case, you should know their existence. Plus, they’re pretty fun to learn.

* They transform non-uniform distributed data into uniformly distributed which gives a starting point for probabilistic assumptions.

* Universal identity of data, which leads to automatic deduplication that helps in solving problems like count-distinct, if we design operations as idempotent.

- - -

https://dzone.com/articles/introduction-probabilistic-0

Probabilistic data structures are a group of data structures that are extremely useful for big data and streaming applications. Generally speaking, these data structures use hash functions to randomize and compactly represent a set of items. Collisions are ignored but errors can be well-controlled under certain threshold. Comparing with error-free approaches, these algorithms use much less memory and have constant query time. They usually support union and intersection operations and therefore can be easily parallelized.

- - -

## en.wikipedia.org/wiki/HyperLogLog

The new algorithm makes it possible to estimate cardinalities well beyond 10⁹ with a typical accuracy of 2% while using a memory of only 1.5 kilobytes.

## en.wikipedia.org/wiki/Cuckoo_filter


## en.wikipedia.org/wiki/Count–min_sketch

