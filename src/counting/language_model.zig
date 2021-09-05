// For 1..6-grams language model from `data/2{x}-grams.{bin|one|two}`
//
// * Let V = data/21-grams.bin
//
// * Absoluted Discount Smoothing + Stupid Backoff for the sake of Simplicity
//   See `docs/n-gram_smoothing.md` (Kneser-Ney is the best but require more
//   computation and the bigger the corpus is the nearer they are converged)

// Total Mem 501 MB
//
// * 268 MB `BinaryFuseFilter`: 16-bits per key grams with count = 1
// *  30 MB `BinaryFuseFilter`: 16-bits per key grams with count = 2
//
// * 131 MB `HashCount234`: 7-bytes key represent + 2-byte count for 4,5,6-grams
// *  72 MB `HashCount234`: 6-bytes key represent + 3-byte count for 1,2,3-grams
