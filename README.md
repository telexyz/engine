## Vietnamese Telex Input Method and Everything Related

## Cải tiến bộ gõ telex

[ IMPORTANT ] Yếu điểm có thể coi là lớn nhất của Telex là viết song ngữ rất chậm,
vì hay bị hiểu lầm thành dấu mũ. Việc chuyển bàn phím thì cũng rất mất thời gian !!!

[ QUESTION ] Làm thế nào để giảm thiểu sự nhầm lẫn khi gõ tiếng Anh lẫn lộn với tiếng Việt ???

[ Gõ Tiếng Việt MacOS ]
https://github.com/lamquangminh/EVKey
https://github.com/tuyenvm/OpenKey 


## Code a text tokenizer / a text processor

[ >>> HERE I SHOULD BE, DOWN THE RABBIT HOLE <<< ]

### TexTok: A text tokenizer

+ Input: Text files

+ Output: Xem `documents/encoding.md`. OOVs are encoded later using BPE.

Xem `01-TKNZ.md` (xong phrase-1).

[ >>> DONE <<< ]

TO-TEST: convert syllable to various format and valid them with telex parser.

Hiện tại với mỗi char đầu vào phải switch 3 lần, lần 1 phân biệt kiểu char, lần 2, convert từ utf-8 về ascii-telex, lần 3 xem nó là viết hoa hay thường => viết 1 hàm trung lập thống nhất 3 lần switch này về làm 1.

=> 11.8% faster (182182 ms / 206351 ms)

https://leimao.github.io/blog/Byte-Pair-Encoding/

In information theory, byte pair encoding (BPE) or diagram coding is a simple form of data compression in which the most common pair of consecutive bytes of data is replaced with a byte that does not occur within that data. On Wikipedia, there is a very good example of using BPE on a single string. It was also employed in natural language processing models, such as Transformer (trained on standard WMT 2014 English-German dataset) and GPT-2, to tokenize word sequences.

BPE in used https://github.com/google/sentencepiece

> “Sentencepiece, a language-independent subword tokenizer and detokenizer designed for Neural-based text processing” — SentencePiece Paper


#### What the diff between Trie and Transducer?
https://blog.burntsushi.net/transducers

Trie only reuse prefix and have unique ending nodes. So we can assign an unique id number to each end node that mapping 1-1 with a word in dictionary.

Trie is a prefix tree, which requires a common prefix. This makes it suitable for autocomplete or search suggestions. If you need a very fast auto-complete then try my Pruning Radix Trie. https://github.com/wolfgarbe/PruningRadixTrie

Transducers reuse bot prefix and suffix so it smaller than Trie interm of memory but more complicated to implement and can not mapping 1-1 between ending nodes and words.

## [ Telex Engine ] Real-Data Tokenizer / Parser Enhancement

Study and apply techniques, espcically iterators, at https://github.com/ziglang/zig/blob/master/lib/std/mem.zig to improve `real_data_v0.zig`

`real_data_v1.zig` code is more neat than `real_data_v0.zig` but suprisingly run much slower than `v0`, 1.41 times slower (314495 ms (5.24 mins) / 222653 ms (3.71 mins)).

`v0` is a naive implementation, with no interator, no outside function call ...

combine speed of `v0` and coding struct of `v1` to create `v2` that has speed of `v0` but easier to read and extend like `v1`

Final: `real_data_v2.zig` keep naive loop from `v0` and struct from `v1` and remove ad-hoc second try. Result: Simpler and 10% faster 200035 ms (3.33 mins)

=> Speed = 9.6m lines / 200035 ms = 48 lines per ms.
=> Speed = 578mb / 200035 ms = 2.96kb per ms.

CONCLUSION: Always prefer simple solution. Always avoid adhoc / clever solution !!!

## [ Telex Engine ] New insights / improvements II

+ `data/_syllables.txt` contains recognized syllables
+ `data/_oov.txt` contains oov words without second try

While looking at oov.txt (out-of-vocabulary), found a reasonable amount of word that composed of two valid vietnamese syllables:
đăngký Đăngơ ĐĩaThan đơngiá đơnphải đưalao đưatin đưaTrung đưaTết đườngkỳ đườngphục Đượ đượ đượcca đượcdùng đượcgiao đượcgiải đượcnha đạophòng đạoTPHCM đạoVịnh đạođối Đạtlai Đảngcho ĐảoCôn 

=> Try to parse them using concat more-than-one-syllable without separator. In other words, just parse input char stream untill the output syllable is saturated then add a new empty syllable to continue parsing ...

### RESULTS

+ `data/_syllables1.txt` contains double-syllable words
+ `data/_oov1.txt` contains oov words after apply second try

Try: "MẹHàMy" => "MẹHàM|y" => true
Try: "Mẹnuôi" => "Mẹn|uôi" => true
Try: "NgheNh|ìn" => true
	=> Bài toán dính từ như trên dùng bi/tri-syllable xử lý đơn giản hơn nhiều !!!
	VD: "phò|nghơn" vs "phòng|hơn", "Chư|ong" vs "Chương" phải dùng từ điển hoặc gram mới xử lý dc!

Try: "Môn|trêan" => false
Try: "Môn|tênêgrô" => false

Try: "Môn|ôlôxốp" => "Mô|nô|lô|xốp" 
	=> cần ưu tiên phân bô âm đầu trong trường hợp phiên âm tiếng nước ngoài

Try: "môn|ôxit" => false
Try: "Môn|đôva" => false
Try: "Mô|rava" => false

Try: "Mô|ritani" => "Mô|ri|tani" => "Mô|ri|ta|ni" 
	=> Cần hàm parser hồi quy để bóc tách liên tục cho tới khi hết chuỗi

ủnghộ => ủ|nghộ <= first_successed_at
ủnghộ => ủng|hộ <= last_successed_at


## [ Telex Engine ] Performance Test

We tested the improvment agaist 578Mb of Vietnamese online article titles. Beside performance test. We will detect syllable that is not recognized by the telex-engine and list it to a separate file to study later. Un-recognized syllables could be foreign-words, abbreviations, very-old-rare-used syllables, and other exceptions.

Result: 578mb of text, 9.6m lines of article titles. Run in around 3-minutes, got 138k oov.

[LATER] since it may take 1.5-2 hours to run (3 min x 33 = 99 mins)
Exciting to see telex-engine works agaist really big data. After we pass 578Mb article-title-text, we can test telex-engine agaist 19.9Gb (x33) of full-content article-text.


## [ Telex Engine ] New insights / improvements

Batch processing is finished:
+ Step 1: utf-8 => utf8ToAsciiTelex() => ascii-telex
+ Step 2: ascii-telex => parseAmTietToGetSyllable() => Syllable struct

The code run very fast and was tested agaist around 6600 (popular / conventional) Vietnamese syllables. Now it's time to make the engine more flexible and speed-it-up!

Re-built telex parser using state machine, feeded character by character (per keystroke), that parse both utf-8 and ascii-telex format, both lower case and upper case ...

The state-machine always waiting for more token (any character) until it reach it's final state (not Vietnamese character) then it will be reseted to initial state. Waiting for the new syllable to come ...

[ LATER ] By process char / keystroke one-by-one, it can UNDO recent-steps (when the user press backspace key for example) very fast by saving internal trail (e.g now reach amGiua step-2, go back -1 to amGiua step-1, or go back -2 to amDau step-2 ...).

By combine utf-8 format and ascii-telex format and convert it to state-machine, we can speed it up by by-passing the utf8ToAsciiTelex() processor and don't have to feed the whole syllable everytime.

## UTF-8 & upcase / downcase handling
https://github.com/JakubSzark/zig-string/blob/master/zig-string.zig


[ LATER ] Normally, upcase only the first char of the syllable so need one more bit to record it. 17-bits => 18-bits. Later when we need to decode / un-compressed the real input syllable from it compact-representation then we do it!

### Test agaist vn dictionary

Around 6600 syllables passed. Can use trie or FSM to store them as a dictionary to lookup for true Vietnamese syllable. Can use isVietmese() instead of canBeVietnamese().


Telex module now assume that input strings are all in downcase and ascii-telex.

Ascii-telex: mimic the input key stream when user typing Vietnamese using an A-Z physical or virtual keyboard (QWERTY for example). With some stricker rules when typing telex:

- Mark char must follow the main char closely
	VD: uwow => ươ, uow => uơ, uonw => uonw

- Tone char must be at the end of syllable
	VD: nons => nón, nosn => nosn


Add UTF-8 handling will give telex module the power to process raw utf-8 string (no need an outside converter to convert utf-8 to ascii-telex. VD: người => nguwowif), and convert ascii-telex back to utf-8. VD: nguwowif => người.

## Native build / perf / test and node.js wasm build / test

```sh
./run.sh
```

## Browser js vs wasm perf comparision

```sh
./local-server.sh
open index.html
```

## Perf notes

Native 
	100000 x 6 fn calls took 63 ms

Browser js implementation
	100000 x 6 fn calls took 1937 ms

Browser inside wasm
	100000 x 6 fn calls took 286 ms

Browser js call wasm
	100000 x 6 fn calls took 4040000 ms


=> Bottle neck is calling wasm function from js and waiting for result!

=> wasm is around 10x faster than js

=> native is around 3x faster then wasm
# telex-engine
