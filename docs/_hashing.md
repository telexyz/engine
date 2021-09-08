## UMASH: a fast and universal enough hash
https://engineering.backtrace.io/2020-08-24-umash-fast-enough-almost-universal-fingerprinting

UMASH computes a 64-bit hash for short cached inputs of up to 64 bytes in 9-22 ns, and for longer ones at up to 22 GB/s, while guaranteeing that two distinct inputs of at most `s bytes` collide with probability less than `⌈s/2048⌉⋅2^−56`. If that’s not good enough, we can also reuse most of the parameters to compute two independent UMASH values.

The latency on short cached inputs (9-22 ns for 64 bits, 9-26 ns for 128) is somewhat worse than the state of the art for non-cryptographic hashes— wyhash achieves 8-15 ns and xxh3 8-12 ns—but still in the same ballpark. It also compares well with latency-optimised hash functions like `FNV-1a (5-86 ns)` and MurmurHash64A (7-23 ns).

