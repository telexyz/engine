PROBLEM: Given a token as a KEY reTRIEval the corespoding value

EXTENSION: Think of is as database (record retrieval), documents (text retrieval), search engine ...

# Perfect-Hash, Trie, FST ...

https://github.com/Tessil/hat-trie

- - -

https://www.s-yata.jp/marisa-trie/docs/readme.en.html

```sh
git clone https://github.com/s-yata/marisa-trie.git
cd marisa-trie
autoreconf -i
./configure --enable-native-code
make
make install

marisa-build < keyset.txt > keyset.dic
marisa-lookup keyset.dic Marisa # 915465	Marisa
marisa-common-prefix-search keyset.dic USA
```

- - -

https://github.com/tlwg/libdatrie | https://linux.thai.net/~thep/datrie

`Trie` is abbreviated from "Re`trie`val".

Trie is an efficient indexing method. It is indeed also a kind of deterministic finite automaton (DFA).

The time needed to traverse from the root to the leaf is proportional to the length of the key. Therefore, it is usually MUCH FASTER than B-tree or any comparison-based indexing method in general cases. Its time complexity is comparable with hashing techniques.

In addition to the efficiency, trie also provides flexibility in searching for the closest path in case that the key is misspelled. For example, by skipping a certain character in the key while walking, we can fix the insertion kind of typo. By walking toward all the immediate children of one node without consuming a character from the key, we can fix the deletion typo, or even substitution typo if we just drop the key character that has no branch to go and descend to all the immediate children of the current node.

- - -

The tripple-array structure for implementing trie appears to be well defined, but is still not practical to keep in a single file. The next/check pool may be able to keep in a single array of integer couples, but the base array does not grow in parallel to the pool, and is therefore usually split.

To solve this problem, [Aoe1989] reduced the structure into two parallel arrays. In the double-array structure, the base and next are merged, resulting in only two parallel arrays, namely, base and check.


WITH THE TWO SEPARATE DATA STRUCTURES, DOUBLE-ARRAY BRANCHES AND SUFFIX-SPOOL TAIL, KEY INSERTION AND DELETION ALGORITHMS MUST BE MODIFIED ACCORDINGLY.