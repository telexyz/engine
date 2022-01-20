Hiện tại mọi syllables đều encode thành `u15` và còn dư khoảng `14k slots` để chứa OOS (out of syllables) nên mọi tokens đều có thể được encode thành `u15`.

Note: hiện tại chú trọng vào âm tiết và sau này mở rộng ra tokens, ưu tiên các lưu các OOS nguyên bản trong dict trước, phần còn lại dùng BPE để handle OOV.

Bộ từ điển tiếng Việt để tách từ sẽ gồm ít nhất 02 âm tiết nhiều nhất 04 âm tiết. Với các từ từ 05 âm tiết trở lên thường là từ kép sẽ tách được thành 2 từ đơn nhỏ hơn.

- - - 

Một cách biểu diễn đơn giản coi từ điển là một tập `4-grams [s0, s1, s2, s3]`, từ có 2 âm tiết nghĩa là s3, s4 = 0, từ có 3 âm tiết thì s4 = 0. Setting như vậy khi matching từ trái qua phải thì luôn ưu tiên matching từ có nhiều âm tiết hơn trước.

`4-grams = 64-bits (16 x 4) = u64` => Thỏa mãn việc làm keys trong https://github.com/hexops/fastfilter để tăng tốc đối sánh mẫu. `BinaryFuse(u16) dùng 19-bits per entry có 0.00001524 false-positive`, như vậy nếu khớp `1m mẫu` thì sẽ có `15 mẫu` là false-positive. Từ điển `100k chỉ chiếm 238kb` bộ nhớ. => Quá OK!


__LABELING__

Để đánh dấu một token là token thứ mấy của một từ ta dùng 4 giá trị sau:
* 0 token đầu tiên của từ trong từ điển
* 1 token thứ hai của từ trong từ điển
* 2 token thứ ba của từ trong từ điển
* 3 token thứ tư của từ trong từ điển
* ...

Khi matching có thể có nhiều cách gộp syllables thành words, hay nói cách khác 1 syllables có thể thuộc nhiều từ ta dùng `4-bits [flag0, flag1, flag2, flag3]` để đánh dấu xem token này có thể nằm ở vị trí thứ mấy của từ:
* flag_0 == 1 có thể là token đầu tiên của một từ trong từ điển
* flag_1 == 1 có thể là token thứ hai của một từ trong từ điển
* flag_2 == 1 có thể là token thứ ba của một từ trong từ điển
* flag_3 == 1 có thể là token thứ tư của một từ trong từ điển
* ...

- - -

Khi xét một `TokensChunk` có độ dài `n` để tìm ra cách nhóm `sylls2words` thì với mỗi cặp `token[i]` và `token[i+1]` cần xác định giữa chúng có phải là `word boundary` (a.k.a nhát cắt) hay không? Ta tính điểm cho từng nhát cắt:

1/ Có thể tính điểm dài từ `k_l = bonus * (l-1)` để `k_l` luôn hơn `log10(count)`. Điểm này chỉ hợp lệ khi `token[i-l]..token[i]` là một từ. Với bonus = 100 ta có:
* l = 1: k_1 =   0 (luôn luôn đúng, 0 điểm)
* l = 2: k_2 = 100 với đk token[i-1]..token[i] là một từ
* l = 3: k_3 = 200 với đk token[i-2]..token[i] là một từ
* l = 4: k_4 = 300 với đk token[i-3]..token[i] là một từ

2/ `log10(count(token[i-l+1]..token[i]))` của từ đó, thể hiện giữa 2 từ dài bằng nhau ưu tiên từ có tần suất xuất hiện nhiều hơn.

_Note_: Một từ xuất hiện ko quá 1 tỉ (9 số không => log10 < 9).

3/ Thêm một ưu tiên nữa sẽ bị phạt (penanty's point) nếu bỏ rơi một token để tránh trường hợp chạy theo từ dài mà bỏ qua những từ ngắn hơn.

```
score(i) = score(i-l)
	+ k_l(i)
	+ log10(count(token[i-l+1]..token[i]))
	- penanty * number_of_single_tokens_from(i-l+1..i)
```

Với cách tính điểm như trên có thể giải quyết bài toán bằng quy hoạch động (viberbi) hoặc tìm kiếm lưới (beam, a-star).

- - -

## Các thuật toán tìm kiếm lưới

Beam (bread first) vs A* (depth first) Heuristic Search
http://www.phontron.com/slides/nlp-programming-en-13-search.pdf

https://towardsdatascience.com/intuitively-understanding-connectionist-temporal-classification-3797e43a86c

- - -

[1] Thống kê từ điển thấy rằng từ tiếng Việt bao gồm: 
* 16% một âm tiết
* 71% hai âm tiết
* 13% là 3+ âm tiết
Nếu bỏ từ một âm tiết, thì số lượng 3+ âm tiết chiếm khoảng 15% (13 / 84)

[2] Thống kê file `data/VnVocab.txt`
* 28_522 từ 2 âm tiết
*  2_320 từ 3 âm tiết
*  2_831 từ 4 âm tiết
*    424   +5 âm tiết (phần lớn là thành ngữ, có thể tách nhỏ)
Số lượng 3+ âm tiết chiếm 15.1% (5.1k / 33.6k)

[3] Thống kê file [`data/wordlist.txt`](https://github.com/binhvq/vietdict106k)
* 64_220 từ 2 âm tiết
* 14_786 từ 3 âm tiết
* 10_258 từ 4 âm tiết
*  3_555   +5 âm tiết
Số lượng 3+ âm tiết chiếm 27.7% (25k / 90k)