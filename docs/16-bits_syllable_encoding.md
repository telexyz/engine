## `syllable_data_structs.zig`

### Compact `am_cuoi + tone` to `6-bits`

`62 = 13*6 - 4*4` // 4 âm cuối `c,ch,p,t` ko dùng 4 thanh `_none,f,r,x`
=> 62 slots to store `am_cuoi + tone` combinations (__lucky :D__)

### Final results

Total: 16-bits

    // 26 đầu           5-bits (dư 6-slots)
    // 27 giữa          5-bits (dư 5-slots)
    // 62 cuối + tone   6-bits (dư 2-slots)

Tổng số slots `65_536 = 2^16`
Số slots dùng `43_524 = 26*27*62`
Số slots dư   `22_012` đủ để chứa OOV (dùng BPE)

Như vậy chỉ cần `16-bits` là đủ để chứa `vocab` tiếng Việt viết thường (lowercase) + OOV

- - -

### Thử rút gọn `âm_cuối`

    // 13 âm cuối
    _none,    
    i,      ai      ưi  ui     oi  ôi
    y,      ay  ây
    u,      au  âu  ưu  iu êu 
    o,      ao             eo
    m,      am 
    n,      an
    nh,     anh  ênh  inh
    ng,     ang  êng       ung  ưng  eng  âng  ong  ông  ương  iêng
    ch,     ach  êch  ich
    c,      ac   êc        uc   ưc   ec   âc   oc   ôc   ươc   iêc
    p,      ap
    t,      at
a =>  a,  ah
ê => ez, ezh

Thêm 2 âm giữa `ah, ezh`
Thay thế `a y => ah i`, `az y => az i`
         `a o => ah u`, ` e o =>  e u`

         `a  nh => ah  ng`,  `a  ch => ah  c`
         `i  nh => i   ng`,  `i  ch => i   c`
         `ez nh => ezh ng`,  `ez ch => ezh c`
...
=> âm cuối bỏ được `y,o,nh,ch`, còn 9 âm cuối (âm cuối + tone <= `38 = 9*6 - 3*4`)

=> Vẫn cần 16-bits nhưng dư nhiều slots hơn

    // 26 đầu           5-bits (dư 06-slots)
    // 29 giữa          5-bits (dư 03-slots)
    // 42 cuối + tone   6-bits (dư 22-slots)

Tổng số slots `65_536 = 2^16`
Số slots dùng `31_668 = 26*29*42`
Số slots dư   `33_868` thoải mái chứa OOV (dùng BPE)
