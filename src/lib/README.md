## Third-party source code

Since Zig don't have official packpage management
Prefer to copy over the other people source code here to manage and modified.

* `lib/fastfilter` from https://github.com/hexops/fastfilter

* `hash_map.zig` from https://github.com/lithdew/rheia/blob/master/hash_map.zig

Bản độ lại `counting/hash_count.zig` chỉ để đếm số lần xuất hiện của n-gram, chỉ còn mảng giá trị được khởi tạo với capacity biết trước và 2 hàm get và put. Hash cũng rút gọn xuống `u32` dùng cityhash. Lưu `u22` fingerprint thay cho key. (fingerprint dùng 1 hàm hash khác). Dùng @rem() thay vì shift để map hash vào index.

Bản implement cuối dùng `u32` fingerprint với `u29` từ 1 hàm hash và `u3` là length của n-grams để `hash + fingerprint = u64` là đầu vào cho fast filter.