Validating UTF-8 In Less Than One Instruction Per Byte
https://arxiv.org/pdf/2010.03090.pdf

Validation is not a straightforward problem. UTF-8 uses between 1 and 4 bytes to encode each character, and there are many distinct error cases to check. In our experience, most systems validate UTF-8 using relatively complicated sequences of branches. The speed of a branch-based approach depends on the input. We can exceed speeds of 2 GiB/s, going as fast as 4 GiB/s on ASCII content.

Though such speeds may seem satisfactory, recent disks can sustain higher throughput (e.g., 5 GiB/s) with networking speeds being even higher. Generic compression libraries such as LZ4 can decompress text data at 5 GiB/s [3]. An engineer behind the high-performance ScyllaDB database system [4] concluded that UTF-8 validation can become a bottleneck under heavy loads [5].

![](files/utf8_bytes.png)

SIMD

tieng|zs viet|zj nam|