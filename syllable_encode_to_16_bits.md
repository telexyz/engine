## `syllable_data_structs.zig`

    // 28 âm đầu, 5-bits
    // 30 âm giữa, 5-bits

`10-bits` needed for `am_dau + am_giua`

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

a => a, ah
ê => ez, ezh

    // 6 thanh
    _none,
    f,
    r,
    x,
    s,
    j,

### Thử rút gọn `âm_cuối`

Thêm 2 âm giữa `ah, ezh`
Thay thế `a y => ah i`, `az y => az i`
         `a o => ah u`, `e o => e u`

         `a  nh => ah  ng`,  `a  ch => ah  c`
         `i  nh => i   ng`,  `i  ch => i   c`
         `ez nh => ezh ng`,  `ez ch => ezh c`
...
=> âm cuối bỏ được `y,o,nh,ch`, còn 9 âm cuối


### Compact `am_cuoi + tone` to `6-bits`

`62 = 13*6 - 4*4` // 4 âm cuối `c,ch,p,t` ko dùng 4 thanh `_none,f,r,x`

=> 62 slots to store `am_cuoi + tone` combinations (__lucky :D__)

0000 000
0001 001
.... ...
1100 101

