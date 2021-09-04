// 1..6-grams language model from `data/2{x}-grams.cdx`
// * V = data/21-grams.cdx
// * Laplace or add-one smoothing
// * `Quantization`: store probabilities in 8..16-bits rather than 32 bit float.
// * `BinaryFuseFilter`: 32-bits per key n-gram count lookup
// * Testing: Stupid backoff vs modified Kneser-Ney

// try binaryFuseTest(u32, 1_000_000, 4_522_040); => bits per entry 36.2
// 48-bits (32+16) storage => 54.3 bits per entry (48 x 36.2 / 32)
// 68% storage compare to hash_count (80-bits per entry)
// => ~900 MB of RAM (68% x 1.3Gb)
