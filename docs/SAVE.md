```c old telexify write to file on-the-fly
    var file = try std.fs.cwd().createFile(output_filename, .{});
    defer file.close();
    var buff_wrt = Text.BufferedWriter{ .unbuffered_writer = file.writer() };
    text.writer = buff_wrt.writer();
    try buff_wrt.flush();

pub const Text = struct {
    pub const FileWriter = std.io.Writer(std.fs.File, std.os.WriteError, std.fs.File.write);
    pub const BufferedWriter = std.io.BufferedWriter(ONE_MB / 5, FileWriter);
    writer: BufferedWriter.Writer = undefined,


pub inline fn writeToken(token: []const u8, attrs: Text.TokenAttributes, text: *Text) !void {
    if (text.keep_origin_amap) {
        if (attrs.spaceAfter())
            _ = try text.writer.print("{s} ", .{token})
        else
            _ = try text.writer.write(token);
        return;
    }
    // Write space after token
    if (attrs.isSyllable()) {
        _ = try text.writer.print("{s} ", .{token});
        text.prev_token_is_vi = true;
    } else {
        switch (token[0]) {
            '\n' => _ = try text.writer.write("\n"),
            '_', '-' => if (attrs.surrounded_by_spaces == .none and token.len == 1) return,
            else => _ = try text.writer.print("{s} ", .{token}),
        }
    }
}

    // Write syllables only
    if (tk_info.isSyllable()) {
        _ = try writer.print("{s} ", .{tk_info.trans_slice(text)});
        text.prev_token_is_vi = true;
        //
    } else if (text.prev_token_is_vi) {
        //
        const trans_ptr = tk_info.trans_ptr(text);

        const true_joiner = tk_info.attrs.surrounded_by_spaces == .none and trans_ptr[1] == 0 and (trans_ptr[0] == '_' or trans_ptr[0] == '-');

        if (!true_joiner) {
            _ = try writer.write("\n");
            text.prev_token_is_vi = false;
        }
    }
```

```c old TokenCategory struct


    pub inline fn toByte(self: TokenAttributes) u8 {
        const byte = @bitCast(u8, self);
        if (byte < 12) return byte + 1;
        return byte;
    }

    pub inline fn newFromByte(byte: u8) TokenAttributes {
        if (byte < 12) byte -= 1;
        return @bitCast(TokenAttributes, byte);
    }

    pub const TokenCategory = enum(u6) {
        // Dùng được 27 invisible ascii chars, 1-8,11, 12,15-31
        // 3 main token categoried, used to write to disk as token's attrs
        nonalpha = 0, //  + 2-bits  => 00,01,02,03 + 1 => \x01\x02\x03\x04
        // Avoid slot 1 if possible since it don't show as space in klogg app
        //         1, //  + 2-bits  => 04,05,06,07 + 1 => \x05\x06\x07\x08
        //         2, //  + 0x11    =>       10    + 1 => \x0b
        //         3, //  + 0x00,11 => 12       15     => \x0c\x0f
        alphmark = 4, //  + 2-bits  => 16,17,18,19     => \x10\x11\x12\x13
        alph0m0t = 5, //  + 2-bits  => 20,21,22,23     => \x14\x15\x16\x17
        syllmark = 6, //  + 2-bits  => 24,25,26,27     => \x18\x19\x1a\x1b
        syll0m0t = 7, //  + 2-bits  => 28,29,30,31     => \x1c\x1d\x1e\x1f
        // Supplement category ids 8-63
        // used as an intialized/temp values / need to be processed / state machine
        can_be_syllable = 8,
    };
```



# Vietnamese Telex Input Method and Everything Related

## Inspire

https://en.wikipedia.org/wiki/Microsoft_SwiftKey

https://medium.com/@curiousNupur/how-does-swiftkey-predict-your-next-keystrokes-b048ef67267d

## Cải tiến bộ gõ telex

[ IMPORTANT ] Yếu điểm có thể coi là lớn nhất của Telex là viết song ngữ rất chậm,
vì hay bị hiểu lầm thành dấu mũ. Việc chuyển bàn phím thì cũng rất mất thời gian !!!

[ QUESTION ] Làm thế nào để giảm thiểu sự nhầm lẫn khi gõ tiếng Anh lẫn lộn với tiếng Việt ???

[ Gõ Tiếng Việt MacOS ]
https://github.com/tuyenvm/OpenKey 

* Gõ nhanh âm đầu: cc => ch, gg => gi, kk => kh, nn => ng
* Gõ nhanh âm cuối: g => ng, h => nh, k => ch


### Beyond tknz

[ >>> HERE I SHOULD BE, DOWN THE RABBIT HOLE <<< ]

A/ Tiếp tục đào sâu, cải tiến phase-1, handmade phase-2, hoàn thiện tới phase-3 (poss-processing, tách từ sâu hơn nữa, chữa lỗi chính tả ...)

Bài toán sequence tagging yêu cầu phải matching với từ điển, việc truy vấn ngược token khi chưa sử dụng DB, chưa mapping token <=> Id coi như phải đọc lại dữ liệu từ đầu.

Trước khi làm matching cần cài đặt trie để mapping token <=> Id
https://www.s-yata.jp/marisa-trie/docs/readme.en.html

Sau đó dùng DB https://github.com/lithdew/lmdb-zig để lưu dữ liệu một cách có cấu trúc, có hệ thống, để dễ sử dụng lại, dễ truy vấn, trích xuất ... hơn ...

[ >>> DONE <<< ]

Thấy cần quay lại cải tiến nền tảng vì phần tknz, tagging, dictionary matching mà làm ko kỹ thì phần tiếp theo cũng ko cải thiện mấy. => Quay lại A/

Chọn C/ làm trước. Đi theo hướng NLP: Embedding, Tagging, NER, ... 


### VieTok: A Vietnamese Text Tokenizer

Xem chi tiết `docs/01-TKNZ.md`: Hiện đã xong phrase-1, tách Viet Syllables làm bộ từ vựng chính, tách tokens đi cùng bộ thuộc tính nhúng vào 27 ký tự ascii vô hình để có thể đi kèm token (làm header) trong file text.

Phase-2 dùng `syllower` đã tách làm bộ từ vựng gốc (khoảng 9000 âm tiết viết thường), sau đó áp dụng BPE để xử lý mọi OVV bao gồm `alphmark`, `alph0m0t` và `nonalpha` bằng cách quy về các `subword units` (dự tính khoảng 9000 từ vựng nữa)
https://github.com/telexyz/fastBPE

Phase-1 cũng còn rất nhiều ý tưởng cần thực thi hoặc cải tiến:
1/ Data-struct để lưu và tra cứu vocab, (xem `reTRIEval.md`) với vocab nhỏ khoảng vài chục ngàn từ thì Trie là đủ dùng https://tessil.github.io/2017/06/22/hat-trie.html

2/ Tách text thành các tập nhỏ hơn và sử dụng map-reduce để xử lý song song hoặc phân tán. Cách này cực hiệu quả và có thể sử dụng cả ở những tầng xử lý tiếp theo như indexing, searching, embedding ...

Hiện có ba lựa chọn:

A/ Tiếp tục đào sâu, cải tiến phase-1, handmade phase-2, hoàn thiện tới phase-3 (poss-processing, tách từ sâu hơn nữa, chữa lỗi chính tả ...)

B/ Dừng lại ở đó để đi tiếp theo hướng lưu trữ + Retrieval (encoding, indexing, searching, ... ) Hướng này đi sâu vào ứng dụng tìm kiếm, sử dụng https://justine.lol/redbean/ để viết web app (dùng web interface) rất hay. Hướng này kết quả cuối đã hình dung rõ, chỉ tập trung vào implement cho tốt.

C/ Dừng lại ở đó để đi tiếp theo hướng NLP: Embedding, Tagging, NER, ... Hướng này hướng tới SOTA NLP, sử dụng các thư viện đơn giản và hiệu quả như để khám phá xem có thể làm gì được với tập dữ liệu tiếng Việt đang có?

TO-TEST: convert syllable to various format and valid them with telex parser.

Hiện tại với mỗi char đầu vào phải switch 3 lần, lần 1 phân biệt kiểu char, lần 2, convert từ utf-8 về ascii-telex, lần 3 xem nó là viết hoa hay thường => viết 1 hàm trung lập thống nhất 3 lần switch này về làm 1.

=> 11.8% faster (182182 ms / 206351 ms)

## [ Telex Engine ] New insights / improvements II

+ `output/result_00../syllables1,2.txt` contains recognized syllables
+ `output/result_00../oov1,2.txt` contains oov words without second try

While looking at oov.txt (out-of-vocabulary), found a reasonable amount of word that composed of two valid vietnamese syllables:
đăngký Đăngơ ĐĩaThan đơngiá đơnphải đưalao đưatin đưaTrung đưaTết đườngkỳ đườngphục Đượ đượ đượcca đượcdùng đượcgiao đượcgiải đượcnha đạophòng đạoTPHCM đạoVịnh đạođối Đạtlai Đảngcho ĐảoCôn 

=> Try to parse them using concat more-than-one-syllable without separator. In other words, just parse input char stream untill the output syllable is saturated then add a new empty syllable to continue parsing ...

### RESULTS

+ `output/result_00../syllables1.txt` contains double-syllable words
+ `output/result_00../oov1.txt` contains oov words after apply second try

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