## UMASH: a fast and universal enough hash
https://engineering.backtrace.io/2020-08-24-umash-fast-enough-almost-universal-fingerprinting

UMASH computes a 64-bit hash for short cached inputs of up to 64 bytes in 9-22 ns, and for longer ones at up to 22 GB/s, while guaranteeing that two distinct inputs of at most `s bytes` collide with probability less than `⌈s/2048⌉⋅2^−56`. If that’s not good enough, we can also reuse most of the parameters to compute two independent UMASH values.

The latency on short cached inputs (9-22 ns for 64 bits, 9-26 ns for 128) is somewhat worse than the state of the art for non-cryptographic hashes— wyhash achieves 8-15 ns and xxh3 8-12 ns—but still in the same ballpark. It also compares well with latency-optimised hash functions like `FNV-1a (5-86 ns)` and MurmurHash64A (7-23 ns).


## Fast strongly universal 64-bit hashing everywhere!
https://lemire.me/blog/2018/08/15/fast-strongly-universal-64-bit-hashing-everywhere

https://github.com/lemire/Code-used-on-Daniel-Lemire-s-blog/blob/master/2018/08/15/src/main/java/me/lemire/microbenchmarks/algorithms/HashFast.java

```java
  static long a1 = 0x65d200ce55b19ad8L;
  static long b1 = 0x4f2162926e40c299L;
  static long c1 = 0x162dd799029970f8L;
  static long a2 = 0x68b665e6872bd1f4L;
  static long b2 = 0xb6cfcf9d79b51db2L;
  static long c2 = 0x7a2b92ae912898c2L;

  static int hash32_1(long x) {
    int low = (int)x;
    int high = (int)(x >>> 32);
    return (int)((a1 * low + b1 * high + c1) >>> 32);
  }
  static int hash32_2(long x) {
    int low = (int)x;
    int high = (int)(x >>> 32);
    return (int)((a2 * low + b2 * high + c2) >>> 32);
  }
  static long hash64(long x) {
      int low = (int)x;
      int high = (int)(x >>> 32);
      return ((a1 * low + b1 * high + c1) >>> 32)
        | ((a2 * low + b2 * high + c2) & 0xFFFFFFFF00000000L);
  } 
```
This bit-mixing function is “obviously” faster. It has half the number of multiplications, and none of the additions. However, in my tests, the difference is less than you might expect (only about 50%). Moreover if you do need two 32-bit hash values, the 64-bit mixing function loses much of its edge and is only about 25% faster.


## xxHash
http://cyan4973.github.io/xxHash
https://github.com/The-King-of-Toasters/zig-xxhash

