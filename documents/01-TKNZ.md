# VIETNAM TKNZ

* Rule #1: SYLLABLES are FIRST CLASS Citizens
* Rule #2: SubWord must re-use known SYLLABLES
* Rule #3: Phải tách được tokens bị dính
	=> Chấp nhận nhiều ứng cử viên tiềm năng, chọn lọc sau!
* Rule #4: Don't try to be clever
* Rule #5: Prefer simple solution!


## Phase-1: Space-splitter (space-32, tab-9) and alphabet vs nonalpha splitter

TODO:

* Handle `Thoọng`: need to conver `oo` to `ooo` before passing to syll-parser

* Reject mixed upper vs lower case syllable, keep only titelized or capitalized sylls

* Break alphabet-types into have-marks-and-tone vs others
FIX: why "cp" is categoried as marktone?

[ DONE ]

* colapse types that have similar _ascii-telex trans_ to create next layer of _ascii-telex types_

* Convert _utf8 types_ to _ascii-telex types_

* Find an efficient way to check if a _utf8 type_ is a Vi Syllable or not!
  - We know that `am_giua` is a must for a Vi Syllable
  - Some `am_giua` can follow one some `am_dau` and only be followed by some `am_cuoi`

* Choose an efficient bytes-hashing algorithm to count similar _utf8 lower_case-fom tokens_ to create _utf8 types_ (see `_HASH.md`)

### One-Way-Mapping Multiple layer of (Re-)presentations:
1. utf8 bytes => 2.
2. utf8 non-breaking tokens => 3.
3. utf8 alphabet tokens & utf8 delimiter (non-alphabet) tokens => 4.
4. utf8 alphabet types => 5. & utf8 delimiter (non-alphabet) types
5. ascii-telex syllable types (syllable vocab)

The purpose of this phase is to split the input text into a list of non-breaking tokens separated by space characters that can be inputted from keyboard (32, 9).

It's could be Syllables `Chây   ì   nộp   phạt   nguội   Cháu   đòi   tiền   cơm   dì   nhà   Đà   Nẵng   nghiên   cứu   tiện   ích   nhắn   tin   khi   vi   phạm   đến   chủ   phương   Khó   xử   vụ   mẹ   tuổi   trộm   xe   hơi   của   con   gái   Thay   đổi   về   đăng   ký   chuyển   nhượng   từ   bạn   cần   biết   Những   trường   hợp   trưng   cầu   giám   định   trong   án   kinh   tế   Thị   trấn   ở   bán   với   giá   hơn   để   thu   hút   cư   dân   Bỏ   quy`

Or non-alphabet / abbr / foreign-words ... `.   ,   70   12/2   1   12/2/2018:   20   :   '   '.   12/2.   20.000   02/2018.   2/2018?.   2/2018.   12/2:   24.000   2   ?.   -   12/02/2018,   18   (   ).   12   !'.   12:   7/18.   12/2/2018.   m2   BOT   18   QL18   TPHCM   CAND   7   FLC   4   SEA   Games   PVP   Land   U23   6km   MC   68   3   Samsung   Display   300   VFF   29   8   TNCN   AFF   Cup   2008   23   Italy   euro   200   Vietlott   105   27   21   casino   1986   FDI   jeans   DNNVV   bikini   TP   HCM   25   30   Rolls   Royce   Bespoke   2017   Cagliari   Juventus   HLV   Allegri   Serie   Icardi   Inter   80   4000   26   Rome   Mourinho   Morata   C1   Real   Ronaldo   VN   K   BHXH   THPT   Myanmar   Rohingya   TAND   T   ara   Facebook   Clip   Mercedes   container   Venezuela   265   Google   Uber   Aerobic   260   16   Malaysia   Chol`,

Or look-like-Vietnamese (typo, abbr, borrowed-words ...) `BHYTNâng   ĐHTB   Bôlykhămxay   này15   Xôviết   iốt   NộiThích   HĐBA   crôm   Chilê   HĐLĐ   uyênhXí   Hrê   Krông   BĐKH   đôla   ĐHQG   Euréka   QSĐ   đónTết   Tiếg   toàndiện   záo   zụk   ĐT601   LĐLĐVN   LĐTB   zăng   CQĐT   đôlômit   Thoọng   Vắcxin   ĐVHD   áBo   PTĐ   CĐCS   xtê   GĐKT   kêt   sơmi   QĐND   ATVSLĐ   Môt   hạiBài`


This phase must:

* Moving fast and try to detect as much syllable-tokens using strict rules [$] as possible!

* Convert utf-8 syllable-token to ascii-telex syllable-token

* Treat newline-10 as a special token type

* Adding class-attribute to each token 1 => Syllable, 2 => Newline 3 => Others

* Counting similar tokens to create types

[$] Strick rules ensure that only utf-8 token that 100% look like a vi-syllable with 0-confusion is converted. VD: `Ngươì => Nguwowif` but not confusing case like `ngườí` or `cáiiii gì????` ...

```js
Input: "Ngươì ơiii chào nhé!"
Output: "Nguowif", "ơiii", "chaof", "nhes", "!"
```

By doing all of this we respect Rule #1/ that makes "SYLLABLES are FIRST CLASS Citizens" so we can build a syllable vocab, and prepare input data the next phase.


## Phase-2: Subword segmentation

https://everdark.github.io/k9/notebooks/ml/natural_language_understanding/subword_units/subword_units.nb.html#12_probablistic_subword_segmentation

We iterate over every position in a given word. At each end-of-character position, we determine the best segment by finding the one with highest likelihood given the current vocabulary.

we need to have a vocabulary for subwords that can attribute each subword to a probability. We can use BPE to build such vocabulary. For complete coverage we will also include character-level subwords into the vocabulary.

https://everdark.github.io/k9/notebooks/ml/natural_language_understanding/subword_units/subword_units.nb.html#123_em_with_viterbi

Now we know the idea of EM, and we know how to find the optimal segment path by Viterbi, we can put them together to forumlate the optimization task of our probablistic subword segmentation.

* Initialize a large seeding subword vocabulary from the training corpus
* [Expectation] Estimate each subword probability by the corresponding frequency counts in the vocabulary
* [Maximization] Use Viterbi to segment the corpus, returning the optimal segments
* Compute the loss of each new subword from optimal segments
* Shrink the vocabulary size by dropping the subwords with top X% smallest losses
* Repeat step 2 to 5 until the vocabulary size reaches a desired number

The loss of a subword in step 4 is the reduction in overall training corpus segment likelihood if that subword is removed from the current vocabulary.

we used BPE to generate the initial vocabulary. Another common choice is to the suffix array algorithm. to generate the common substrings.


```js
Input: "Nguowif", "ơiii", "chaof", "nhes", "!"
Output: "Nguowif", "owi", "i", "i", "chaof", "nhes", "!"
```
After phase-#1, the number of others-tokens is quite small. For above example we need to process token number 3 only!


TODO:

* Sử dụng tokens dạng nguyên bản utf8 của vocab để scan OOV types, nhằm tách các thành phần chắc chắn là âm tiết. Chú ý cách phân biệt chữ cái viết hoa vs chữ cái viết thường có thể dùng để làm boundary để tách (xem ví dụ dưới).

* Có nhiều cách tách thì giữ lại thành nhiều dị bản, càng nhiều ứng cử viên tiềm năng càng tốt, cân hết!

* Choose an effective subword tknz algo that suitale for Vi and reuse syllable vocab

```js
Try: "MẹHàMy" -> "MẹHàM|y" -> true
Try: "Mẹnuôi" -> "Mẹn|uôi" -> true
Try: "NgheNh|ìn" -> false
Try: "Môn|ôlôxốp" -> "Mô|nô|lô|xốp" ?? nên giữ nguyên vì đây là tên riêng
```

This phase must:

* Re-use syllable vocab to break tokens in meaningful parts

* Combining subword tokenize techniques to obtain best results


## Phase-3: Anything elses / Post-processing

Digit tknz?, Viết tắt? ...

- - - 

# REF: SoTA HF Tokenizer
https://huggingface.co/docs/tokenizers/python/latest/components.html

## Normalizer
* Unicode normalization algorithms (NFD, NFKD, NFC & NFKC)
* Lowercasing
* Strip: Removes all whitespace characters on the specified sides (left, right or both) of the input
* ...
* Sequence: Composes multiple normalizers that will run in the provided order 
	`Sequence([NFKC(), Lowercase()])`

## PreTokenizer

The PreTokenizer takes care of splitting the input according to a set of rules. This pre-processing lets you ensure that the underlying Model does not build tokens across multiple “splits”. For example if you don’t want to have whitespaces inside a token, then you can have a PreTokenizer that splits on these whitespaces.

### ByteLevel Spliting (will be used with BPE)

Splits on whitespaces while remapping all the bytes to a set of visible characters. This technique as been introduced by OpenAI with GPT-2 and has some more or less nice properties:

	* Since it maps on bytes, a tokenizer using this only requires 256 characters as initial alphabet (the number of values a byte can have), as opposed to the 130,000+ Unicode characters.

	* A consequence of the previous point is that it is absolutely unnecessary to have an unknown token using this since we can represent anything with 256 tokens (Youhou!! 🎉🎉)

	* For non ascii characters, it gets completely unreadable, but it works nonetheless!


## BPE

One of the most popular subword tokenization algorithm. The Byte-Pair-Encoding works by starting with characters, while merging those that are the most frequently seen together, thus creating new tokens. It then works iteratively to build new tokens out of the most frequent pairs it sees in a corpus.

BPE is able to build words it has never seen by using multiple subword tokens, and thus requires smaller vocabularies, with less chances of having “unk” (unknown) tokens.


## WordPiece

This is a subword tokenization algorithm quite similar to BPE, used mainly by Google in models like BERT. It uses a greedy algorithm, that tries to build long words first, splitting in multiple tokens when entire words don’t exist in the vocabulary. This is different from BPE that starts from characters, building bigger tokens as possible.

It uses the famous ## prefix to identify tokens that are part of a word (ie not starting a word).

## Unigram

Unigram is also a subword tokenization algorithm, and works by trying to identify the best set of subword tokens to maximize the probability for a given sentence. This is different from BPE in the way that this is not deterministic based on a set of rules applied sequentially. Instead Unigram will be able to compute multiple ways of tokenizing, while choosing the most probable one.


- - - 

## Blah, blah, blah ...

https://blog.floydhub.com/tokenization-nlp/

TOKEN, TOKENIZE, TOKENIZATION: WHAT'S TOKEN? WHY TOKENIZATION? TOKENIZE FOR WHAT?

@Sáng 15/06/2021 trong lúc chuẩn hoá các việc sử dụng `terms` (see notes_on_terms.md), chợt nhận ra mình đang thiếu sự hiểu đúng về thế nào `token`, tìm kiếm trên Google và tìm đến [0]. Bài viết chân phương, dễ hiểu khiến mình nhận ra:

Token hiểu đơn giản là đầu ra của quá trình biến đổi các câu chữ đầu vào (text) thành các đơn-vị nền tảng để làm cơ-sở cho các bước xử lý tiếp theo.

Như vậy định nghĩa về `token`, `tokenize` ... là rộng, không cố kết với bất cứ thứ gì cụ thể. Cách hiểu tokenization là tách-từ như mình vẫn có trong đầu là bị thiên lệch, chưa thấu đạt và thoả đáng.

Bài viết gợi ra 1 từ khoá làm mình tò mò `Subword tokens` (Character tokens: s-m-a-r-t-e-r vs Subword tokens: smart-er) vì từ trước tới nay mình chưa đào sâu mà chỉ hiểu nôm na tokenization là tách-từ, mà giờ còn tách-nhỏ-hơn-cả-từ nữa cơ à? 

Thực ra tách nhỏ hơn từ là chuyện thường như cân đường hộp sữa, tiếng Anh có prefix, suffix, root ..., tiếng Việt có cách phân tách âm tiết như sau (thì chính là subword rồi còn gì :^)
```js
âm tiết = phụ âm đầu + vần
vần = âm giữa + âm cuối + thanh điệu
âm giữa = âm đệm + nguyên âm chính

Note: nguyên âm chính luôn có và thanh điệu luôn có
Phụ âm đầu, âm đệm, và âm cuối có thể ko có. 
Vần luôn có và thanh điệu là 1 thuộc tính của vần, bao trùm toàn bộ vần

VD1: cách phân tách theo phát âm

gặt		g {a2 t}_T6
chưa	ch ua2_T1
được	d2 {ua2 k}_T6
hình	h {i nh}_T2
thành	th {a1 nh}_T2
thói	th oi_T3
quen	k {u1 e1 n}_T1

VD1: cách phân tách theo nhập liệu TELEX từ bàn phím
Quy ước bỏ dấu ngay sau nguyên âm và thanh điệu gõ cuối cùng

gặt		g aw t j
chưa	ch uwa
được	dd uwow c j
hình	h i nh f
thành	th a nh f
thói	th oi s
quen	qu e n

```

Mình vừa làm xong module encode âm tiết tiếng Việt thành `u17` (dùng 17-bits) trong đó {phụ âm đầu} cần `u5`, {nguyên âm đệm + nguyên âm chính} cần `u5`, {âm cuối} cần `u4` và {thanh điệu} cần `u3` nên ý thức rõ về subwords trong tiếng Việt, cộng thêm các kiểu biến thể viết tắt, tiếng vùng miền, viết kiểu "trẻ trâu" trên internet nữa thì subwords "zô cùngg đa ja.ng và thú vịịịịịịị". 

Nếu chỉ thông qua chuẩn hoá đầu để quy chuẩn các biến thể đó thành âm tiết gốc thì đời còn gì là "vô cùng đa dạng và thú vị" nữa :'( Bởi chúng ta đã làm mất đi nhiều thông tin khác mà người gõ muốn chuyển tải qua con chữ như là tâm trạng, vùng miền, hay đơn giản là "gõ kém", "lóng ngóng", "mắt mờ, tay chậm", "chính tả dốt" nên gõ nhầm hoài!

Tiếp đó, bài viết thở ra một câu chốt "Transformed based models – the SOTA in NLP – rely on Subword Tokenization algorithms for preparing vocabulary. One of the most popular Subword Tokenization algorithm known as Byte Pair Encoding (BPE) that tackles OOV effectively."

Tạm dịch: Các Mô-hình "biến đổi ánh xạ", (mô hình) Xử-Lý-Ngôn-Ngữ-Tự-Nhiên đương đại, dựa vào các thuật toán `Subword Tokenization` để chuẩn bị từ vựng. Mã hoá cặp-byte (BPE) là thuật toán `Subword Tokenization` "quốc dân" nhất, nó giải quyết OOV hiệu quả!

VD: word-embedding biến-đổi tokens bằng cách ánh xạ nó 1-1 với các vectors toán học cực nhiều chiều (vài trăm chẳng hạn) [1]. 

Mình vừa `tokenize` 1 copus gần 600MB text tiếng Việt và OOV khá nhiều nên bồ kết ngay quả "giải quyết OOV hiệu quả". Nói vậy đủ để hiểu subword tokenization rất hay ho :^)

- - -

Luận về xử lý thông tin, con người hay máy tính không phải lúc nào cũng nhận được tín hiệu đầu vào CHUẨN mà hai bên đã quy ước với nhau từ trước. Chúng ta phải suy đoán (a.k.a giải mã) rất nhiều để có thể hiểu được ngôn ngữ, trong đối thoại hàng ngày chẳng hạn: 
+ có người nói rất nhanh, nói tắt, nói thiếu từ (mất tín hiệu -  signal lost/uncompleted)
+ có người nói rề rà, ề à, loằng ngoằng (nhiễu tín hiệu - signal vs noise)
+ có người dùng tiếng địa phương, bồi thêm tiếng nước ngoài (nhận được tín hiệu nhưng thiếu thông tin về tín hiệu đó - unknown signal)

Trong xử lý tín hiệu (có liên quan tới máy tính) đó là quá trình khử nhiễu, khôi phục tín hiệu bị mất từ những tín hiệu đã có, giải mã tín hiệu bằng nhiều mô hình khác nhau ...

Khi gõ/chat cũng thế, gõ sai chính tả; gõ tắt cho nhanh; gõ thiếu dấu, thiếu thanh điệu; não chúng ta phải suy đoán (giải mã) rất là nhiều, còn chưa kể yếu tố từ đồng âm khác nghĩa, từ đa nghĩa ... nữa, nó buộc chúng ta phải HỌC liên tục: Học bằng cách phải NẠP thông tin chung quanh chủ đề đang trao đổi, bằng cách diễn giải lại và hỏi đối phương xem mình hiểu như vậy có đúng không, bằng va chạm thử sai (trials and errors) để tự rút kinh nghiệm. Khi học đủ rồi thì chỉ cần người kia buột miệng 1 cái là mình biết họ định nói cái gì rồi, hoặc cho cậu gõ tắt thoải mái tớ liếc cái là hiểu liền, hoặc như trong khi chat với nhau thấy bên kia cứ ngập ngừng, gõ rồi mà chưa thấy gửi đi là đoán họ đang có điều gì ngập ngừng khó nói đây ... 

Tức là ngôn ngữ chỉ là phương tiện để người ta truyền tải truyền tải ý định / ý muốn của mình cho người khác hiểu được, nó chỉ là phương tiện, là kênh truyền tải không hơn. Trong kênh truyền tải đó ngoài từ ngữ, ngôn ngữ còn nhiều thông tin nữa về hoàn cảnh, trạng thái cảm xúc, sức khoẻ, văn hoá, vùng miền, thời tiết (lạnh quá nói run lập cập), bàn phím t9 (điện thoại cổ chỉ có 10 phím 0-9 được lồng ghép chữ cái a-z vào đó) không thể gõ đủ dấu được ... được truyền tải theo một cách trực tiếp hoặc gián tiếp. Những thông tin đó giúp chúng ta (và máy tính) hiểu sâu hơn về thông điệp muốn được truyền tải, thông cảm hơn với người nói / gõ, dựa vào đó mà phản hồi kịp thời, đúng trọng tâm, thoả mãn hai bên, khiến cả hai đạt được trạng thái mãn nguyện. Theo mình như vậy mới gọi là giao tiếp có tâm. Như vậy mới là mục đích cần đạt được của xử lý thông tin, xử lý ngôn ngữ ...

Việc chuẩn hoá tưởng là hay nhưng lại làm mất đi các tín hiệu mà người chuẩn hoá cho rằng là không cần thiết, nó làm cho việc giải mã trở nên đơn giản hơn với người hoặc máy tính nhưng làm xa rời đi mục đích cần đạt được ở trên. Khi gõ văn bản cũng thế, tín hiệu nguyên bản nhất mà máy tính nhận được chính là các tín hiệu nhận được từ bàn phím (key-strokes), làm sao để giữ được nguyên bản các key-strokes đó, xử lý trực tiếp trên các key-strokes đó sẽ làm cho bài toán trở nên sinh động và hữu ích hơn rất nhiều so với việc chỉ coi văn bản là 1 chuỗi các ký tựa được mã hoá (thuở xưa là ascii, thủa nay là unicode/utf-8).

EDGE CASES MATTER!

Với góc nhìn trên ngoài key-strokes (chỉ nghi nhận được thông qua bộ gõ tiếng Việt) chính các OOV (out-of-vocabulary words) mới là thứ sinh động, thú vị đáng để đào sau tìm hiểu, xem thông điệp đằng sau đó là gì ... ?

Tiếng Việt lỏng lẻo nên khả năng CHƠI chữ rất nhiều, nói cách khác là các biến thể và thông tin thêm đi kèm các biến thể đó rất nhiều ...

ÔNG CHỦ VÀ CÔNG DÂN HẠNG NHẤT, HẠNG 2,3

Bộ gõ tiếng Việt, là một bài toán cực hay mà chưa được khai thác hết, vì chỉ có bộ gõ mới nhận được thông tin từ bàn phím qua thời gian thực một cách nguyên bản và trần trụi nhất. Nó giống như chúng ta nghe/học trực tiếp và có thể tương tác hỏi đáp lại người đang nói/giảng với việc chúng ta nghe lại / xem lại trên youtube: Hoàn toàn khác biệt, và ở một đẳng cấp khác, ko thể so sánh với nhau.

Như vậy bộ gõ chính là công dân hạng nhất, OOV là công dân hạng hai, bộ từ vựng (được định nghĩa từ trước trong từ điển) là công dân hạng ba. Công dân hạng nhất theo túng công dân hạng hai và ba. Người gõ phím là ông chủ, là trùm cuối. Mình thông qua công dân để hiểu và tương tác với trùm cuối. Được quyền và được lựa chọn tương tác với công dân hạng nào là một lợi thế, lớn trong cách tiếp cận rồi. Sau đó mới là các phương pháp (google vô số) để xử lý bài toán.

KẾT

Cách tiếp cận `subword` sẽ là nền tảng, cách tiếp cận `keystrokes` sẽ là bước ngoặt trong nhập liệu và tương tác người máy thông qua ngôn ngữ tự nhiên! Và TOKEN, TOKENIZE, TOKENIZATION: WHAT IS TOKEN?, WHY TOKENIZATION?, TOKENIZE FOR WHAT? là bước khởi đầu vô cùng quan trọng cho việc phát triển về sau. Bởi đó là quá trình định nghĩa và tạo ra các đơn vị thông tin làm nền tảng cho các bước xử lý tiếp theo. 

Các đơn vị cần mang thông tin có ý nghĩa, số lượng vừa đủ (quá ít thì khô cứng, quá nhiều thì loạn), có khả năng chịu lỗi, có khả năng mở rộng được, có khả năng chuyển hoá được thành chuỗi tín hiệu đầu vào gốc (chuyển hoá hai chiều), không bị giới hạn bởi quy ước (cách gõ, cách mã hoá), bởi ngôn ngữ ... sẽ là tiêu chuẩn để phát triển và xây dựng TOKENIZERS. Nên nhớ word-tokenizer khác, syllable-tokenizer khác, subword-tokenizer khác và keystroke-tokenizer là 1 thứ khác nữa ...

- - -

PHỤ LỤC: Dây mơ rễ má và đọc thêm

Google về BPE dẫn tới [2], [2] dẫn tới [3], [3] dẫn tới [4] và [4] chỉ ra BPE được dùng trong [5]: Google SentPiece.


[0] https://www.analyticsvidhya.com/blog/2020/05/what-is-tokenization-nlp/

[1] https://colah.github.io/posts/2014-07-NLP-RNNs-Representations/

[2] https://paperswithcode.com/method/bpe

[3] https://leimao.github.io/blog/Byte-Pair-Encoding

[4] https://en.wikipedia.org/wiki/Byte_pair_encoding

[5] https://github.com/google/sentencepiece

[6] https://jacky2wong.medium.com/understanding-sentencepiece-under-standing-sentence-piece-ac8da59f6b08

[7] https://gist.github.com/atinsood/6d185dfe025cbb5d55f158d4d17bc142