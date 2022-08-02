- Tìm hiểu thuật toán nén `integer` bằng SIMD
  https://upscaledb.com/blog/0009-32bit-integer-compression-algorithms.html
  https://upscaledb.com/blog/0012-32bit-integer-compression-algorithms-part2.html
  https://upscaledb.com/blog/0013-32bit-integer-compression-algorithms-part3.html

## Đặt vấn đề

`docs/syllable_n_token.id.md` chỉ ra rằng chỉ cần `u15` là dư sức để định danh mọi syllables tiếng Việt và OOV trong corpus. Để tiện cho máy tính xử lý theo byte ta dùng `u16` để định danh tokens nói chung nên sẽ dư ra ít nhất 32k slots để chứa từ quan trọng không phải là syllables (từ ghép, từ tiếng dân tộc thiểu số, từ vay mượn từ tiếng nước ngoài, từ lóng, từ viết tắt, các ký hiệu hay dùng ...) lọc ra bằng từ điển và thống kê.

Tiếp theo, gộp tokens gần nhau thành các cụm có ý nghĩa (một từ) là cần thiết để tăng độ chính xác tìm kiếm. Bài toán gộp âm tiết thành từ hay còn gọi là tách từ tiếng Việt đang thiếu và yếu, thiếu một quy chuẩn về mặt ngôn ngữ học là tách từ thế nào là hợp lý, thiếu một từ điển đủ bao quát và cập nhật, thiếu bộ corpus đủ lớn để học và đánh giá độ chính xác trong nhiều domains khác nhau. Vì vậy cách tiếp cận ở đây là đừng chạy theo accuracy hay tìm ra best solution, mà hãy sử dụng n-best, aprroximate, hay mọi patterns có thể matching ...

Điểm chính cần lưu tâm ở đây là có nhiều cách chuẩn bị và trình bày lại dữ liệu đầu vào trước khi xử lý và bài toán indexing, searching có thể tiếp cận theo hướng ăn tạp tức là sử dụng tất cả các cách trình bày đó mà không cần phải chỉ ra đâu là cách trình bày tốt nhất. Vì cái này tốt hơn cái kia luôn tuỳ thuộc vào ngữ cảnh và mục đích sử dụng.

Ví dụ với câu "ông già đi nhanh quá" có 2 cách tách từ như sau:
* 1/ ông/N già/ADJ đi/N nhanh_quá/ADV
* 2/ ông/N già_đi/V nhanh_quá/ADV
Nếu không có context thì cả hai đều đúng và có giá trị như nhau.

Giả sử người dùng input "già đi nhanh", máy sẽ phân tích ra 3 bộ keywords để search như sau:
0/ già + đi + nhanh
1/ già_đi/V + nhanh/ADV
2/ già/ADJ + đi/V + nhanh/ADV
(Bộ 0 là baseline, trung tính, bao trùm mọi cách phân tích)

Máy sẽ hiển thị cả 2 cách phân tích trên và hỏi lại người dùng xem họ chọn cách nào. Nếu cả 2 cách ko thoả mãn người dùng thì show baseline. __Cách này áp dụng trong cả inverted indexing và word2vec.__



## Thảo luận về việc mở rộng bộ từ vựng hay dùng positional indexing

Với cách định danh tokens dùng `u16`, bộ từ điển tối đa có thể sử dụng là 32k từ. Để sử nhiều hơn 32k từ hơn có thể dùng `u24` để tăng lượng tokens có thể index, hoặc sử dụng `positional index`. 

Nên dùng `positional index` nó cần thiết cho sub-word tokens nhất là trong indexing văn bản song ngữ / ngôn ngữ, bộ từ vựng không thể biết trước.

Cũng là tăng thêm 1-byte khi indexing thì 1-byte này có thể cộng dồn vào mục định danh (`u16 => u24`) hoặc dùng để làm `positional index`, hoặc tìm một cách khác để sử dụng 1-byte này sao cho thật hiệu quả!


Một cách lỏng hơn nữa là sử dụng flags (xem `docs/*dict_matching.md`). Với mỗi token (ám chỉ âm tiết và OOV) sẽ có flags 4-bits để xem token đó thuộc về vị trí thứ mấy của từ giả sử từ dài nhất chỉ có 4 âm tiết hoặc 4 OOV.

ví dụ:
"màu xanh" => màu-1,0,0,0 xanh-0,1,0,0
"cơ sở dữ liệu" => cơ-1,0,0,0 sở-0,1,0,0 dữ-1,0,1,0 liệu-0,1,0,1 vì "dữ liệu" là 1 từ riêng

với text "xanh lá, màu xanh" => màu-1,0,0,0 xanh-1,1,0,0 lá-0,1,0,0
với input "xanh xanh" => xanh-1,1,0,0 thì sẽ khớp với text "xanh lá màu xanh" chưa ổn.


### PHƯƠNG ÁN 1: relative positional indexing (rel-pos)

Bổ xung thông tin về vị trí tương đối, giả sử ta dùng 2-bit để biểu diễn vị trí tương đối của tok trong tex. với tex "xanh lá, màu xanh" => xanh/0 lá/0 màu/1 xanh/1.

Kết hợp với flags ta có: tex "xanh lá, màu xanh" 
=> xanh-1,0,0,0/0 lá-0,1,0,0/0 màu-1,0,0,0/1 xanh-0,1,0,0/1

Nên với input "xanh xanh" như ở ví dụ trên không tìm được xanh-1,1,*,*/x ở cùng vị trí x

Giả sử mỗi syl được lặp lại với xác suất 1/12 thì `16 doc-rel-pos` lưu OK cho 192 syls' tex (tương đương đoạn văn 10 dòng, mỗi dòng khoảng 20 âm tiết).

_TODO_: Ước lượng xác suất lặp lại âm tiết!

**EDGE CASE**: lát cắt nằm ở giữa từ thì xử lý thế nào ???
  => !! LÀM TRÒN VỊ TRÍ CẮT CHO TỚI HẾT SYLLABLE CHUNK !!!

=> Inverted index sẽ có dạng:

tok_id: 
  doc_id1(`u32`):word-pos-flags-0(`u4`)...word-pos-flags-k1(`u4`)
  doc_id2(`u32`):word-pos-flags-0(`u4`)...word-pos-flags-k2(`u4`)
  ...

Với k1, k2 ... kn <= L, L là trị số để giới hạn số lượng rel-pos. L càng nhỏ thì dung lượng index db càng nhỏ, L càng lớn thì độ chính xác của rel-pos càng cao. 

_word-pos-flags-0(`u4`)...word-pos-flags-k1(`u4`)_ là spare data struct, chỗ nào ko có ko cần lưu!

=> !!! Nghệ thuật ở đây là ở chỗ phân tích 1 doc để phân chia rel-pos sao cho xác xuất trùng nhau ít nhất hoặc với 1 xác xuất cho trước số lượng rel-pos phải dùng là ít nhất !!!
 
* Tức là độ dài ngắn của phân đoạn rel-pos có thể khác nhau
   (phụ thuộc vào độ trùng lặp của token trong đoạn đó)
 
* Các phân đoạn có thể trùm mí lên nhau để handle EDGE CASE


#### Bài toán cho trước tần suất lặp lại token chấp nhận được, phân đoạn rel-pos

* VD tần suất lặp không quá 2 token bị lặp trên 1 đoạn

* Dùng obvious breakers (stop chars) để xác định ranh giới có thể phân đoạn như: `, ; : .`

* Dùng quy hoạch động để tìm tập ranh giới tối ưu

* Dùng heuristic để điều chỉnh ranh giới sao cho tối ưu hơn (optional)


=> Với những doc thiếu obvious breakers nảy sinh bài toán bổ xung breakers (`, .`)

=> Hoặc dễ hơn là phát hiện breaker mềm ví dụ như obvious word boundaries, khi dùng word boundaries nên kết hợp với phân đoạn trùm mí để handle edge cases.


### PHƯƠNG ÁN 2 (không hấp dẫn)

Giả sử với mọi `2..4-syllable words` trong từ điển ta liệt kê mọi bi-grams (2-syllables) và index hết các bi-grams đó thì sao?

Với ví dụ trên thì bi-gram "xanh-xanh" ko có mặt trong text "xanh lá màu xanh" nên không match với input "xanh xanh".

Chỉ giữ lại khoảng 32k bi-gram đại diện cho từ điển mà có tuần suất xuất hiện trong corpus là cao nhất.


### Với lượng dữ liệu nhỏ như Phaps thì:

7500 đoạn văn bản, mỗi đoạn dài 10 dòng, mỗi dòng khoảng 20 âm tiết.

* doc_id: `u13`
* token_id `u15`
* word_pos_flag per token per doc_id: `u4`
* số phân đoạn mỗi đoạn văn bản giả sử là 8
* mỗi doc chứa khoảng 200 tokens và có 32 uniq tokens (2^5)

=> Dung lượng inverted index chưa sử dụng các kỹ thuật nén bits là:

`2^5 * 2^13 * 2^3 * 0.5-byte` =
`2^20 bytes` = `2^10 kBs` = `1 mB`

=> Quá OK để nhúng vào wasm !!!

Lưu ý: con số trên chỉ là phỏng đoán chưa có căn cứ. Cần làm thật để có con số chính xác.
