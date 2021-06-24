## Lợi ích của việc Telexifiy Syllables (utf-8 to ascii-telex)

* Giảm số ký tự cần để mã hóa

* Chuẩn hóa việc bỏ dấu thanh điệu trên nguyên âm.

* Dùng `u17` đủ để nghi nhớ toàn bộ syllables, không cần dùng từ điển mà từ universal `u17 ID` này là có thể khôi phục lại text-form của syllable.

* Tăng tốc mã hóa toàn bộ dữ liệu. Coi syllables là vocab. Sau khi gạn lọc các syllables có thể telexified, phần còn ở giữa là `OOV`. Việc mã hóa OOV sẽ đơn giản và nhẹ nhàng hơn do phần dữ liệu này nhỏ. Sử dụng BPE chỉ với OOV sẽ vô cùng nhanh so với việc BPE trên toàn bộ dữ liệu.

*// Cách tiếp cận hiện đại //*

Coi `syllables` là cái đã biết. `OOV` là cái đáng để phám phá. Tiếng Việt dùng từ mượn, từ nước người, tên riêng, viết tắt rất là nhiều. OOV cần khá lớn. 5000

`▁tooi ▁ddeens ▁dduwowngf ▁3/4`


## Final

### Dùng 20-bits (5x4) để mã hóa Syllables (2.5-bytes)
17-bits must, 1-bit để phân biệt S hay O, 1-bit để xem trước có ▁ hay ko? 1 bit để xem chữ cái đầu có viết hoa hay ko? 1-bit để xem syllable có dc auto-completed hay ko?
`.uyee <= .uye, .iee <= .ie, .yee <= .ye, .uee <= .ue, .uwow <= .uwo`

### Dùng 16-bits (4x4) để mã hóa OOVs (2-bytes)
1-bit để phân biệt S hay O, 1-bit để xem trước có ▁ hay ko? Còn 14-bits tức là 16,384 chỗ để chứa OOV (<= thoải mái, chứa được toàn bộ tiếng Anh nếu dùng BPE để chơi song ngữ luôn).

=> Chọn chia hết cho 4 để có thể dùng PackedIntStruct :^)

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

* ??? 2-bits to mark the `in-between-delimiter-category` of `tri-syllables`:
	+ 0x00: SPACES \s \n \t
	+ 0x01: NOT_SPACES '-' '/' ':' ...
	+ 0x10: MIXED (of three above)

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