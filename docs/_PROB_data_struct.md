# Cuckoo Filter, Count-Min-Log, HyperLogLog

## Cuckoo-Filter => Membership

### 2nd try
https://github.com/hexops/xorfilter

`keys` phải biết từ trước, ko online update được :'(

https://lemire.me/blog/2019/12/19/xor-filters-faster-and-smaller-than-bloom-filters

Xor filters offer better accuracy for a given memory budget. With only 9 bits per entry, you can get a false positive probability much less than 1%.

### 1st try
https://raw.githubusercontent.com/kristoff-it/zig-cuckoofilter/master/src/cuckoofilter.zig => zig 0.5.0, outdated code, compile error

## Count-Min-Log => Frequency
https://github.com/seiflotfy/count-min-log/blob/master/log.go
https://github.com/barrust/count-min-sketch

## HyperLogLog => `cardinality` "number of elements" (no-use)

- - -

https://github.com/ziglang/gotta-go-fast/blob/master/benchmarks/self-hosted-parser/input_dir/bloom_filter.zig


- - -

https://highlyscalable.wordpress.com/2012/05/01/probabilistic-structures-web-analytics-data-mining/

Frequency Estimation: Count-Min Sketch

Let’s focus on the following problem statement: there is a set of values with duplicates, it is required to estimate frequency (a number of duplicates) for each value. Estimations for relatively rare values can be imprecise, but frequent values and their absolute frequencies should be determined accurately.


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
