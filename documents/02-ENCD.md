## Dùng mã ascii để lưu, syll id, mục đích để ko phá game khi lưu cùng ascii/utf8
`/0-9`: 47,48-57 => 11
`@A-Z`: 64,65-90 => 27
 `a-z`: 97-122   => 26
Total = 64 (2^6) => Cần 3-bytes để mã hóa 18-bits dưới dạng ascii đọc được

```js
// Dùng được 27 invisible ascii chars, 1-8, 11,12, 15-31
var str = "|\x01\x02\x03\x04\x05\x06\x07\x08\x0b\x0c\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x19\x1a\x1b\x1c\x1d\x1e\x1f|";
```
Mã hóa độ dài token: `switch(lencode) {`
* 01-08: 01-08          ` 1... 8 => token_len = lencode,`
* 15-31: 09-25          `15...31 => token_len = lencode - 6,`
* 11,12: >= 26             `else =>  ... ... ... , }`

Mã hóa token attrs khi đi cùng ascii/utf8 text (IMPLEMENTED in `text.zig`)
```js
// src/text.zig
// Còn dư hai full-slots 0,1 và hai half-slots 2,4
    pub const TokenCategory = enum(u6) {
        // Dùng được 27 invisible ascii chars, 1-8,11, 12,15-31
        // 3 main token categoried, used to write to disk as token's attrs
        //         0  //  + 2-bits  => 00,01,02,03 + 1 => \x01\x02\x03\x04
        //         1  //  + 2-bits  => 04,05,06,07 + 1 => \x05\x06\x07\x08
        //         2  //  + 0x11    =>       10    + 1 => \x0b
        //         3  //  + 0x00,11 => 12       15     => \x0c\x0f
        syllable = 4, //  + 2-bits  => 16,17,18,19     => \x10\x11\x12\x13
        marktone = 5, //  + 2-bits  => 20,21,22,23     => \x14\x15\x16\x17
        alphabet = 6, //  + 2-bits  => 24,25,26,27     => \x18\x19\x1a\x1b
        nonalpha = 7, //  + 2-bits  => 28,29,30,31     => \x1c\x1d\x1e\x1f
        // Supplement category ids 8-63
        // used as an intialized/temp values / need to be processed / state machine
        _none = 8, // initial state
    };

    pub const TokenSurroundedBySpaces = enum(u2) {
        // Use 2-bits to describle
        none, //  0|0
        right, // 0|1
        left, //  1|0
        both, //  1|1
    };
```
## Lợi ích của việc Telexifiy Syllables (utf-8 to ascii-telex)

* Giảm số ký tự cần để mã hóa

* Chuẩn hóa việc bỏ dấu thanh điệu trên nguyên âm.

* Dùng `u17` đủ để nghi nhớ toàn bộ syllables, không cần dùng từ điển mà từ universal `u17 ID` này là có thể khôi phục lại text-form của syllable.

* Tăng tốc mã hóa toàn bộ dữ liệu. Coi syllables là vocab. Sau khi gạn lọc các syllables có thể telexified, phần còn lại là `OOV`. Việc mã hóa OOV sẽ đơn giản và nhẹ nhàng hơn do phần dữ liệu này nhỏ và có syllables làm nền tảng để mã hóa tiếp.

*// Cách tiếp cận hiện đại //*

Coi `syllables` là cái đã biết. `OOV` là cái đáng để phám phá. Tiếng Việt dùng từ mượn, từ nước người, tên riêng, viết tắt rất là nhiều. Chỗ chứa OOVs cần đủ lớn.

`▁tooi ▁ddeens ▁dduwowngf ▁3/4`


## Finalize

### a.1/ Dùng 20-bits (5x4) để mã hóa Syllables (2.5-bytes)
* 17-bits is a must, 
+ 01-bit để phân biệt Syllable hay OOV
+ 01-bit để xem trước có ▁ (space) hay ko? 
+ 01 bit để xem chữ cái đầu có viết hoa hay ko? 

### a.2/ Dùng 16-bits (4x4) để mã hóa OOVs (2-bytes)
- 01-bit để phân biệt Syllable hay OOV 
- 01-bit để xem trước có ▁ (space) hay ko? 
* Còn 14-bits tức là 16,384 chỗ để chứa OOV 
(<= có thể thêm 01 ngôn nhữ nữa như tiếng Anh chẳng hạn nếu dùng BPE).

Nếu cần nâng lên 20-bits như sylls => chứa được 2^18 = 262,144 từ
Cắt 2-bits để làm việc khác vẫn còn chỗ cho 65,536 từ
=> Chọn chia hết cho 4 để dễ dồn bits vào bytes (xem PackedIntStruct :^)

### b/ Lưu tất cả vào 20-bits (2.5 bytes)
* 17-bits đầu đương nhiên dùng hết
+ 01-bit để xem trước có ▁ (space) hay ko? 
+ 01 bit để xem chữ cái đầu có viết hoa hay ko? 
+ 01 bit để xem toàn bộ token có viết hoa hay ko?
<hoặc>
+ 01-bit để xem syllable có dc auto-completed hay ko? `.uyee <= .uye, .iee <= .ie, .yee <= .ye, .uee <= .ue, .uwow <= .uwo`</hoặc>

Sau khi phân tách 17 bits đầu vào âm-đầu + âm giữa + âm cuối + tone sẽ biết được là syll hay oov? Phần còn lại dư 63,368 chỗ cho OOVs (xem chi tiết ở phần cuối)

!!! NGHIÊNG VỀ b/ VÌ CÓ THÊM 1 BIT ĐỂ LƯU ATTRS VÀ THÊM CHỖ CHO OOV !!!

## Convert *all* Vietnamese `(mono,bi,)tri-syllables` to `u64`
(*all* means enough to cover every use-cases)

*// Cách tiếp cận truyền thống, coi syllables mới là quan trọng. //*

`u17` to encode a `syllable` => 13-bits (64-17x3) left to store as much info as we can to re-produce original input chars from encoded data (additonal data will be put in the end of `tri-syllable`):

* 3-bits to mark if the first char of each `syllable` is capitalized or not

* 3-bits to mark if each `syllable` is all-capitalized or not

* 3-bit to mark if each `syllable` vowel is auto-completed or not:
// .uyee <= .uye, .iee <= .ie, .yee <= .ye, .uee <= .ue, .uwow <= .uwo
+ dưoi <1> duwowi	// diff = 1

* 2-bits to mesure the `relative-position-to-the-phrase` of the `tri-syllables`
	+ 0x00: left   of the-phrase
	+ 0x01: middle of the-phrase
	+ 0x10: right  of the-phrase
	+ 0x11: I'm the-whole-phrase

* ??? 2-bits to mark the `in-between-delimiter category` of `tri-syllables`:
(phần nằm giữa hay phần nối các syll trong tri-syll)
	+ 0x00: NONE       	    	"ngàyhômnay"
	+ 0x00: SPACE \s \t 		"ngày hôm nay"
	+ 0x01: OTHER '-' '/' ':'   "ngày-hôm-nay", "3/4"
	+ 0x10: .....

?? Other conversions:

+ nghêmnh  <0> ngheemnh
+ nghêmnhj <0> ngheemnhj

Note: `_` thanh ngang, `s` sắc, `f` huyền, `r` hỏi, `x` ngã, `j` nặng, `?` confusing


```js <= zig
// am_dau 0-27, 5-bits. Dư 4-slots => đánh dấu đc 16384 = 4 * 32 * 16 * 8
@intCast(u17, @enumToInt(syllable.am_dau)) |
    // am_giua 0-30, 5-bits. Dư 1-slot => đánh dấu đc 3584 = 28 * 1 * 16 * 8
    (@intCast(u17, @enumToInt(syllable.am_giua)) << AM_GIUA_BITS_OFFSET) |
    // am_cuoi 0-12, 4-bits. Dư 3-slots => đánh dấu đc 20832 = 28 * 31 * 3 * 8
    (@intCast(u17, @enumToInt(syllable.am_cuoi)) << AM_CUOI_BITS_OFFSET) |
    // tone 0-5, 3-bits. Dư 2 slots => đánh dấu đc 22568 = 28 * 31 * 13 * 2
    (@intCast(u17, @enumToInt(syllable.tone)) << TONE_BITS_OFFSET);

// => Tổng slots còn dư là 63368 = 16384 + 3584 + 20832 + 22568
// Verify assumption:
// - - - - - - - - -
// Total slots 131072 = 2^17
// Used slots 67704 = 28*31*13*6
// Remain slots 63368 = 131072 - 67704. Ok! Good!
```