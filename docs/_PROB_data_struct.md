https://towardsdatascience.com/hashes-power-probabilistic-data-structures-d1398d1335c6

(**) In fact, I’m a huge proponent of designing your code around the data, rather
than the other way around, and I think it’s one of the reasons git has been fairly successful (**)

(**) I will, in fact, claim that the difference between a bad programmer
and a good one is whether he considers his code or his data structures
more important. Bad programmers worry about the code. Good programmers
worry about data structures and their relationships. (**)

PROBABILISTIC DATA STRUCTURES. They compromise precision with quite impressive resource requirements. If you’re solving a small problem where memory space isn’t limited, computation isn’t a bottleneck, and exact precision is a must, then you may think twice before using them. If that’s not the case, you should know their existence. Plus, they’re pretty fun to learn.

Bloom filters can produce false positives, but not false negatives.

Count-Min-Log sketch: Approximately counting with approximate counters
https://arxiv.org/pdf/1502.04885

