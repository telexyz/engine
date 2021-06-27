## Notes on terms

`syllable`: token là âm tiết tiếng Việt hoàn chỉnh

`marktone`: token ko là âm tiết tiếng Việt, chỉ chứa ký tự trong bảng chữ cái tiếng Việt và phải có ký tự mang dấu hoặc thanh (khả năng cao là tiếng Việt lỗi chính tả, từ vay mượn ...)

`alphabet`: token ko là âm tiết tiếng Việt, chỉ chứa ký tự a-zA-Z (phần nhiều là từ nước ngoài)

`nonalpha`: token không chứa ký tự nào trong bảng chữ cái tiếng Việt
`nonalpha` có thể phân nhỏ hơn thành: 
* `digits`: 12  54  34.5  44,56
* `units`: %, $
* `phrase_breakers`: , ; : ! ? .
* ...

### Conclusion

To avoid confusion we agree to follow below rules on using-terms for the whole project:

1/ Vietnamese `syllable` is fisrt-class citizen since it's the foundation unit of both Vietnamese spoken and written language: 

    + It's structure is well defined, and can encode using 17-bits only.

    + It can be converted (two-way) to various form: no-mark, no-tone, no-mark-no-tone, telex, abbreviation VD: `không` <~=> khong, ko, k0, k; `những` <~=> nhũng, nhưngx, nhungx, nhung, nx.

Thông số tiếng Việt lấy từ Vietnam Lexicography Center (Vietlex)
    - Số từ 40181 (được sử dụng nhiều nhất)
    - Số âm tiết 7729
    - 81.55% các âm tiết đồng thời là các từ đơn.
    - 70.72% các từ ghép có 2 âm tiết.
    - 13.59% các từ ghép có 3,4 âm tiết.
    - 01.04% các từ ghép có từ 5 âm tiết trở lên.


    + ...

2/ Use `n-syllable` instead of 'n-gram' since here we apply it to `Vietnamese syllables` only! => Not confuse what 'n-gram' means? is it word?, sub-word or anything else?

3/ Use `bi,tri-syllable` (or `2,3-syllable`) to re-present `vietnamese words` since a Vietnamese word should be a combination of Vietnamese syllables. Except borrow words, name-entities, từ viết tắt (HĐND, CHXH) ... will be encoded using dictionary, in this case we call them `word`

4/ A `token` is an output of an `tokenizer`. So depend on the `tokenizer`  should be a `syllable`, or a `word`, that can be looked up in the dictionary, a specific `format` like numbers, money `124, $100m, $200, 1,500đ` and finally a `oov` (out-of-vocabulary).

Note that there are `terms` that can be broken into `tokens`: `đ/kg   30/10/2015   30-12-2020   3/4   bệnh/giường   trước/sau   ngày26-4-2016   Sơn-Tân   đen-trắng`. Sometime it's just a notation `ĐNa-90152, Dương-981` (biển số xe, tên riêng ...) that can be broken into `tokens` too.

=> Prefer syllable `token` or sub-word `token` (in Vietnamese syllables are sub-words)! 
In this case, delimimters between `tokens` are really matter and should be taken into account. They SEPARATE or GLUE `tokens` ...

```js
"đ/kg" <= token`/`token``
"30/10/2015" <= digits`/`digits`/`digits``
"ngày26-4-2016" <= syllable``digits`-`digit`-`digits``
"đường 3/4" <= syllable` `digit`/`digit`` // name-entity
"Sơn-Tân" <= syllable`-`syllable`` // name-entity
"đen-trắng" <= syllable`-`syllable``
```

### Definition

`define:term`
+ a word or phrase used to describe a thing or to express a concept, especially in a particular kind of language or branch of study.

`define:token`
+ a thing serving as a visible or tangible representation of a fact, quality, feeling, ...
+ Tokens are the building blocks of Natural Language.

>> Tokens are the building blocks of Natural Language.
https://www.analyticsvidhya.com/blog/2020/05/what-is-tokenization-nlp/

Tokenization is a way of separating a piece of text into smaller units called tokens. Here, tokens can be either words, characters, or subwords. Hence, tokenization can be broadly classified into 3 types – word, character, and subword (n-gram characters) tokenization.

For example, consider the sentence: “Never give up”.

The most common way of forming tokens is based on space. Assuming space as a delimiter, the tokenization of the sentence results in 3 tokens – Never-give-up. As each token is a word, it becomes an example of Word tokenization.

Similarly, tokens can be either characters or subwords. For example, let us consider “smarter”:

Character tokens: s-m-a-r-t-e-r
Subword tokens: smart-er

>> Creating Vocabulary is the ultimate goal of Tokenization.

Transformed based models – the SOTA in NLP – rely on Subword Tokenization algorithms for preparing vocabulary. One of the most popular Subword Tokenization algorithm known as Byte Pair Encoding (BPE) that tackles OOV effectively.

Byte Pair Encoding (BPE) is a widely used tokenization method among transformer-based models. BPE addresses the issues of Word and Character Tokenizers:

+ BPE tackles OOV effectively. It segments OOV as subwords and represents the word in terms of these subwords

+ BPE is a word segmentation algorithm that merges the most frequently occurring character or character sequences iteratively. Here is a step by step guide to learn BPE.

Steps to learn BPE:
    1/ Split the words in the corpus into characters after appending </w>
    2/ Initialize the vocabulary with unique characters in the corpus
    3/ Compute the frequency of a pair of characters or character sequences in corpus
    4/ Merge the most frequent pair in corpus
    5/ Save the best pair to the vocabulary
    6/ Repeat steps 3 to 5 for a certain number of iterations

>> At test time, the OOV word is split into sequences of characters. Then the learned operations are applied to merge the characters into larger known symbols.
    - Neural Machine Translation of Rare Words with Subword Units, 2016


`define:n-gram`
https://vi.wikipedia.org/wiki/N-gram

n-gram là một chuỗi tiếp giáp của n phần tử từ một mẫu văn bản hay lời nói cho trước. Các phần tử có thể là âm vị, âm tiết, chữ cái, từ hoặc các cặp cơ sở (base pairs) tùy theo ứng dụng.

### Explantation

We've used alot of terms (search) `terms`, `keywords`; `words`, `syllables`, `tokens`, `terms`, `n-gram`, `n-syllable` some of them are interchangable and in some special context they are the same thing. So how to standardize those terms?

+ a `token` is sequent of chars that may contain  meaningful information.  

    + We don't want to miss any useful information so we just keep as much tokens as possible, and only REMOVE the unmeaningful things WE-KNOW-FOR-SURE (junks typed by random keystrokes ldfkk, kkekeo, cvpcvpvke, ...) or WE-ARE-100%-SURE-THAT-IT-IS-UNABLE-TO-RECOGNIZE (encrypted chars that only can decrypted if we know the key or the password)

    + Note: encoding error like this "MÃ¡txcÆ¡va cafÃ© thÃ¢t NSÆ¯T NiÃª BeyoncÃ© ..." should be recovered by trying difference encoder / decoder ...

    + We SPLIT input text into a stream of `tokens` and try to extract as much useful information as we can from them. For example, trying to RECOVER a miss-spelled-word or typo (alot: câc, bầt, lượngTitan ...); NORMALIZE regional differencies (ăn rồi vs ăn gòi, tui vs tôi), gernerational differencies (zui vs vui vs dzui) ...

+ a `word`, as in an English words, is a `token` that can lookup for meaning in a dictionary. In other way, `word` is a very sure meaningful `token` that is warranted by a LOOKUP method. We can LOOKUP the meaning of a `word` everytime we want.

+ a `syllable` is a Vietnamese unit-of-spoken-language in written format. A `syllable` alone should always have meaning so it a `word` too. But normally 2,3, or 4 of `syllables` are formed together to create a specific meaning considered as a word in English. For example: school = trường_học (`2-syllable word`), go to school = tới trường (now, `trường syllable` is is abbv of `trường_học word`); `trường` alone have alot of meanings: trường = field (trường điện từ = electrical field), trường = long, a-lot (đường trường = a very long road) ...

+ `n-gram` is a combinary of `n-tokens` to respect their context with additonal information like how frequenty it apprear ... `1,2,3-gram` is enough for Vietnamese since `4,5..-gram` mostly is composed of `1,2,3-gram`. In English, `n-gram` normally mean `n-words`, but:

    + Since `syllable` play an foundation role in Vietnamese (both spoken and written). We use `n-syllable` quite often to specify that we are dealing with meaningful unit `syllable`, not `token`, not `word`. `n-syllable` can form `words`, can form concise/very-condense-meaning `phares`, `idioms` ... And they combined together can form `sentences`, `paragraphs` .. 

    + Note: We normally find a very long sentence with alot of `,` and `;`, they should be a `paragraphs`.

+ (search) `terms` are used to describle the string input sequence from user (normally via keyboard) that express what the user have in mind. The `terms` should be understandable by both parties, the search engine UI normally provide user example of possible `search terms` and `search syntaxes` to form `more specific and more meaningful terms` that EXPRESS user intension much better. For example: Google search: 
`"full text search" site:wikipedia.com` got:
    + https://en.wikipedia.org/wiki/Information_retrieval
    + https://en.wikipedia.org/wiki/Trie
    + https://en.wikipedia.org/wiki/String-searching_algorithm

+ (search or not) `keywords` for me is the words that can represent whole meaning of the phrase. We can just scan a phrase for `keywords`only and we capture the rough meaning of that phrase. How to decice which if a `word` is a `keyword` or not is quite intersting.
