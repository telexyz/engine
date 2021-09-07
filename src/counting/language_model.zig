// For 1..6-grams language model from `data/2{x}-grams.{bin|one|two}`
//
// * Let V = data/21-grams.bin
//
// * Absoluted Discount Smoothing + Stupid Backoff for the sake of Simplicity
//   See `docs/n-gram_smoothing.md` (Kneser-Ney is the best but require more
//   computation and the bigger the corpus is the nearer they are converged)

// Total Mem 501 MB
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// * 268 MB `BinaryFuseFilter`: 16-bits per key grams with count = 1
// *  30 MB `BinaryFuseFilter`: 16-bits per key grams with count = 2
// * 131 MB `HashCount234`: 7-bytes key represent + 2-byte count for 4,5,6-grams
// *  72 MB `HashCount234`: 6-bytes key represent + 3-byte count for 1,2,3-grams

// `../data/_train.txt` 655 MB
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// 1-gram U: 11119, U1: 1290, U2: 682, U3+: 9147, T: 102925305, M: 1150231
// 2-gram U: 2295455, U1: 955586, U2: 321666, U3+: 1018203, T: 120921879, M: 287825
// 3-gram U: 14469253, U1: 9243940, U2: 1934347, U3+: 3290966, T: 96074372, M: 98283
// 4-gram U: 29393263, U1: 22318488, U2: 3223949, U3+: 3850826, T: 74559148, M: 39369
// 5-gram U: 36248011, U1: 30184149, U2: 3156594, U3+: 2907268, T: 60262735, M: 33411
// 6-gram U: 35963796, U1: 31398771, U2: 2591882, U3+: 1973143, T: 49137138, M: 26376

// `../data/_train.txt.cdx` 428 MB
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// 1-gram U: 11119, U1: 1290, U2: 682, U3+: 9147, T: 102925305, M: 1150231
// 2-gram U: 2295456, U1: 955587, U2: 321666, U3+: 1018203, T: 120921876, M: 287825
// 3-gram U: 14469255, U1: 9243942, U2: 1934347, U3+: 3290966, T: 96074377, M: 98283
// 4-gram U: 29393265, U1: 22318490, U2: 3223949, U3+: 3850826, T: 74559150, M: 39369
// 5-gram U: 36248011, U1: 30184149, U2: 3156594, U3+: 2907268, T: 60262735, M: 33411
// 6-gram U: 35963796, U1: 31398771, U2: 2591882, U3+: 1973143, T: 49137138, M: 26376
