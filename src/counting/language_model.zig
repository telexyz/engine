// 1..6-grams language model from `data/2{x}-grams.cdx`
// * V = data/21-grams.cdx
// * Laplace or add-one smoothing
// * `Quantization`: store probabilities in 16-bits rather than 32 bit float.
// * `BinaryFuseFilter`: 16-bits per key n-gram count lookup
// * Testing: Stupid backoff vs modified Kneser-Ney

// 32-bits per lookup table entry
// try binaryFuseTest(u32, 1_000_000, 4522040);
