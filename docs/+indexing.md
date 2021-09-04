Như đã trình bày ở `docs/syllable_n_token.id.md` mọi syllable tiếng Việt và OOV trong corpus đều được định danh bằng `u15`. Để tiện cho máy tính xử lý theo byte ta dùng `u16` để định danh và dư ra ít nhất 32k slot để chứa từ quan trọng không phải là syllables (từ ghép, từ tiếng dân tộc thiểu số, từ vay mượn từ tiếng nước ngoài, từ lóng, từ viết tắt, các ký hiệu hay dùng ...) lọc ra bằng từ điển và thống kê.

Bài toán gộp âm tiết thành từ hay còn gọi là tách từ tiếng Việt đang thiếu và yếu, thiếu một quy chuẩn về mặt ngôn ngữ học là tách từ thế nào là hợp lý, thiếu một từ điển đủ bao quát và cập nhật, thiếu bộ corpus đủ lớn để học và đánh giá độ chính xác trong nhiều domains khác nhau. Vì vậy cách tiếp cận ở đây là đừng chạy theo accuracy hay tìm ra best solution, mà hãy sử dụng n-best hay aprroximate, hay pattern matching ...

Điểm chính ở đây là có nhiều cách trình bày và bài toán indexing, searching bao trùm tất cả các cách trình bày đó mà không cần phải chỉ ra đâu là cách trình bày tốt nhất. Tốt nhất hay không là tuỳ thuộc vào ngữ cảnh và mục đích sử dụng.

Ví dụ với câu "ông già đi nhanh quá" có 2 cách tách từ như sau:
1/ ông/N già/ADJ đi/N nhanh_quá/ADV
2/ ông/N già_đi/V nhanh_quá/ADV
Nếu không có context thì cả hai đều đúng và có giá trị như nhau.

Giả sử người dùng input "già đi nhanh", máy sẽ phân tích ra 3 bộ keywords để search như sau:
0/ già + đi + nhanh
1/ già_đi/V nhanh/ADV
2/ già/ADJ đi/V nhanh/ADV
(Bộ 0 là baseline, đúng trong mọi trường hợp :D)

Hiện kết quả của cả 2 cách phân tích và hỏi lại người dùng xem họ chọn cách nào. Nếu cả 2 cách ko thoả mãn người dùng thì show baseline.

Cách này áp dụng trong cả inverted indexing và word2vec.

- - -

Để giới hạn không gian ids trong `u16`, bộ từ điển tối đa có thể sử dụng là 32k từ.

- - -

Để sử dụng bộ từ điển nhiều từ hơn cần mở rộng số lượng tokens cần index, hoặc sử dụng positional index (đằng nào cũng phải dùng với sub-word tokens).

Tuy nhiên mở rộng số tokens quá nhiều sẽ làm phình DB lên ít nhất gấp đôi.

- - -

Một cách lỏng hơn nữa là sử dụng flags (xem `docs/.dict_matching.md`)
Với mỗi syllable (token) sẽ có flags 4-bits để xem token đó thuộc về vị trí thứ mấy của từ giả sử từ dài nhất chỉ có 4 âm tiết.

ví dụ:
"màu xanh" => màu-1,0,0,0 xanh-0,1,0,0
"cơ sở dữ liệu" => cơ-1,0,0,0 sở-0,1,0,0 dữ-1,0,1,0 liệu-0,1,0,1 vì "dữ liệu" là 1 từ riêng

với text "xanh lá, màu xanh" => màu-1,0,0,0 xanh-1,1,0,0 lá-0,1,0,0
với input "xanh xanh" => xanh-1,1,0,0 thì sẽ khớp với text "xanh lá màu xanh" chưa ổn.

## PHƯƠNG ÁN 1

Bổ xung thông tin về vị trí tương đối, giả sử ta dùng 2-bit để biểu diễn vị trí tương đối của tok trong tex. với tex "xanh lá, màu xanh" => xanh/0 lá/0 màu/1 xanh/1.

Kết hợp với flags ta có: tex "xanh lá, màu xanh" 
=> xanh-1,0,0,0/0 lá-0,1,0,0/0 màu-1,0,0,0/1 xanh-0,1,0,0/1

Với input "xanh xanh" không tìm được xanh-1,1,*,*/x ở cùng vị trí x

Giả sử mỗi syl được lặp lại với xác suất 1/12 thì 16 doc-rel-pos flags lưu OK cho 192 syls' tex (đoạn văn 10 dòng, mỗi dòng khoảng 20 âm tiết).

**EDGE CASE**: lát cắt nằm ở giữa từ thì xử lý thế nào ???
  => !! LÀM TRÒN VỊ TRÍ CẮT CHO TỚI HẾT SYLLABLE CHUNK !!!

=> Inverted index sẽ có dạng:

tok_id: 
  doc_id1(`u32`):doc-rel-pos-flags(`u16`) [word-pos-flags-0(`u4`)...word-pos-flags-k1(`u4`)]
  doc_id2(`u32`):doc-rel-pos-flags(`u16`) [word-pos-flags-0(`u4`)...word-pos-flags-k2(`u4`)]
  ...

- - -

## PHƯƠNG ÁN 2

Giả sử với mọi 4-syllable words trong từ điển ta liệt kê mọi bi-gram (2-syllables) và index hết các bi-grams đó thì sao?

Với ví dụ trên thì bi-gram "xanh-xanh" ko có mặt trong text "xanh lá màu xanh" nên không match với input "xanh xanh".

Chỉ giữ lại khoảng 32k bi-gram đại diện cho từ điển mà có tuần suất xuất hiện trong corpus là cao nhất để làm đại diện.

Sau khi lọc bi-grams từ 34k và giữ lại 32k top, lọc uniq syllables được: 5427 uniq syllables.
29_452_329 (5427^2) combinations =>
3_681_542 bytes (3.6Mb) để làm bit_set

https://randorithms.com/2019/09/12/MPH-functions.html

A perfect hash function is one that maps N keys to the range [1,R] without having any collisions. A minimal perfect hash function has a range of [1,N]. We say that the hash is minimal because it outputs the minimum range possible. The hash is perfect because we do not have to resolve any collisions.