## Large Text File Compression

Tìm hiểu cách nén / giải nén utf-8 hiệu quả, để giảm dung lượng file đầu vào, có thể add vào git repo hoặc / và đọc trực tiếp thông tin từ đó dễ dàng.

Unicode data file compression: achieving 40-70% reduction over gzip alone
https://devlog.hexops.com/2021/unicode-data-file-compression

- - -

## 7z: 22%, tốc độ tốt
https://www.7-zip.org/download.html
```sh
brew install p7zip
7z a -mx5 fb_comments_10m.txt.7z fb_comments_10m.txt
7z a -mx5 corpus-title.txt.7z corpus-title.txt
7z a -mx5 best_vi_translation_train.txt.7z best_vi_translation_train.txt
```

- - -

## Cách dùng displayable ascii chars để mã hóa con số

```js
/0-9: 47,48-57 => 11
@A-Z: 64,65-90 => 27
 a-z: 97-122   => 26
Total = 64 (2^6)
```

## 1/ 04 ascii không có trong âm tiết utf8
```js
'f':00110
'j':01010
'w':10111
'z':11010
// => 3 phép so sánh để phân biệt
x0110 => f
x1010 => j,z
x0111 => w
```
## 2/ 06 ascii nguyên âm
```js
'a':00001
'e':00101
'i':01001
'o':01111
'u':10101
'y':11001
// => 4 phép so sánh để biết xem ascii có phải là nguyên âm hay ko?
00001 => a
x0101 => e,u
x1001 => i,y
x1111 => o
```
## 3/ Các ascii còn lại trong bảng chữ cái sau khi bỏ 1/ và 2/
```js
0000 => p
0001 => q
0010 => b,r
0011 => c,s
0100 => d,t
0101 => u
0110 => v
0111 => g
1000 => h,x
1011 => k
1110 => n
1101 => m
1110 => n
```
## Phụ âm chỉ có thể đứng đầu âm tiết, ko đứng ở vị trí khác
```js
'b':00010
'd':00100
'k':01011
'l':01100
'q':10001
's':10011
'v':10110
'x':11000
```

## Phụ âm đứng thứ 2, mà ko phải đứng cuối (at > 2kt) chỉ có thể là
```js
h,g,r
```
## Đứng cuối âm tiết ko là nguyên âm chỉ có thể là
```js
'c':00011
'g':00111
'h':01000
'm':01101
'n':01110
'p':10000
't':10100
```

[ DONE ]

https://design215.com/toolbox/ascii-utf8.php
ASCII Characters 128-255 must be represented as multi-byte strings in UTF-8

```
[ ký-tự:số-bytes-thực-tế ]

à2 á2 ã2 â2 ă2 è2 é2 ê2 ì2 í2 ị3 ỉ3 ĩ2 ò2 ó2 ọ3 ỏ3 õ2 ô2 ơ2 ù2 ú2 ụ3 ủ3 ũ2 ư2 ỳ3 ý2 ỵ3 

ỷ3 ỹ3 ạ3 ả3 ẹ3 ẻ3 ẽ3 đ2 Đ2 Ầ3 Ấ3 Ậ3 Ẩ3 Ẫ3 Ằ3 Ắ3 Ặ3 Ẳ3 Ẵ3 Ề3 Ế3 Ệ3 Ể3 Ễ3 Ồ3 Ố3 Ộ3 Ổ3 Ỗ3 

Ờ3 Ớ3 Ợ3 Ở3 Ỡ3 Ừ3 Ứ3 Ự3 Ử3 Ữ3 ầ3 ấ3 ậ3 ẩ3 ẫ3 ằ3 ắ3 ặ3 ẳ3 ẵ3 ề3 ế3 ệ3 ể3 ễ3 ồ3 ố3 ộ3 ổ3 

ỗ3 ờ3 ớ3 ợ3 ở3 ỡ3 ừ3 ứ3 ự3 ử3 ữ3
```

=> Đủ chỗ để ghi đè lên dòng bytes utf-8 đầu vào mã hóa thay thế ascii-telex, dồn hết ký tự về cuối hoặc đầu tùy vào vị trí delimiters (ở đây là \s\t\n) ở trái hay phải âm tiết, ô nào thừa ghi đè ký tự space (32) vào. Làm như vậy ko phải cấp phát dữ liệu mới, ko phải copy dữ liệu từ đầu vào sang đầu ra.

- - -

Nhìn vào mã hóa đầy đủ của các ký tự có dấu trong tiếng Việt. Thấy hoàn toàn có cách lọc nhanh xem ký tự này có tone hay ko? Hoặc với 1 kt đầu vào dùng range ( <, >) là có thể lọc được xem ký tự đó ứng với khoảng các ký tự nào?

Sẽ cải thiện performance nếu làm dc điều trên.

```js
'À'2:195:128 'Á'2:195:129 'Â'2:195:130 'Ã'2:195:131 'È'2:195:136 'É'2:195:137 
'Ê'2:195:138 'Ì'2:195:140 'Í'2:195:141 'Ò'2:195:146 'Ó'2:195:147 'Ô'2:195:148 
'Õ'2:195:149 'Ù'2:195:153 'Ú'2:195:154 'Ý'2:195:157 
'à'2:195:160 'á'2:195:161 'â'2:195:162 'ã'2:195:163 'è'2:195:168 'é'2:195:169
'ê'2:195:170 'ì'2:195:172 'í'2:195:173 'ò'2:195:178 'ó'2:195:179 'ô'2:195:180
'õ'2:195:181 'ù'2:195:185 'ú'2:195:186 'ý'2:195:189

'ă'2:196:131 'Đ'2:196:144 'đ'2:196:145 'ĩ'2:196:169 'Ă'2:196:130  'Ĩ'2:196:168 
'ũ'2:197:169 'Ũ'2:197:168
'ư'2:198:176 'Ơ'2:198:160 'ơ'2:198:161 'Ư'2:198:175

'ả'3:225:186:163 'ẹ'3:225:186:185 'ẻ'3:225:186:187 'ẽ'3:225:186:189 'Ầ'3:225:186:166
'Ấ'3:225:186:164 'Ậ'3:225:186:172 'Ẩ'3:225:186:168 'Ẫ'3:225:186:170 'Ằ'3:225:186:176
'Ắ'3:225:186:174 'Ặ'3:225:186:182 'Ẳ'3:225:186:178 'Ẵ'3:225:186:180 'Ế'3:225:186:190
'ấ'3:225:186:165 'ậ'3:225:186:173 'ẩ'3:225:186:169 'ẫ'3:225:186:171 'ằ'3:225:186:177
'ắ'3:225:186:175 'ặ'3:225:186:183 'ẳ'3:225:186:179 'ẵ'3:225:186:181
'Ế'3:225:186:190 'ầ'3:225:186:167 'ế'3:225:186:191

'ụ'3:225:187:165 'ủ'3:225:187:167 'Ề'3:225:187:128 'ề'3:225:187:129 'ờ'3:225:187:157
'ọ'3:225:187:141 'ỏ'3:225:187:143 'ị'3:225:187:139 'ỉ'3:225:187:137 'ừ'3:225:187:171
'ỳ'3:225:187:179 'ỵ'3:225:187:181 'ỷ'3:225:187:183 'ỹ'3:225:187:185 'Ờ'3:225:187:156
'Ệ'3:225:187:134 'Ể'3:225:187:130 'Ễ'3:225:187:132 'Ồ'3:225:187:146 'Ừ'3:225:187:170
'Ố'3:225:187:144 'Ộ'3:225:187:152 'Ổ'3:225:187:148 'Ỗ'3:225:187:150
'Ớ'3:225:187:154 'Ợ'3:225:187:162 'Ở'3:225:187:158 'Ỡ'3:225:187:160
'Ứ'3:225:187:168 'Ự'3:225:187:176 'Ử'3:225:187:172 'Ữ'3:225:187:174
'ệ'3:225:187:135 'ể'3:225:187:131 'ễ'3:225:187:133 'ồ'3:225:187:147
'ố'3:225:187:145 'ộ'3:225:187:153 'ổ'3:225:187:149 'ỗ'3:225:187:151
'ớ'3:225:187:155 'ợ'3:225:187:163 'ở'3:225:187:159 'ỡ'3:225:187:161
'ứ'3:225:187:169 'ự'3:225:187:177 'ử'3:225:187:173 'ữ'3:225:187:175
```

- - -

## lz4: 40%, rất nhanh
```sh
brew install lz4
lz4 -3 fb_comments_10m.txt fb_comments_10m.txt.lz4
lz4 -3 fb_comments_10m_tknz.txt fb_comments_10m_tknz.txt.lz4
````

## ZPAQ: 20% nhưng quá chậm
https://peazip.github.io/maximum-compression-benchmark.html
ZPAQ is the winner in terms of maximum attainable compression, but is slower than other formats. ZPAQ at maximum compression level reached a 19.01% compression ratio versus 21.82% reached by ARC at maximum compression level, the second best result of the benchmark.
http://mattmahoney.net/dc/zpaq.html

```sh
mkdir zpaq715 && cd zpaq715
wget http://mattmahoney.net/dc/zpaq715.zip
unzip zpaq715.zip
make install

zpaq a fb_comments_10m.txt.zpaq fb_comments_10m.txt -m5
zpaq x fb_comments_10m.txt.zpaq
```
