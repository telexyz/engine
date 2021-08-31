# Kết luận

Tập trung dùng hash-table vì đây là CTDL tối ưu cho mem và lookup speed. (xem thêm phần phân tích về IMF trie ở dưới).

Dùng `u64`: `hash + fingerprint` thay vì giá trị thật của n-gram, và thêm `u24` để count. Để chứa 158m 1..6-grams với capacity isPowerOfTwo `2^27 ~= 134m` thì sẽ cần khoảng 1.3Gb để chứa.
=> Cần tỉa bớt 24m grams có count == 1

Kết hợp thêm fast-filter để tiền xử lý nữa sẽ giúp tăng tốc ??%
!!! => Cần làm thử nghiệm để tính độ hiệu quả !!!

## Thử vài hàm hash khác nhau để tạo fingerprint tốt hơn

https://pvk.ca/Blog/2020/08/24/umash-fast-enough-almost-universal-fingerprinting


## hash slots and key value

Với 2..8-grams ta có tổng 241m uniq items (2^27 < 241m < 2^28)
=> Tối thiểu hash slots phải là `u28`

key value với 2-gram có thể fit vào `u28` tức là key value có thể được map trực tiếp vào hash slots.

Với n >= 3 thì cần hash function để map key value và hash slot và tìm cách để lưu trữ giá trị của key value sao cho hiệu quả.

2^28 = 2^8 x 2^10 x 2^10 = 256M already! Mỗi slot phải chứa count là `u32` tức là 4-bytes, chứa thêm key value giả sử là `u64` tức là 8-bytes, tổng 12-bytes.
=> Tổng bộ nhớ cần tối thiểu là khoảng 3Gb.


## Bảng băm và Trie

Bảng băm vô cùng quyền lực, bảng băm mạnh nhất hiện nay là robin hood hashing dựa trên open-address và đảm bảo ô ghi giá trị không quá xa ô băm.

Mọi bảng băm đều hoạt động dựa trên giả thiết hàm băm mang tính ngẫu nhiên cao và càng gần với ngẫu nhiên thật sự càng tốt. Vì thế nên hàm băng cũng được dùng để sinh ra số ngẫu nhiên.

!!! Với từ tiếng dân tộc, từ vay mượn / tiếng nước ngoài, từ lạ (teen code) không thể phân tích ngữ âm để quy về âm tiết tiếng Việt thì việc dùng bảng băm là bắt buộc !!!

Trie có điểm yếu là khi n-gram càng dài thì việc tra cứu càng lâu, với 4-gram, mỗi gram dài 3 nodes thì làm đi hết 12 nodes mới tìm đến node chứa count của gram đó (độ sâu của cây là 12). Các node phân bố ngẫu nhiêu không tuyến tính nên cache miss và ram seek là chuyện bình thường.

Như vậy (gần như chắc chắn) Trie sẽ tốn mem và lookup lâu hơn hash-table. Mỗi lần chuyển node là 1 làm ram seek, với độ sâu trung bình 12 giả sử tổng số node = 6 x |n-grams|, mỗi node phải chứa trung bình 3 con trỏ (3 x u64) như vậy tổng mem sẽ vượt khỏi ram.

- - -

Với n-gram âm tiết tiếng Việt thì sự sắp xếp là có quy luật ví dụ: 
word = syllable + syllable + syllable + ...
syllable = initial + middle + final_tone

Số lượng syllable thường dùng là 12k.

Bảng băm tổng quát không sử dụng được tính chất có quy luật này của n-gram. Trong trường hợp này nên thử trie. Trie còn hỗ trợ prefix lookup, hash table không làm được.

Thực chất trie cũng là 1 cách băm tận dụng tính chất lặp lại có quy luật. Nếu băm theo syllable thì tốc độ chậm vì số lượng node.children cao. Băm theo ký tự thì độ cao của cây là 6 (trung bình 6 ký tự / âm tiết), số lượng children cũng không ít vì TV gồm a-z và các kí tự có dấu:
 
 * 16 phụ âm `q,r,t,p,s,d,g,h,k,l,x,c,v,b,n,m`
 * 12 nguyên âm không thanh `a,â,ă,e,ê,y,u,ư,i,o,ô,ơ`
 * 60 nguyên âm có dấu (tổ hợp 5 dấu với 12 nguyên âm)

=> Tổng 88 ký tự


Dùng cách trình bày kiểu telex thì:

* 16 phụ âm `q,r,t,p,s,d,g,h,k,l,x,c,v,b,n,m`
* 06 nguyên âm không dấu `a,e,y,u,i,o`
* 01 ký tự hỗ trợ bỏ dấu `w`
* 02 ký tự hỗ trợ bỏ thanh `f,j`

=> Tổng 25 ký tự

Cách trình bày kiểu telex làm độ dài từ tăng lên trung bình gần 2 ký tự so với cách trình bày utf-8. Tức là khiến cây tìm kiếm càng dài hơn nữa. Trung bình 8 ký tự / âm tiết

Dùng phân tích ngữ âm để tách và cô động lại âm tiết TV thành initial, middle, final_tone. Số lượng initial là 25, middle là 25, final_tone là 42. Độ cao của cây là 3 cho mỗi âm tiết.

Tạo 3 loại nodes:

* InitialNode: mảng children 25 con trỏ tới MiddleNode
* MiddleNode: mảng children 42 con trỏ tới FinalNode
* FinalNode: mảng children 25 con trỏ tới InitialNode và `u32` đếm số lần xuất hiện

=> IMF Trie :D


## Tham khảo

https://programming.guide/robin-hood-hashing.html

https://martin.ankerl.com/2016/09/21/very-fast-hashmap-in-c-part-2

https://pvk.ca/Blog/2019/09/29/a-couple-of-probabilistic-worst-case-bounds-for-robin-hood-linear-probing

https://en.wikipedia.org/wiki/Binary_search_algorithm#Hashing

For implementing associative arrays, hash tables, a data structure that maps keys to records using a hash function, are generally faster than binary search on a sorted array of records. Most hash table implementations require only amortized constant time on average.

However, hashing is not useful for approximate matches, such as computing the next-smallest, next-largest, and nearest key, as the only information given on a failed search is that the target is not present in any record.