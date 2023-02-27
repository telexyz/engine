// https://github.com/lemire/Code-used-on-Daniel-Lemire-s-blog/blob/master/2018/08/15/src/main/java/me/lemire/microbenchmarks/algorithms/HashFast.java

const a1: u64 = 0x65d200ce55b19ad8;
const b1: u64 = 0x4f2162926e40c299;
const c1: u64 = 0x162dd799029970f8;
const a2: u64 = 0x68b665e6872bd1f4;
const b2: u64 = 0xb6cfcf9d79b51db2;
const c2: u64 = 0x7a2b92ae912898c2;

pub fn hash32_1(x: u64) u32 {
    var low = @truncate(u32, x);
    var high = @truncate(u32, x >> 32);
    return @truncate(u32, (a1 *% low + b1 *% high + c1) >> 32);
}
pub fn hash32_2(x: u64) u32 {
    var low = @truncate(u32, x);
    var high = @truncate(u32, x >> 32);
    return @truncate(u32, (a2 *% low + b2 *% high + c2) >> 32);
}
pub fn hash64(x: u64) u64 {
    var low = x;
    var high = x >> 32;
    return ((a1 *% low + b1 *% high + c1) >> 32) |
        ((a2 *% low + b2 *% high + c2) & 0xFFFFFFFF00000000);
}
