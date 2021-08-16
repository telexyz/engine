## `syllable_data_structs.zig`

### Compact `am_cuoi + tone` to `6-bits`

`62 = 13*6 - 4*4` // 4 âm cuối `c,ch,p,t` ko dùng 4 thanh `_none,f,r,x`
=> 62 slots to store `am_cuoi + tone` combinations (__lucky :D__)

### Final results

Total: 16-bits

    // 25 đầu           5-bits
    // 23 giữa          5-bits
    // 62 cuối + tone   6-bits

Tổng số slots `65_536 = 2^16`
Số slots dùng `35_650 = 25*23*62`
Số slots dư   `29_886` dư chứa OOV (dùng BPE)

Như vậy chỉ cần `16-bits` là đủ để chứa `vocab` tiếng Việt viết thường (lowercase) + OOV

- - -

### Thử rút gọn `âm_cuối`

    // 13 âm cuối
    _none,
    i,      ai      ưi  ui     oi  ôi    oái
    y,      ay  ây                       oáy   uây
    u,      au  âu  ưu  iu  êu                 iêu
    o,      ao              eo
    m,      am 
    n,      an
    nh,     anh  ênh  inh
    ng,     ang            ung  ưng  eng  âng  ong  ông  ương  iêng
    ch,     ach  êch  ich
    c,      ac   êc        uc   ưc   ec   âc   oc   ôc   ươc   iêc
    p,      ap
    t,      at

Thay thế:

     a  y =>  aw i
     az y =>  az i
    oa  y => oaw i
    uaz y => uaz i

    a o => aw u
    e o =>  e u

    a  nh => aw  ng
    i  nh => i   ng
    ez nh => ez  ng

=> âm cuối bỏ được `y,o,nh`, còn 10 âm cuối (âm cuối + tone <= `44 = 10*6 - 4*4`)

=> Vẫn cần 16-bits nhưng dư nhiều slots hơn

    // 25 đầu           5-bits
    // 23 giữa          5-bits
    // 44 cuối + tone   6-bits

Tổng số slots `65_536 = 2^16`
Số slots dùng `26_400 = 25*23*44`
Số slots dư   `40_236` thoải mái chứa OOV (dùng BPE)
