// 1..6-grams language model from `data/2{x}-grams.cdx`
// * V = data/21-grams.cdx
// * Laplace or add-one smoothing
// * `Quantization`: store probabilities in 8..16-bits rather than 32 bit float.
// * `BinaryFuseFilter`: 16-bits per key n-gram pre-filter
// * Testing: Stupid backoff vs modified Kneser-Ney

// try binaryFuseTest(u16, 111_000_000, 249_823_288); => bits per entry 18
// => ~240MB

// HashProb 2^27 items, each 64-bit KeyRepresent + 16-bit float => 10-bytes
// => ~1.3Gb (134_217_728 x 10 / (1024 x 1024))
