## Rút gọn `âm_cuối`

    i,      ai        oái
    y,  -   ay   ây   oáy   uây

    u,      au
    o,  -   ao   eo   oao   oeo

Thay thế:

y/

     a  y =>  aw i
     az y =>  az i
    oa  y => oaw i
    uaz y => uaz i

o/

     a o => aw u
     e o =>  e u
    oa o => oa u
    oe o => oe u

!! Cách thay này phù hợp với phiên âm quốc tế [2/] !!

                      OANH HOÀNG HOẰNG
    ng,     ang             oang  oăng                iêng
    nh, -?  anh  ênh  inh   oanh         uênh  uynh

    c,      ac              oác   oặc                 iêc
    ch, -?  ach  êch  ich   oách         uệch  uỵch  

nh?
     ez nh =>  ez ng
     i  nh =>  i  ng
    uez nh => uez ng
    uy  nh => uy  ng

     anh? !=> aw ng
    oanh? !=> oă ng

ch?
     ez ch =>  ez c
     i  ch =>  i  c
    uez ch => uez c
    uy  ch => uy  c

     ach? !=> aw c
    oách? !=> oắ c


`nh? ch?` có thể giải quyết được bằng cách giới thiệu 2 nguyên hỗ trợ `ah, oah`

     ez nh =>  ez ng
     i  nh =>  i  ng
    uez nh => uez ng
    uy  nh => uy  ng
     a  nh =>  ah ng
    oa  nh => oah ng

     ez ch =>  ez c
     i  ch =>  i  c
    uez ch => uez c
    uy  ch => uy  c
     a  ch =>  ah c
    oa  ch => oah c


## Result

Âm cuối bỏ được `y, o`, còn 11 âm cuối.
Thêm 2 nguyên âm để, bỏ được `ch, nh` bớt được còn 9 âm cuối. 
3 âm cuối `c, p, t` chỉ có 2 thanh đi cùng nên `âm cuối + tone = 42`(=6*6+3*2)

     25 đầu
     25 giữa (23 + 2)
     42 cuối + tone

Tổng số slots `32_768 = 2^15`
Số slots dùng `26_250 = 25*25*42`
Số slots dư    `6_518`


## Trường hợp cần hỗ trợ viết không dấu

Cần thêm nguyên âm `uo` để chứa dạng không dấu của `uoz, uow` => `26 giữa`
3 âm cuối `c, p, t` mang được phép đi dùng thanh 0 nữa => `cuối + tone = 45`

Tổng số slots `32_768 = 2^15`
Số slots dùng `29_250 = 25*26*45`
Số slots dư    `3_518`


## REFs

[1/ Liệt kê cách đánh vần tiếng Việt đầy đủ các âm vị](https://sites.google.com/site/sachquocngu/chuong-5/bai-75)


[2/ Các vần trong tiếng Việt](https://vi.wikipedia.org/wiki/Âm_vị_h%E1%BB%8Dc_tiếng_Việt#.C3.82m_ti.E1.BA.BFt_v.C3.A0_s.E1.BA.AFp_x.E1.BA.BFp_.C3.A2m)

[3/ All syllables in Vietnamese](http://www.hieuthi.com/blog/2017/03/21/all-vietnamese-syllables.html)