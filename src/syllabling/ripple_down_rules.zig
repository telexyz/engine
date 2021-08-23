// Module: syll2words's ripple-down rules parser in Zig code
// Nguồn https://github.com/datquocnguyen/RDRsegmenter/blob/master/Model.RDR
//
// Chuyển thể bộ luật SCRDR (Single Classification Ripple-Down Rules) dùng để chỉnh sửa
// việc nhóm các âm tiết thành từ sau khi đã nhóm lần một (matching với từ điển).
// Cụ thể xem http://www.lrec-conf.org/proceedings/lrec2018/pdf/55.pdf

const std = @import("std");

pub const Tag = enum {
    N, // none
    B, // word's begin
    I, // word's inner
};

inline fn eq(a: []const u8, b: []const u8) bool {
    // eq: String Equal
    // tên hàm ngắn để luật if .. then ko bị quá dài
    // TODO: Sử dụng similar matching để có khả năng chịu / chữa lỗi chính tả
    return std.mem.eql(u8, a, b);
}

inline fn isQt(s: []const u8) bool {
    // isQT: isQuoteString
    // tên hàm ngắn để luật if .. then ko bị quá dài
    if (std.mem.eql(u8, s, "“")) return true;
    if (std.mem.eql(u8, s, "”")) return true;
    if (std.mem.eql(u8, s, "\"")) return true;
    return false;
}

pub fn parse(index: usize, syllables: []const []const u8, tags: []const Tag) Tag {
    // tên biến ngắn để luật if .. then ko bị quá dài
    const slb = syllables[index]; //     slb: current syllable
    const sp1 = syllables[index - 1]; // sp1: first previous syllable
    const sp2 = syllables[index - 2]; // sp2: second previous syllable
    const sn1 = syllables[index + 1]; // sn1: first next syllable
    const sn2 = syllables[index + 2]; // sn2: second next syllable

    const tag = tags[index]; //     tag: current syllable tag
    const tp1 = tags[index - 1]; // tp1: first previous syllable tag
    const tp2 = tags[index - 2]; // tp2: second previous syllable tag
    const tn1 = tags[index + 1]; // tn1: first next syllable tag
    const tn2 = tags[index + 2]; // tn2: second next syllable tag

    if (tag == .I) {
        if (eq(sp1, "quan|zj")) {
            if (eq(sp1, "quan|zj") and eq(slb, "huyen|zj")) return .I;
            if (eq(sp1, "quan|zj") and eq(slb, "uy|r")) return .I;
            return .B;
        }
        if (eq(sp1, "nguoi|wf") and eq(slb, "ta|")) {
            if (eq(slb, "ta|") and eq(sn1, "chia|") and eq(sn2, "ddat|zs")) return .I;
            if (eq(slb, "ta|") and eq(sn2, "bao|r")) return .I;
            return .B;
        }
        if (eq(sp1, "con|") and eq(slb, "gai|s")) return .B;
        if (eq(sp1, "chu|r") and eq(slb, "ddau|zf")) return .B;
        if (eq(sp2, "chat|zs") and eq(sp1, "ddoc|zj") and eq(slb, "da|")) return .B;
        if (eq(sp1, "tai|s") and eq(slb, "ddinh|j") and eq(sn1, "cu|w")) {
            if (eq(slb, "ddinh|j") and tn1 == .I and tn2 == .N) return .I;
            return .B;
        }
        if (eq(sp1, "thu|ws") and eq(slb, "hai|")) {
            if (eq(sn2, "tu|w")) return .I;
            return .B;
        }
        if (eq(sp1, "thi|f")) {
            if (eq(sp1, "thi|f") and eq(slb, "tham|zf")) return .I;
            if (eq(sp2, "") and eq(sp1, "thi|f") and eq(slb, "ra|")) return .I;
            if (eq(sp1, "thi|f") and eq(sn1, ",")) return .I;
            if (eq(sp2, "co|s") and eq(sp1, "thi|f") and eq(slb, "gio|wf")) return .I;
            if (eq(sp2, ",") and eq(slb, "ra|")) return .I;
            if (eq(sp2, "ra|") and eq(slb, "co|s")) return .I;
            if (eq(slb, "thao|f") and tn1 == .B) return .I;
            return .B;
        }
        if (eq(sp1, "con|") and eq(slb, "trai|")) return .B;
        if (eq(sp1, "pho|s")) {
            if (tp1 == .B and eq(slb, "mac|wj")) return .I;
            if (eq(slb, "thac|s")) return .I;
            if (eq(slb, "tien|zs") and eq(sn2, "va|f")) return .I;
            return .B;
        }
        if (eq(slb, "vn")) return .B;
        if (eq(sp1, "khu|") and eq(sn1, "nghiep|zj")) return .B;
        if (eq(sp1, "ty|")) return .B;
        if (eq(sp1, "tren|z") and eq(slb, "co|w")) return .B;
        if (tp2 == .I and tp1 == .B and eq(slb, "la|f")) {
            if (eq(sp1, "nghia|x") and eq(slb, "la|f")) return .I;
            if (eq(sp1, "lo|w") and eq(slb, "la|f")) return .I;
            if (eq(slb, "la|f") and eq(sn1, "chon|j")) return .I;
            if (eq(sp1, "hay|") and eq(sn1, "su|wj")) return .I;
            if (eq(slb, "la|f") and eq(sn1, "nhan|z")) return .I;
            if (eq(sn1, "chet|zs")) return .I;
            if (eq(slb, "la|f") and eq(sn1, ",")) return .I;
            if (eq(sp1, "tuc|ws") and eq(slb, "la|f")) return .I;
            if (eq(slb, "la|f") and eq(sn2, "thanh|f")) return .I;
            return .B;
        }
        if (eq(sp1, "thu|ws") and eq(slb, "ba|")) {
            if (eq(sp1, "thu|ws") and eq(slb, "ba|") and eq(sn1, "va|f")) return .I;
            return .B;
        }
        if (eq(sp2, "bat|ws") and eq(sp1, "ddau|zf") and eq(slb, "tu|wf")) {
            if (eq(sn2, "2002")) return .I;
            return .B;
        }
        if (tp1 == .B and eq(slb, "ddo|z") and tn1 == .I) return .B;
        if (eq(sp1, "nguoi|wf") and eq(slb, "o|wr")) return .B;
        if (eq(sp1, "co|s") and eq(slb, "gia|s")) {
            if (eq(sn2, "le|r")) return .I;
            if (eq(sn2, "ddong|zf")) return .I;
            return .B;
        }
        if (eq(slb, "ddieu|zf") and eq(sn1, "kien|zj")) {
            if (eq(sp1, "vo|z") and eq(sn1, "kien|zj")) return .I;
            return .B;
        }
        if (tp1 == .B and eq(slb, "gi|f") and tn1 == .B) {
            if (eq(sp1, "huong|zs") and eq(slb, "gi|f")) return .I;
            if (eq(sn1, "!")) return .I;
            if (eq(sp2, ",") and eq(sp1, "noi|s") and eq(slb, "gi|f")) return .I;
            if (eq(slb, "gi|f") and eq(sn2, "ruot|zj")) return .I;
            if (eq(slb, "gi|f") and eq(sn1, ",") and eq(sn2, "nhung|w")) return .I;
            if (eq(sp1, "lam|f") and eq(slb, "gi|f") and isQt(sn1)) return .I;
            if (eq(sp1, "thieu|zs")) return .I;
            if (eq(slb, "gi|f") and eq(sn1, "khong|z")) return .I;
            if (eq(sp1, "hen|f") and eq(slb, "gi|f")) return .I;
            return .B;
        }
        if (eq(sp1, "dduoc|wj")) {
            if (eq(sn1, ",")) return .I;
            if (eq(sp2, "nhung|w") and eq(sp1, "dduoc|wj") and eq(slb, "cai|s")) return .I;
            if (eq(sp1, "dduoc|wj") and eq(sn1, "thi|f")) return .I;
            if (tp2 == .N and tp1 == .B) return .I;
            if (tp2 == .I and tp1 == .B and eq(slb, "mua|f")) return .I;
            if (eq(sp1, "dduoc|wj") and eq(slb, "viec|zj") and isQt(sn1)) return .I;
            if (eq(sp2, "muon|zs") and eq(sp1, "dduoc|wj") and eq(slb, "viec|zj")) return .I;
            if (eq(sp1, "dduoc|wj") and eq(slb, "mua|f") and eq(sn1, "to|")) return .I;
            if (eq(sn2, "la|f")) return .I;
            return .B;
        }
        if (eq(sp1, "nguoi|wf") and eq(slb, "lam|f")) return .B;
        if (eq(sp1, "co|s") and eq(slb, "nghia|x")) return .B;
        if (eq(sp2, "thieu|zs") and eq(slb, "tu|wj")) return .B;
        if (eq(sp1, "ba|") and eq(slb, "thang|s")) {
            if (eq(sp1, "ba|") and eq(sn1, "hai|")) return .I;
            return .B;
        }
        if (eq(sp1, "truong|wr") and eq(slb, "phong|f")) {
            if (tp2 == .N and tp1 == .B) return .I;
            return .B;
        }
        if (eq(sp1, "cuc|j") and eq(slb, "truong|wr")) return .B;
        if (eq(sp1, "lam|f") and eq(slb, "chu|r")) {
            if (eq(slb, "chu|r") and eq(sn1, ",")) return .I;
            if (eq(slb, "chu|r") and eq(sn2, "thuc|ws")) return .I;
            if (eq(sp1, "lam|f") and eq(slb, "chu|r") and eq(sn1, "tinh|f")) return .I;
            return .B;
        }
        if (eq(sp1, "trong|") and eq(slb, "suot|zs")) {
            if (eq(sn1, ",")) return .I;
            return .B;
        }
        if (eq(sp1, "lam|f") and eq(slb, "cong|z")) {
            if (eq(sn1, "tru|wf")) return .I;
            return .B;
        }
        if (eq(sp1, "anh|") and eq(slb, "ta|")) return .B;
        if (eq(slb, "chien|zs") and eq(sn1, "tranh|")) {
            if (eq(sp1, "pham|j") and eq(slb, "chien|zs")) return .I;
            return .B;
        }
        if (eq(slb, "dan|z") and eq(sn1, "toc|zj")) return .B;
        if (eq(slb, "khong|z") and tn1 == .B and tn2 == .B) {
            if (eq(sn1, ",")) return .I;
            if (eq(sp1, "phong|f")) return .I;
            if (eq(sp2, "ty|") and eq(sp1, "hang|f") and eq(slb, "khong|z")) return .I;
            if (eq(sp2, "cang|r") and eq(slb, "khong|z")) return .I;
            if (eq(slb, "khong|z") and eq(sn2, "dduong|wf")) return .I;
            if (eq(slb, "khong|z") and eq(sn1, "bat|ws")) return .I;
            if (eq(sp2, "hang|x") and eq(sp1, "hang|f") and eq(slb, "khong|z")) return .I;
            if (eq(sp2, "ton|z") and eq(slb, "khong|z")) return .I;
            if (eq(sn2, "len|z")) return .I;
            if (eq(slb, "khong|z") and eq(sn1, "se|x")) return .I;
            if (eq(sn1, "o|wr")) return .I;
            if (eq(sp2, "gia|") and eq(sp1, "hang|f") and eq(slb, "khong|z")) return .I;
            return .B;
        }
        if (eq(slb, "sau|") and tn1 == .B) {
            if (eq(sp1, "truoc|ws")) return .I;
            if (eq(sp1, "mai|") and eq(sn1, ".")) return .I;
            if (eq(sp2, "vang|f")) return .I;
            if (eq(sp2, "minh|f")) return .I;
            if (eq(slb, "sau|") and eq(sn1, "chuyen|zr")) return .I;
            if (eq(slb, "sau|") and eq(sn1, "cung|x")) return .I;
            return .B;
        }
        if (eq(sp1, "ong|z") and eq(slb, "ta|")) return .B;
        if (eq(sp1, "vu|j") and eq(slb, "truong|wr")) return .B;
        if (eq(sp1, "anh|") and eq(slb, "ay|zs")) return .B;
        if (eq(sp1, "thuoc|zj") and eq(slb, "ddia|j")) {
            if (eq(sp1, "thuoc|zj") and eq(sn1, "phap|s")) return .I;
            if (eq(sp2, "truong|wf")) return .I;
            if (eq(sp2, "nuoc|ws") and eq(sp1, "thuoc|zj") and eq(slb, "ddia|j")) return .I;
            if (eq(sp2, "thoi|wf") and eq(sp1, "thuoc|zj") and eq(slb, "ddia|j")) return .I;
            return .B;
        }
        if (eq(sp1, "tien|zf") and eq(sn1, "dung|j")) return .B;
        if (eq(sp1, "nhu|w") and eq(sn1, "nay|f")) return .B;
        if (eq(sp1, "lam|f") and eq(slb, "bang|wf")) return .B;
        if (eq(sp1, "vien|zj") and eq(slb, "truong|wr")) return .B;
        if (tp1 == .B and eq(slb, "cua|r")) {
            if (eq(slb, "cua|r") and eq(sn1, "nhung|w") and eq(sn2, "dduoc|wj")) return .I;
            if (tn2 == .N) return .I;
            if (eq(slb, "cua|r") and eq(sn1, "nen|z")) return .I;
            return .B;
        }
        if (eq(sp1, "tinh|s") and eq(slb, "tu|wf")) return .B;
        if (eq(sp1, "co|s") and eq(slb, "tinh|f")) return .B;
        if (eq(sp1, "nua|wx") and eq(slb, "la|f")) {
            if (eq(slb, "la|f") and eq(sn1, "...") and isQt(sn2)) return .I;
            return .B;
        }
        if (eq(sp1, "ma|f") and eq(slb, "ca|r")) {
            if (eq(slb, "ca|r") and eq(sn1, "gia|")) return .I;
            return .B;
        }
        if (eq(sp1, "khu|") and eq(slb, "tap|zj")) return .B;
        if (eq(sp1, "may|s") and eq(slb, "ddien|zj")) {
            if (eq(sp2, "cho|")) return .I;
            return .B;
        }
        if (eq(sp1, "con|") and eq(slb, "heo|")) return .B;
        if (eq(sp1, "thu|ws") and eq(slb, "tu|w")) {
            if (eq(sn2, "thang|s")) return .I;
            return .B;
        }
        if (eq(sp1, "nha|f") and eq(slb, "chung|")) return .B;
        if (eq(slb, "bien|z") and eq(sn1, "gioi|ws")) return .B;
        if (eq(sp1, "tu|wf") and eq(slb, "dduong|wf")) return .B;
        if (eq(sp1, "khu|") and eq(slb, "che|zs") and eq(sn1, "xuat|zs")) {
            if (eq(sn2, "rong|zj")) return .I;
            return .B;
        }
        if (tp2 == .B and tp1 == .I and eq(slb, "truong|wr")) {
            if (eq(sp2, "tham|") and eq(slb, "truong|wr")) return .I;
            if (eq(sp2, "ke|zs") and eq(slb, "truong|wr")) return .I;
            return .B;
        }
        if (eq(sp1, "dde|zr") and eq(slb, "tro|wr")) return .B;
        if (eq(slb, "xe|") and eq(sn1, "bo|f")) return .B;
        if (tp1 == .B and eq(slb, "dduoc|wj")) return .B;
        if (tp1 == .B and eq(slb, "hom|z") and tn1 == .B) {
            if (eq(slb, "hom|z") and eq(sn1, "sau|") and eq(sn2, "(")) return .I;
            return .B;
        }
        if (eq(sp1, "goi|j") and eq(slb, "la|f")) {
            if (eq(sp1, "goi|j") and eq(slb, "la|f") and eq(sn1, "hang|")) return .I;
            if (eq(sp1, "goi|j") and eq(slb, "la|f") and eq(sn1, "luat|zj")) return .I;
            if (eq(sp2, "giong|zs")) return .I;
            if (eq(slb, "la|f") and eq(sn1, "su|wj") and eq(sn2, "nhiem|zx")) return .I;
            if (eq(sn2, "dduoc|wj")) return .I;
            if (eq(slb, "la|f") and eq(sn2, "mon|z")) return .I;
            if (eq(sp2, "anh|") and eq(sp1, "goi|j") and eq(slb, "la|f")) return .I;
            if (eq(sn2, "ddoc|zj")) return .I;
            if (eq(slb, "la|f") and eq(sn2, "thu|r")) return .I;
            if (eq(sn2, ";")) return .I;
            return .B;
        }
        if (eq(slb, "cuoc|zj") and eq(sn1, "song|zs")) return .B;
        if (eq(slb, "viet|zj") and eq(sn1, "nam|")) return .B;
        if (eq(sp2, "lon|ws") and eq(slb, "la|f")) return .B;
        if (eq(sp1, "chanh|s") and eq(slb, "van|w") and eq(sn1, "phong|f")) return .B;
        if (eq(slb, "vat|zj") and eq(sn1, "chat|zs")) return .B;
        if (eq(slb, "chi|") and eq(sn1, "phi|s")) return .B;
        if (eq(sp2, "thu|ws") and eq(slb, "la|f")) return .B;
        if (eq(sp1, "chuyen|zr") and eq(slb, "tien|zf")) {
            if (eq(sp2, "thu|w") and eq(sp1, "chuyen|zr") and eq(slb, "tien|zf")) return .I;
            return .B;
        }
        if (eq(sp2, "nhieu|zf") and eq(slb, "la|f")) return .B;
        if (eq(sp1, "len|z") and eq(slb, "mat|wj")) return .B;
        if (eq(slb, "thuc|wj") and eq(sn1, "hien|zj")) return .B;
        if (eq(sp1, "nen|z") and eq(slb, "nguoi|wf")) return .B;
        if (eq(sp1, "cao|") and eq(slb, "trinh|f") and eq(sn1, "ddo|zj")) return .B;
        if (eq(sp1, "cua|wr") and eq(slb, "nha|f")) return .B;
        if (eq(sp1, "hang|x")) return .B;
        if (eq(sp1, "xoa|s") and eq(slb, "mu|f")) return .B;
        if (eq(sp1, "nguyen|z") and eq(slb, "chu|r")) return .B;
        if (eq(sp1, "dduong|wf") and eq(slb, "day|z") and eq(sn1, "ddien|zj")) {
            if (eq(slb, "day|z") and eq(sn2, "thoai|j")) return .I;
            return .B;
        }
        if (eq(slb, "luat|zj") and eq(sn1, "to|zs") and eq(sn2, "tung|j")) return .B;
        if (eq(sp2, "trieu|zj") and eq(slb, "tien|zf")) return .B;
        if (eq(sp1, "biet|zs") and eq(sn1, "gio|wf")) return .B;
        if (eq(slb, "rieng|z") and eq(sn1, "le|r")) return .B;
        if (eq(slb, "the|zr") and eq(sn1, "hien|zj")) {
            if (eq(slb, "the|zr") and eq(sn2, "nay|")) return .I;
            return .B;
        }
        if (eq(sp1, "tay|") and eq(slb, "cam|zf")) return .B;
        if (eq(sp2, "cao|") and eq(slb, "la|f")) return .B;
        if (eq(slb, "hoc|j") and eq(sn1, "tap|zj")) return .B;
        if (eq(sp2, "so|wj") and eq(sp1, "nhat|zs") and eq(slb, "la|f")) return .B;
        if (eq(sp1, "thu|ws") and eq(slb, "nam|w")) {
            if (eq(sp2, "hom|z")) return .I;
            return .B;
        }
        if (eq(slb, "cong|z") and eq(sn1, "tac|s")) return .B;
        if (eq(slb, "van|zj") and eq(sn1, "chuyen|zr")) return .B;
        if (eq(sp1, "me|j") and eq(slb, "gia|f")) return .B;
        if (eq(sp1, "mat|wj") and eq(slb, "dduong|wf")) {
            if (eq(sp2, "hong|r")) return .I;
            if (eq(sp2, "nhua|wj") and eq(sp1, "mat|wj") and eq(slb, "dduong|wf")) return .I;
            return .B;
        }
        if (eq(sp1, "khi|")) return .B;
        if (eq(sp1, "ddang|")) return .B;
        if (eq(slb, "ly|s") and eq(sn1, "do|")) return .B;
        if (eq(slb, "nguyen|zx") and tn1 == .I) return .B;
        if (eq(sp1, "su|wj") and eq(slb, "bien|zs")) return .B;
        if (eq(slb, "mat|wj") and eq(sn1, "bang|wf")) return .B;
        if (eq(slb, "so|zs") and eq(sn1, "luong|wj")) return .B;
        if (eq(sp1, "quyen|zf") and eq(slb, "hanh|f")) return .B;
        if (eq(slb, "tp")) return .B;
        if (eq(sn1, "cao|s")) {
            if (tn1 == .B and tn2 == .I) return .I;
            return .B;
        }
        if (eq(slb, "chien|zs") and eq(sn1, "ddau|zs")) return .B;
        if (eq(sp1, "lam|f") and eq(slb, "hang|f")) return .B;
        if (eq(slb, "nuoc|ws") and eq(sn1, "ngot|j")) return .B;
        if (eq(sp1, "mot|zj") and eq(slb, "so|zs") and eq(sn1, "it|s")) return .B;
        if (eq(sp2, "ddung|ws") and eq(slb, "co|w")) return .B;
        if (eq(slb, "phuong|w") and eq(sn1, "an|s")) return .B;
        if (eq(slb, "che|zs") and eq(sn1, "bien|zs")) return .B;
        if (eq(sp1, "lam|f") and eq(slb, "ddau|zf")) return .B;
        if (eq(sp1, "so|zs") and eq(slb, "gia|")) return .B;
        if (eq(slb, "ddang|") and eq(sn2, "trien|zr")) return .B;
        if (eq(sp1, "con|") and eq(slb, "thu|ws")) return .B;
        if (eq(slb, "ddau|zf") and eq(sn1, "tien|z")) return .B;
        if (eq(sp1, "thu|") and eq(slb, "ngan|z") and eq(sn1, "sach|s")) return .B;
        if (eq(sp1, "ong|z") and eq(slb, "hoang|f")) return .B;
        if (eq(slb, "gia|s") and eq(sn1, "tri|j")) {
            if (eq(slb, "gia|s") and tn1 == .I) return .I;
            return .B;
        }
        if (eq(sp2, "cham|zj") and eq(slb, "la|f")) return .B;
        if (eq(slb, "may|s") and eq(sn1, "bay|")) return .B;
        if (eq(sp1, "vao|f") and eq(slb, "cau|zf")) return .B;
        if (eq(sp1, "ba|") and eq(slb, "bon|zs")) return .B;
        if (eq(slb, "vi|j") and eq(sn1, "tri|s")) return .B;
        if (eq(sp1, "lam|f") and eq(slb, "vi|f")) return .B;
        if (eq(sp1, "ai|") and eq(slb, "bao|r")) return .B;
        if (eq(slb, "khi|s") and eq(sn1, "tuong|wj")) return .B;
        if (eq(slb, "ke|zs") and eq(sn1, "hoach|j")) return .B;
        if (eq(sp1, "bao|s") and eq(sn1, "an|")) return .B;
        if (eq(sp2, "moi|zx") and eq(slb, "mot|zj")) return .B;
        if (eq(sp1, "sang|") and eq(slb, "nam|w")) return .B;
        if (eq(sp1, "chi|j") and eq(slb, "ta|")) return .B;
        if (eq(sp1, "tu|wf") and eq(slb, "thuc|wj")) return .B;
        if (eq(sp2, "ti|r") and eq(slb, "tien|zf")) return .B;
        if (eq(sp1, "nhu|w") and eq(slb, "the|zs") and eq(sn1, "la|f")) return .B;
        if (eq(sp1, "moi|ws") and eq(slb, "phai|r")) return .B;
        if (eq(slb, "tai|f") and eq(sn1, "xe|zs")) return .B;
        if (eq(sp1, "nguoi|wf") and eq(slb, "thuong|w")) {
            if (eq(sp1, "nguoi|wf") and eq(slb, "thuong|w") and isQt(sn1)) return .I;
            if (eq(sn1, "...")) return .I;
            return .B;
        }
        if (tp1 == .I and eq(slb, "tran|zf") and tn1 == .I) return .B;
        if (eq(sp1, "tu|wf") and eq(slb, "nguyen|z")) return .B;
        if (eq(sp1, "tong|zr") and eq(slb, "thu|") and eq(sn1, "nhap|zj")) return .B;
        if (eq(sp1, "con|") and eq(slb, "nha|f")) return .B;
        if (eq(sp1, "giay|f") and eq(slb, "an|") and eq(sn1, "giang|")) return .B;
        if (eq(sp1, "ra|") and eq(slb, "cong|z")) return .B;
        if (eq(slb, "nghiep|zj") and eq(sn1, "vu|j")) return .B;
        if (eq(sp1, "mot|zj") and eq(slb, "ddoi|z")) return .B;
        if (eq(sp1, "tieng|zs") and eq(slb, "ddong|zj") and eq(sn1, "co|w")) return .B;
        if (eq(sp1, "ban|s") and eq(slb, "nuoc|ws")) return .B;
        if (eq(sp2, "tot|zs") and eq(sp1, "nhat|zs") and eq(slb, "la|f")) return .B;
        if (eq(sp1, "ong|z") and eq(slb, "tu|wf")) return .B;
        if (eq(sp1, "nguoi|wf") and eq(slb, "dan|z") and eq(sn1, "ngheo|f")) return .B;
        if (eq(sp1, "cum|j") and eq(slb, "cang|r") and eq(sn1, "hang|f")) return .B;
        if (eq(sp1, "dduong|wf") and eq(slb, "bien|z") and eq(sn1, "ngang|")) return .B;
        if (eq(slb, "chi|") and eq(sn1, "tieu|z")) return .B;
        if (eq(slb, "vien|z") and eq(sn1, "chuc|ws")) return .B;
        if (eq(sp1, "ho|zf") and eq(slb, "thuy|r")) return .B;
        if (eq(slb, "thu|r") and eq(sn1, "thiem|z")) return .B;
        if (eq(sp1, "lai|j") and eq(slb, "nguoi|wf")) return .B;
        if (eq(sp2, "can|zf") and eq(slb, "la|f")) return .B;
        if (eq(sp1, "cham|zj") and eq(slb, "tien|zs") and eq(sn1, "ddo|zj")) return .B;
        if (eq(sp1, "ddo|zj") and eq(slb, "phi|f") and eq(sn1, "nhieu|z")) return .B;
        if (eq(slb, "tieu|z") and eq(sn1, "thu|j")) return .B;
        if (eq(sp1, "phu|r") and eq(slb, "chu|r")) return .B;
        if (eq(slb, "ha|f") and eq(sn1, "noi|zj")) return .B;
        if (eq(sp1, "tu|wf") and eq(slb, "can|w")) return .B;
        if (eq(slb, "mat|wj") and eq(sn1, "hang|f")) return .B;
        if (eq(sp1, "co|s") and eq(slb, "nhan|z")) return .B;
        if (eq(sp1, "con|") and eq(slb, "nguoi|wf") and eq(sn1, "o|wr")) return .B;
        if (eq(sp1, "nguoi|wf") and eq(sn1, "tuoi|zr")) return .B;
        if (eq(slb, "xe|") and eq(sn1, "khach|s")) return .B;
        if (eq(sp1, "thay|zs") and eq(slb, "ba|f")) return .B;
        if (eq(sp1, "tu|wj") and eq(slb, "quyet|zs") and eq(sn1, "ddinh|j")) return .B;
        if (eq(sp1, "co|z") and eq(slb, "bac|s") and eq(sn1, "si|x")) return .B;
        if (eq(sp1, "xe|") and eq(slb, "tai|r") and eq(sn1, "trong|j")) return .B;
        if (eq(sp2, "chi|r") and eq(sp1, "huy|") and eq(slb, "so|wr")) return .B;
        if (eq(sp1, "nguoi|wf") and eq(slb, "ngoai|f")) return .B;
        if (eq(sp1, "co|s") and eq(slb, "tuoi|zr")) return .B;
        if (eq(slb, "nuoc|ws") and eq(sn1, "ngoai|f")) return .B;
        if (eq(sp1, "nhu|w") and eq(sn1, "le|zj")) return .B;
        if (eq(sp1, "lam|f") and eq(slb, "bo|zj")) {
            if (eq(sp1, "lam|f") and eq(slb, "bo|zj") and eq(sn1, "ngac|j")) return .I;
            return .B;
        }
        if (eq(sp1, "su|wj") and eq(slb, "chu|r")) return .B;
        if (eq(slb, "cong|z") and eq(sn1, "bo|zs")) return .B;
        if (eq(sp1, "nuoc|ws") and eq(slb, "dung|f")) return .B;
        if (tp2 == .B and tp1 == .B and eq(slb, "truoc|ws")) {
            if (eq(sp1, "thue|zs") and eq(sn1, "ba|j")) return .I;
            if (isQt(sp2) and eq(slb, "truoc|ws")) return .I;
            if (eq(sp2, ",")) return .I;
            if (eq(slb, "truoc|ws") and eq(sn1, "nguoi|wf") and eq(sn2, "brâu")) return .I;
            if (eq(sp1, "ngay|f") and eq(slb, "truoc|ws") and eq(sn1, "cua|r")) return .I;
            return .B;
        }
        if (eq(slb, "xe|") and eq(sn1, "tai|r")) return .B;
        if (eq(sp1, "chat|zs") and eq(slb, "ddoc|zj") and eq(sn1, "hai|j")) return .B;
        if (eq(slb, "thue|zs") and eq(sn1, "thu|")) return .B;
        if (eq(sp1, "tu|wf") and eq(slb, "chuong|w") and eq(sn1, "trinh|f")) return .B;
        if (eq(sp1, "kim|") and eq(slb, "ddong|zf") and eq(sn1, "ho|zf")) return .B;
        if (eq(sp1, "hoi|zj") and eq(slb, "kien|zs") and eq(sn1, "truc|s")) return .B;
        if (eq(sp1, "nuoc|ws") and eq(slb, "giai|r") and eq(sn1, "khat|s")) return .B;
        if (eq(slb, "cao|") and eq(sn1, "nguyen|z")) return .B;
        if (eq(sp2, "ddieu|zf") and eq(sp1, "kien|zj") and eq(slb, "can|zf")) return .B;
        if (eq(sp1, "nhu|w") and eq(slb, "khong|z")) {
            if (eq(sn2, "")) return .I;
            return .B;
        }
        if (eq(slb, "dda|f") and tn1 == .I and tn2 == .B) return .B;
        if (eq(sp2, "la|s") and eq(sp1, "co|wf") and eq(slb, "ddo|r")) return .B;
        if (eq(sp2, "cu|ws") and eq(sp1, "the|zs") and eq(slb, "ma|f")) return .B;
        if (eq(sp1, "lua|s") and eq(sn1, "xuan|z")) return .B;
        if (eq(sp1, "so|zs") and eq(slb, "nhan|z")) return .B;
        if (eq(slb, "ddoan|f") and eq(sn1, "chu|r")) return .B;
        if (eq(slb, "hang|f") and eq(sn1, "xom|s")) return .B;
        if (eq(sp2, "nang|wj") and eq(slb, "la|f")) return .B;
        if (eq(sp1, "co|s") and eq(slb, "mang|")) return .B;
        if (eq(sp1, "cuc|j") and eq(slb, "tac|s") and eq(sn1, "chien|zs")) return .B;
        if (eq(sp1, "vung|f") and eq(sn1, "bien|zr")) return .B;
        if (eq(slb, "mat|wj") and eq(sn1, "dduong|wf")) return .B;
        if (eq(sp1, "ddoan|f") and eq(slb, "bo|zj")) return .B;
        if (tp2 == .B and tp1 == .B and eq(slb, "ii")) return .B;
        if (eq(slb, "thoi|wf") and eq(sn1, "gian|")) return .B;
        if (eq(sp1, "phai|r") and eq(slb, "cai|s")) return .B;
        if (eq(sp2, "") and eq(sp1, "dden|zs") and eq(slb, "noi|w")) return .B;
        if (eq(sp1, "tu|wf") and eq(slb, "thong|z")) return .B;
        if (eq(slb, "cong|z") and eq(sn1, "nhan|z")) return .B;
        if (eq(slb, "gia|s") and eq(sn1, "thanh|f")) return .B;
        if (eq(sp1, "so|zs") and eq(slb, "hoc|j")) return .B;
        if (eq(sp1, "nu|wx") and eq(sn1, "hung|f")) return .B;
        if (eq(slb, "thanh|f") and eq(sn1, "pho|zs")) {
            if (eq(sp1, "hinh|f")) return .I;
            return .B;
        }
        if (eq(slb, "thu|r") and eq(sn1, "tuong|ws")) return .B;
        if (eq(slb, "hanh|f") and eq(sn1, "chinh|s") and eq(sn2, "su|wj")) return .B;
        if (eq(slb, "the|zs") and eq(sn1, "thi|f")) return .B;
        if (eq(sp1, "ddanh|s") and eq(slb, "bong|s")) return .B;
        if (eq(sp1, "ddi|") and eq(slb, "o|wr")) return .B;
        if (eq(slb, "suc|ws") and eq(sn1, "manh|j")) return .B;
        if (eq(sp1, "tuoi|zr") and eq(slb, "toi|z")) return .B;
        if (eq(slb, "mat|wj") and eq(sn2, "cuc|wj")) return .B;
        if (eq(slb, "thu|w") and eq(sn2, "toa|f")) return .B;
        if (eq(sp1, "mot|zj") and eq(slb, "the|zr")) return .B;
        if (eq(sp2, "voi|ws") and eq(sp1, "con|") and eq(slb, "cai|s")) return .B;
        if (eq(sp1, "co|wf") and eq(slb, "quy|s")) return .B;
        if (eq(slb, "so|zs") and eq(sn1, "phan|zj")) return .B;
        if (eq(sp1, "ben|z") and eq(sn1, "ddon|w")) return .B;
        if (eq(sp1, "lai|s") and eq(slb, "xe|") and eq(sn1, "om|z")) return .B;
        if (eq(slb, "ddao|j") and eq(sn1, "dduc|ws")) return .B;
        if (eq(sp2, "nhung|wx") and eq(sp1, "nguoi|wf") and eq(slb, "yeu|z")) return .B;
        if (eq(slb, "sinh|") and eq(sn1, "vien|z")) return .B;
        if (eq(sp1, "len|z") and eq(slb, "con|w") and eq(sn1, "sot|zs")) return .B;
        if (eq(slb, "tu|wf") and eq(sn2, "-")) return .B;
        if (eq(slb, "kien|zs") and eq(sn1, "thuc|ws")) return .B;
        if (eq(sp1, "chinh|s") and eq(slb, "su|wj")) return .B;
        if (eq(sp1, "lai|j") and eq(slb, "giong|zs")) return .B;
        if (eq(sp1, "mau|f") and eq(sn1, "dden|")) return .B;
        if (eq(sp2, "dday|z") and eq(sp1, "nhat|zs") and eq(slb, "la|f")) return .B;
        if (eq(sp2, "kho|s") and eq(slb, "la|f")) return .B;
        if (eq(sp1, "thua|w") and eq(sn1, ",")) {
            if (eq(slb, "thot|ws")) return .I;
            return .B;
        }
        if (eq(slb, "chu|r") and eq(sn1, "luc|wj")) return .B;
        if (eq(sp1, "tram|w") and eq(sn1, "ddong|zf")) return .B;
        if (eq(sp1, "nghi|r") and eq(slb, "duong|wx") and eq(sn1, "suc|ws")) return .B;
        if (eq(sp1, "dden|zs") and eq(sn1, "o|wr")) return .B;
        if (eq(sp1, "dden|f") and eq(slb, "chieu|zs") and eq(sn1, "sang|s")) {
            if (eq(sp2, ",")) return .I;
            return .B;
        }
        if (eq(sp1, "roi|zf") and eq(slb, "ra|")) return .B;
        if (eq(sp1, "co|s") and eq(slb, "ddieu|zf") and eq(sn1, "chinh|r")) return .B;
        if (eq(sp1, "lam|f") and eq(slb, "viec|zj") and eq(sn1, "gi|f")) return .B;
        if (eq(slb, "co|wf") and eq(sn1, "quy|s") and eq(sn2, "ti|j")) return .B;
        if (eq(sp1, "gay|z") and eq(slb, "su|wj")) return .B;
        if (eq(slb, "huyet|zs") and eq(sn1, "mach|j")) return .B;
        if (eq(sp1, "nha|f") and eq(sn1, "mon|z")) {
            if (eq(sn2, ",")) return .I;
            return .B;
        }
        if (eq(sp1, "co|s") and eq(slb, "hoc|j")) return .B;
        if (tp1 == .I and eq(slb, "pho|s")) return .B;
        if (eq(sp2, "con|") and eq(sp1, "dduong|wf") and eq(slb, "dan|zx")) return .B;
        if (eq(sp1, "mo|wr") and eq(sn1, "bay|")) return .B;
        if (eq(slb, "tinh|f") and eq(sn1, "co|wf")) return .B;
        if (eq(slb, "sinh|") and eq(sn1, "song|zs")) return .B;
        if (tp2 == .B and tp1 == .B and eq(slb, "vao|f")) {
            if (isQt(sp2)) return .I;
            if (eq(sn1, "dday|zs")) return .I;
            if (eq(sp1, "ddau|zf") and eq(slb, "vao|f") and eq(sn1, "nam|w")) return .I;
            return .B;
        }
        if (eq(sp1, "cung|f") and eq(slb, "dan|z")) return .B;
        if (eq(sp1, "ba|") and eq(slb, "khong|z")) return .B;
        if (eq(sp2, "thang|s") and eq(slb, "hai|")) return .B;
        if (eq(sp2, "") and eq(sp1, "anh|") and eq(slb, "minh|")) return .B;
        if (eq(sp1, "khong|z") and eq(slb, "van|zj")) return .B;
        if (eq(sp1, "khong|z") and eq(slb, "ddau|z")) return .B;
        if (eq(sp1, "lua|s") and eq(slb, "he|f")) return .B;
        if (eq(sp1, "cap|zs") and eq(sn1, "sach|j")) return .B;
        if (eq(sp2, "dung|wj") and eq(sp1, "cho|wj") and eq(slb, "moi|ws")) return .B;
        if (eq(slb, "hoc|j") and eq(sn1, "sinh|") and eq(sn2, "mien|zf")) return .B;
        if (eq(sp1, "ra|") and eq(slb, "hieu|zj") and eq(sn1, "ung|ws")) return .B;
        if (eq(sp2, "") and eq(sp1, "anh|") and eq(slb, "vu|x")) return .B;
        if (eq(sp1, "tien|zf") and eq(slb, "tieu|z")) return .B;
        if (eq(slb, "chieu|zf") and eq(sn1, "qua|") and eq(sn2, "cau|zf")) return .B;
        if (tp1 == .B and eq(slb, "i|")) return .B;
        if (eq(sp2, "lo|") and eq(sp1, "nhat|zs") and eq(slb, "la|f")) return .B;
        if (tp1 == .B and eq(slb, "chua|w") and tn1 == .B) return .B;
        if (eq(sp2, "noi|s") and eq(sp1, "len|z") and eq(slb, "tieng|zs")) return .B;
        if (eq(sp1, "mat|wj") and eq(slb, "nuoc|ws") and eq(sn1, "bien|zr")) return .B;
        if (eq(sp1, "het|zs") and eq(slb, "ddoi|wf")) return .B;
        if (eq(sp1, "mart")) return .B;
        if (eq(sp1, "cham|j") and eq(sn1, "ddat|zs")) return .B;
        if (eq(sp1, "trong|") and eq(slb, "sang|s") and eq(sn1, "nay|")) return .B;
        if (eq(sp1, "dai|r") and eq(slb, "ddong|zf")) return .B;
        if (eq(sp1, "bat|zs") and eq(sn1, "thuong|wf")) return .B;
        if (eq(sp1, "chu|r") and eq(slb, "cong|z") and eq(sn1, "trinh|f")) return .B;
        if (eq(sp1, "loi|wf") and eq(sn1, "thich|s")) return .B;
        if (eq(sp1, "nga|x") and eq(slb, "nam|w")) {
            if (eq(slb, "nam|w") and eq(sn1, "va|f") and eq(sn2, "thanh|j")) return .I;
            return .B;
        }
        if (eq(sp1, "co|s") and eq(slb, "ddieu|zf") and eq(sn1, "gi|f")) return .B;
        if (eq(slb, "giai|r") and eq(sn1, "ddap|s")) return .B;
        if (eq(sp1, "mot|zj") and eq(sn1, "mau|zf")) return .B;
        if (eq(sp1, "dduong|wf") and eq(slb, "tau|f")) return .B;
        if (eq(slb, "cay|z") and eq(sn1, "cau|zf")) return .B;
        if (eq(sp1, "co|s") and eq(slb, "han|j") and eq(sn1, "ngach|j")) return .B;
        if (eq(slb, "thuoc|zs") and eq(sn1, "nam|")) return .B;
        if (eq(sp1, "nu|wx") and eq(sn1, "cuop|ws")) return .B;
        if (eq(sp1, "dden|zs") and eq(slb, "ddieu|zf")) return .B;
        if (eq(sp1, "tung|wf") and eq(slb, "lop|ws")) return .B;
        if (eq(sp1, "tu|wj") and eq(slb, "quan|r") and eq(sn1, "ly|s")) return .B;
        if (eq(sp1, "nuoc|ws") and eq(slb, "nang|wj")) return .B;
        if (eq(sp1, "tai|j") and eq(sn1, "ddinh|f")) return .B;
        if (eq(sp1, "nhieu|zf") and eq(slb, "chuyen|zj")) return .B;
        if (eq(sp1, "ba|") and eq(slb, "la|s")) return .B;
        if (eq(slb, "the|zr") and eq(sn1, "thao|")) return .B;
        if (eq(sp1, "dduong|wf") and eq(sn1, "ddo|r")) return .B;
        if (eq(sp2, "nho|r") and eq(sp1, "nhat|zs") and eq(slb, "la|f")) return .B;
        if (eq(sp1, "ra|") and eq(slb, "ddieu|zf")) return .B;
        if (eq(sp1, "cuoc|ws") and eq(slb, "van|zj")) return .B;
        if (eq(sp2, "thap|zs") and eq(slb, "la|f")) return .B;
        if (eq(sp1, "mat|zs") and eq(slb, "suc|ws") and eq(sn1, "lao|")) return .B;
        if (eq(sp1, "bao|s") and eq(slb, "noi|s")) return .B;
        if (eq(sp1, "mo|wr") and eq(slb, "cua|wr") and eq(sn1, "hang|f")) return .B;
        if (eq(sp1, "tai|") and eq(slb, "nghe|")) {
            if (eq(sn1, "mat|ws")) return .I;
            return .B;
        }
        if (eq(sp2, "ro|x") and eq(sp1, "nhat|zs") and eq(slb, "la|f")) return .B;
        if (eq(sp1, "ddien|zj") and eq(slb, "tu|wf")) return .B;
        if (eq(sp1, "het|zs") and eq(slb, "nuoc|ws")) return .B;
        if (eq(sp2, "") and eq(sp1, "rung|wf") and eq(slb, "nui|s")) return .B;
        if (eq(sp1, "dduong|wf") and eq(slb, "bien|z") and eq(sn1, "doc|j")) return .B;
        if (eq(slb, "so|wr") and eq(sn2, "tri|s")) {
            if (eq(sp2, "ve|zj") and eq(slb, "so|wr")) return .I;
            return .B;
        }
        if (eq(sp1, "nguoi|wf") and eq(sn1, "que|z")) return .B;
        if (eq(sp1, "cho|wj") and eq(sn1, "xay|z")) return .B;
        if (eq(slb, "xac|s") and eq(sn1, "ddinh|j")) return .B;
        if (eq(sp1, "nam|w") and eq(slb, "thang|s") and eq(sn1, "nay|")) return .B;
        if (eq(sp2, "") and eq(sp1, "anh|") and eq(slb, "son|w")) return .B;
        if (eq(slb, "tay|") and eq(sn1, "trai|s")) return .B;
        if (eq(sp1, "do|") and eq(sn1, "an|s")) return .B;
        if (eq(slb, "ra|") and eq(sn1, "dduong|wf")) return .B;
        if (eq(slb, "me|j") and eq(sn1, "con|")) return .B;
        if (eq(sp1, "nuoc|ws") and eq(slb, "rut|s") and eq(sn1, ".")) return .B;
        if (eq(sp1, "hoc|j") and eq(slb, "chinh|s")) return .B;
        if (eq(slb, "mat|wj") and eq(sn1, "tien|zf")) return .B;
        if (eq(sp1, "thanh|f") and eq(slb, "su|wj")) return .B;
        if (eq(sp1, "vao|f") and eq(slb, "dde|zf")) return .B;
        if (eq(sp1, "trong|zf") and eq(slb, "chuoi|zs")) return .B;
        if (eq(sp2, "nho|wf") and eq(slb, "ma|f")) {
            if (tn1 == .B and tn2 == .I) return .I;
            return .B;
        }
        if (eq(sp1, "het|zs") and eq(slb, "ddat|zs")) return .B;
        if (eq(sp1, "cty")) return .B;
        if (eq(slb, "cong|z") and eq(sn1, "vien|z")) return .B;
        if (eq(sp1, "nha|f") and eq(slb, "hao|r")) return .B;
        if (eq(sp2, "cua|r") and eq(sp1, "viec|zj") and eq(slb, "lam|f")) return .B;
        if (eq(sp1, "nguoi|wf") and eq(sn1, "")) return .B;
        if (eq(sp1, "la|f") and eq(slb, "cung|f")) {
            if (eq(slb, "cung|f") and isQt(sn1)) return .I;
            return .B;
        }
        if (eq(sp2, "goi|j") and eq(slb, "bao|s")) return .B;
        if (eq(slb, "chi|") and eq(sn1, "tra|r")) return .B;
        if (eq(slb, "bao|s") and eq(sn1, "tu|wr")) return .B;
        if (eq(sp1, "lam|f") and eq(sn1, "de|zx")) return .B;
        if (eq(slb, "ngay|f") and eq(sn1, "khac|s")) return .B;
        if (eq(slb, "phan|z") and tn1 == .B and tn2 == .B) return .B;
        if (eq(slb, "nang|w") and eq(sn1, "ddong|zj")) return .B;
        if (eq(sp1, "lam|f") and eq(slb, "chung|ws") and eq(sn1, "minh|")) return .B;
        if (eq(sp1, "nuoc|ws") and eq(slb, "trang|ws")) return .B;
        if (eq(sp2, "ddong|z") and eq(slb, "la|f")) return .B;
        if (eq(slb, "bac|s") and eq(sn1, "ho|zf")) return .B;
        if (eq(sp1, "thanh|f") and eq(sn1, "ty|")) return .B;
        if (tp2 == .B and tp1 == .I and eq(slb, "vuon|wf")) return .B;
        if (eq(sp1, "ddat|zs") and eq(slb, "mau|f") and eq(sn1, "mo|wx")) return .B;
        if (eq(slb, "tron|f") and eq(sn1, "nghia|x") and eq(sn2, "vu|j")) return .B;
        if (eq(slb, "nghin|f") and tn1 == .B and tn2 == .B) return .B;
        if (eq(sp1, "co|s") and eq(slb, "li|s") and eq(sn1, "do|")) return .B;
        if (eq(slb, "the|zs") and eq(sn1, "gioi|ws")) return .B;
        if (eq(slb, "hoa|f") and eq(sn1, "binh|f") and eq(sn2, "2004")) return .B;
        if (eq(sp1, "tuoi|zr") and eq(slb, "tre|r") and eq(sn1, "em|")) return .B;
        if (eq(sp2, "nuoi|z") and eq(slb, "nho|r")) return .B;
        if (eq(sp2, "") and eq(sp1, "anh|") and eq(slb, "tai|f")) return .B;
        if (eq(slb, "ddoi|zs") and eq(sn1, "tuong|wj")) return .B;
        if (eq(sp1, "ddao|f") and eq(slb, "sau|z")) {
            if (eq(slb, "sau|z") and eq(sn1, ",")) return .I;
            return .B;
        }
        if (eq(sp1, "tram|w") and eq(slb, "nam|w") and eq(sn1, "nay|")) return .B;
        if (eq(sp2, "hanh|f") and eq(sp1, "thanh|") and eq(slb, "kiem|zr")) return .B;
        if (eq(sp1, "tai|s") and eq(sn1, "xuat|zs")) return .B;
        if (eq(sp1, "nhu|w") and eq(sn1, "tra|")) return .B;
        if (eq(slb, "phu|j") and eq(sn1, "tro|wj")) return .B;
        if (eq(sp2, "mien|zf") and eq(sp1, "ddong|z") and eq(slb, "nam|")) return .B;
        if (eq(sp1, "vietsovpetro") and eq(sn1, "quoc|zs")) return .B;
        if (eq(slb, "cung|f") and eq(sn1, "cuc|wj")) return .B;
        if (eq(sp1, "cau|zf") and eq(slb, "noi|zs") and eq(sn1, "tiep|zs")) return .B;
        if (eq(sp2, "thi|f") and eq(sp1, "hay|") and eq(slb, "biet|zs")) return .B;
        if (eq(sp1, "pha|s") and eq(slb, "nuoc|ws") and isQt(sn1)) return .B;
        if (eq(sp2, "vuc|wj") and eq(sp1, "bac|ws") and eq(slb, "trung|")) return .B;
        if (eq(sp1, "nganh|f") and eq(slb, "hang|f") and eq(sn1, "khong|z")) return .B;
        if (eq(sp1, "khong|z") and eq(slb, "trung|") and eq(sn1, "thuc|wj")) return .B;
        if (eq(slb, "cau|zf") and eq(sn1, "khi|r")) return .B;
        if (eq(sp1, "lam|f") and eq(sn1, "dde|zf")) return .B;
        if (eq(sp2, "thich|s") and eq(sp1, "nhat|zs") and eq(slb, "la|f")) return .B;
        if (eq(slb, "toi|zs") and eq(sn1, "troi|wf")) return .B;
        if (eq(sp1, "khong|z") and eq(slb, "phan|zj") and eq(sn1, "su|wj")) return .B;
        if (eq(slb, "vien|zj") and eq(sn1, "phi|s")) return .B;
        if (eq(sp1, "giam|r") and eq(slb, "toc|zs") and eq(sn1, "ddo|zj")) return .B;
        if (eq(sp2, "") and eq(sp1, "thu|ws") and eq(slb, "sau|s")) return .B;
        if (eq(sp1, "dang|j") and eq(slb, "hinh|f")) return .B;
        if (eq(sp1, "chi|r") and eq(slb, "gioi|ws") and eq(sn1, "han|j")) return .B;
        if (eq(slb, "trong|j") and eq(sn1, "luong|wj")) return .B;
        if (eq(slb, "tuong|wr") and eq(sn1, "tuong|wj")) return .B;
        if (eq(sn1, "tap|ws")) return .B;
        if (eq(sp1, "mat|zs") and eq(sn1, "nho|ws")) return .B;
        if (eq(sp1, "co|zx") and eq(sn1, "quan|")) return .B;
        if (eq(sp1, "dduong|wf") and eq(slb, "mat|zj")) return .B;
        if (eq(sp1, "viec|zj") and eq(sn1, "an|w")) return .B;
        if (eq(slb, "gia|f") and eq(sn2, ",")) return .B;
        if (eq(slb, "khach|s") and eq(sn1, "san|j")) return .B;
        if (eq(slb, "ngat|zs") and eq(sn1, "nguong|wr")) return .B;
        if (eq(sp1, "nguoi|wf") and eq(sn1, "cau|zf")) return .B;
        if (eq(sp2, "3") and eq(slb, "tuoi|zr")) return .B;
        if (eq(slb, "vay|zj") and eq(sn2, "cai|s")) return .B;
        if (eq(slb, "mat|wj") and eq(sn1, "na|j")) return .B;
        if (eq(sp1, "nao|f") and eq(slb, "hay|")) return .B;
        if (eq(sp1, "wave")) return .B;
        if (eq(slb, "y|s") and eq(sn2, "cua|r")) {
            if (eq(slb, "y|s") and eq(sn1, "mua|")) return .I;
            return .B;
        }
        if (eq(sp1, "nhu|w") and eq(sn1, ":")) return .B;
        if (eq(sp2, "ba|") and eq(sp1, "ngay|f") and eq(slb, "nay|")) return .B;
        if (eq(slb, "my|x") and eq(sn1, "son|w")) return .B;
        if (eq(sp1, "khoan|s") and eq(slb, "san|r")) return .B;
        if (eq(sp2, "hai|") and eq(slb, "mot|zj")) return .B;
        if (eq(slb, "tam|z") and eq(sn1, "su|wj")) return .B;
        if (eq(sp1, "au|z") and eq(slb, "la|f")) return .B;
        if (eq(slb, "mot|zj") and eq(sn1, "so|zs")) return .B;
        if (eq(sp1, "cong|z") and eq(slb, "lao|") and eq(sn1, "ddong|zj")) return .B;
        if (eq(sp2, "manh|j") and eq(sp1, "ai|") and eq(slb, "nay|zs")) return .B;
        if (eq(sp1, "ong|z") and eq(slb, "manh|x")) return .B;
        if (eq(sp2, "hai|") and eq(slb, "nho|r")) return .B;
        if (eq(sp1, "nguoi|wf") and eq(sn1, "lang|f")) return .B;
        if (eq(sp2, "nam|w") and eq(sp1, "nam|w") and eq(slb, "tuoi|zr")) return .B;
        if (eq(slb, "le|z") and eq(sn1, "van|w")) return .B;
        if (eq(slb, "tieu|z") and eq(sn1, "huy|r")) return .B;
        if (eq(sp1, "co|s") and eq(slb, "hang|j") and eq(sn1, "muc|j")) return .B;
        if (eq(slb, "gioi|ws") and eq(sn1, "thieu|zj")) return .B;
        if (eq(sp1, "ong|z") and eq(slb, "gia|")) return .B;
        if (eq(sp1, "mon|z") and eq(slb, "sinh|") and eq(sn1, "lop|ws")) return .B;
        if (eq(sp2, "mot|zj") and eq(sp1, "ngay|f") and eq(slb, "mot|zj")) return .B;
        if (tp2 == .B and tp1 == .I and eq(slb, "phai|r")) return .B;
        if (eq(sp2, "buoc|ws") and eq(sp1, "vao|f") and eq(slb, "cuoc|zj")) return .B;
        if (eq(sp1, "co|s") and eq(sn1, "khoan|r")) return .B;
        if (eq(slb, "nghia|x") and eq(sn1, "trang|")) return .B;
        if (eq(sp1, "y|") and eq(slb, "duoc|wj") and eq(sn1, ",")) return .B;
        if (eq(sp1, "nam|") and eq(slb, "trung|") and eq(sn1, "quoc|zs")) return .B;
        if (eq(sp1, "tinh|f") and eq(slb, "thuong|w") and eq(sn1, "yeu|z")) return .B;
        if (eq(sp1, "bong|s") and eq(slb, "bay|")) return .B;
        if (eq(sp1, "tram|w") and eq(slb, "ngan|f") and eq(sn1, ".")) return .B;
        if (eq(sp1, "dda|s") and eq(slb, "vang|f")) return .B;
        if (eq(slb, "chu|r") and eq(sn1, "yeu|zs")) return .B;
        if (eq(slb, "phan|z") and eq(sn1, "phoi|zs") and eq(sn2, "duy|")) return .B;
        if (eq(sp1, "len|z") and eq(slb, "khuon|z")) return .B;
        if (eq(sp1, "cua|r") and eq(slb, "ddoc|zj")) return .B;
        if (eq(sp1, "co|s") and eq(slb, "an|w")) return .B;
        if (eq(sp1, "chua|ws") and eq(slb, "chat|zs")) return .B;
        if (eq(slb, "ddo|r") and eq(sn1, "ruc|wj")) return .B;
        if (eq(sp1, "cho|s") and eq(slb, "chet|zs")) return .B;
        if (eq(sp1, "ba|") and eq(slb, "chi|r")) return .B;
        if (eq(slb, "than|z") and eq(sn1, "quen|")) return .B;
        if (eq(sp1, "tang|w") and eq(sn1, "ddo|zj")) return .B;
        if (eq(sp1, "toan|f") and eq(slb, "luc|wj")) return .B;
        if (eq(slb, "cong|z") and eq(sn1, "so|wr")) return .B;
        if (eq(sp1, "tinh|f") and eq(slb, "yeu|z") and eq(sn1, "thuong|w")) return .B;
        if (eq(sp1, "con|") and eq(slb, "khi|r")) return .B;
        if (eq(sp1, "lon|ws") and eq(slb, "lao|") and eq(sn1, "ddong|zj")) return .B;
        if (eq(sp1, "sat|s") and eq(slb, "thuc|wj")) return .B;
        if (eq(sp1, "nhiem|zx") and eq(slb, "tu|wf")) return .B;
        if (eq(sp1, "phu|j") and eq(slb, "tu|wf")) return .B;
        if (eq(sp1, "xuong|zs") and eq(sn1, "roi|zf")) return .B;
        if (eq(sp1, "vo|z") and eq(sn1, "tam|z")) return .B;
        if (tp2 == .N and tp1 == .B and eq(slb, "bay|r")) return .B;
        if (eq(sp1, "to|zr") and eq(sn1, "tac|s")) return .B;
        if (eq(sp1, "ddi|") and eq(slb, "tu|") and eq(sn1, "nghiep|zj")) return .B;
        if (eq(sp1, "tieng|zs") and eq(slb, "la|f")) return .B;
        if (eq(sp1, "my|x") and eq(slb, "hoc|j")) return .B;
        if (eq(sp2, "may|zs") and eq(sp1, "ngay|f") and eq(slb, "nay|")) return .B;
        if (eq(sp2, "khong|z") and eq(sp1, "ai|") and eq(slb, "ngo|wf")) return .B;
        if (eq(slb, "ma|f") and eq(sn1, "con|f")) return .B;
        if (eq(sp1, "lai|j") and eq(slb, "qua|r")) return .B;
        if (eq(slb, "khi|") and eq(sn1, "khong|z")) return .B;
        if (eq(sp1, "dden|f") and eq(slb, "vang|f")) return .B;
        if (eq(slb, "sinh|") and eq(sn1, "nhat|zj")) return .B;
        if (eq(slb, "ddien|zj") and eq(sn1, "thoai|j")) return .B;
        if (eq(sp1, "nguyen|z") and eq(slb, "ddai|j")) return .B;
        if (eq(sp1, "trang|ws") and eq(slb, "trong|")) return .B;
        if (eq(sp1, "truc|wj") and eq(slb, "chi|r")) return .B;
        if (eq(slb, "dduong|wf") and eq(sn1, "bang|w")) return .B;
        if (eq(sp1, "con|") and eq(slb, "mot|zj")) return .B;
        if (eq(sp2, "") and eq(sp1, "anh|") and eq(slb, "hung|f")) return .B;
        if (eq(sp1, "vn")) return .B;
        if (eq(slb, "thoi|wf") and eq(sn1, "vu|j")) return .B;
        if (eq(slb, "phuong|w") and eq(sn1, "thuc|ws")) return .B;
        if (eq(sp1, "toi|ws") and eq(slb, "so|zs")) return .B;
        return .I;
    } else if (tag == .B) {
        if (eq(sp1, "tan|z")) {
            if (tp1 == .I) return .B;
            if (eq(sp2, "hoa|f")) return .B;
            if (tp1 == .B and eq(slb, ",")) return .B;
            if (eq(sp2, "ong|z")) return .B;
            if (eq(slb, "quan|") and tn1 == .B) return .B;
            if (eq(slb, "cuc|j") and tn1 == .I and tn2 == .B) return .B;
            if (tp1 == .B and eq(slb, "(")) return .B;
            return .I;
        }
        if (eq(sp1, "co|w") and eq(slb, "so|wr")) return .I;
        if (eq(sp1, "chau|z") and eq(slb, "a|s")) return .I;
        if (eq(sp1, "ddieu|zf") and eq(slb, "kien|zj")) return .I;
        if (eq(sp1, "gia|s") and eq(slb, "tri|j")) return .I;
        if (eq(sp1, "chau|z") and eq(slb, "au|z")) return .I;
        if (eq(sp1, "sea")) return .I;
        if (eq(sp1, "bac|s") and eq(slb, "ho|zf")) return .I;
        if (eq(sp1, "phuc|s") and eq(slb, "huy|")) return .I;
        if (eq(sp1, "pho|zs") and eq(slb, "ddong|z")) return .I;
        if (eq(sp1, "tong|zr") and eq(slb, "giam|s")) return .I;
        if (eq(sp1, "chien|zs") and eq(slb, "tranh|")) return .I;
        if (eq(sp1, "vo|x") and eq(slb, "huong|w")) return .I;
        if (eq(sp1, "the|zr") and eq(slb, "hien|zj")) {
            if (eq(sp1, "the|zr") and eq(sn1, "nay|")) return .B;
            return .I;
        }
        if (eq(sp1, "dan|z") and eq(slb, "toc|zj")) return .I;
        if (tp1 == .I and eq(slb, "the|zr") and tn1 == .B) return .I;
        if (eq(sp1, "hoai|f") and eq(sn1, "")) {
            if (eq(sp1, "hoai|f") and eq(slb, ".")) return .B;
            return .I;
        }
        if (eq(sp1, "vinh|j") and eq(slb, "moc|zs")) return .I;
        if (tp1 == .B and eq(slb, "rem|")) return .I;
        if (eq(sp1, "le|z")) {
            if (tp1 == .I) return .B;
            if (tp1 == .B and eq(slb, ",") and tn1 == .B) return .B;
            if (eq(sp2, "keo|s")) return .B;
            if (eq(slb, "bao|r")) return .B;
            if (tp2 == .B and tp1 == .B and eq(slb, ".")) return .B;
            if (tn2 == .I) return .B;
            if (eq(slb, "may|s") and tn1 == .I and tn2 == .B) return .B;
            if (eq(slb, "va|f") and tn1 == .B) return .B;
            return .I;
        }
        if (eq(sp1, "nguyen|zx")) {
            if (tn2 == .I) return .B;
            if (tp2 == .I and tp1 == .I) return .B;
            if (tp1 == .B and eq(slb, "-")) return .B;
            if (eq(sp2, "chua|s")) return .B;
            if (eq(sp2, "trieu|zf")) return .B;
            if (isQt(sp2) and eq(sp1, "nguyen|zx") and isQt(slb)) return .B;
            if (eq(slb, "(") and tn1 == .B and tn2 == .B) return .B;
            if (eq(sp2, "nha|f")) return .B;
            return .I;
        }
        if (eq(sp1, "cho|wj") and eq(slb, "ray|zx")) return .I;
        if (tp1 == .I and eq(slb, "tich|j") and tn1 == .B) return .I;
        if (eq(sp1, "su|wr") and eq(slb, "dung|j")) return .I;
        if (eq(sp1, "lan|") and eq(slb, "anh|")) return .I;
        if (eq(sp1, "nhat|zj") and eq(slb, "linh|")) return .I;
        if (eq(sp1, "cho|wj") and eq(slb, "lon|ws")) return .I;
        if (tp1 == .I and eq(slb, "tac|s") and tn1 == .B) return .I;
        if (eq(sp1, "truong|wf") and eq(slb, "son|w")) return .I;
        if (eq(sp1, "dda|f") and eq(slb, "trang|")) return .I;
        if (eq(sp1, "hong|zf") and eq(slb, "quynh|f")) return .I;
        if (eq(sp1, "ddang|w") and eq(slb, "nam|")) return .I;
        if (eq(sp1, "o|w") and eq(slb, "ddu|")) return .I;
        if (eq(slb, "nguyen|z") and tn1 == .N and tn2 == .N) return .I;
        if (eq(slb, "trung|") and tn1 == .N) {
            if (eq(sp1, "mien|zf")) return .B;
            return .I;
        }
        if (eq(sp1, "vo|x") and eq(sn1, "quynh|f")) return .I;
        if (tp2 == .N and tp1 == .B and eq(slb, "hung|w")) {
            if (eq(slb, "hung|w") and isQt(sn1) and eq(sn2, "cut|j")) return .B;
            if (eq(sp2, "") and eq(sp1, "ong|z") and eq(slb, "hung|w")) return .B;
            return .I;
        }
        if (tp1 == .B and eq(slb, "du|x") and tn1 == .B) return .I;
        if (eq(sp1, "ba|") and eq(slb, "thuc|ws")) return .I;
        if (eq(sp1, "ngoc|j") and eq(slb, "an|zr")) return .I;
        if (tp1 == .I and eq(slb, "phan|zj") and tn1 == .B) {
            if (eq(sp2, "thang|w")) return .B;
            return .I;
        }
        if (tp1 == .I and eq(slb, "cu|w") and tn1 == .B) return .I;
        if (eq(sp1, "bien|z") and eq(slb, "gioi|ws")) return .I;
        if (tp1 == .I and eq(slb, "vien|z")) return .I;
        if (eq(sp1, "quoc|zs") and eq(slb, "thanh|")) return .I;
        if (eq(sp2, "thuoc|zj") and eq(slb, "ban|f")) return .I;
        if (tp1 == .I and eq(slb, "duong|w") and tn1 == .B) {
            if (eq(sp2, "lai|x")) return .B;
            return .I;
        }
        if (eq(sp1, "ddang|wj")) {
            if (tp1 == .I) return .B;
            if (tp1 == .B and eq(slb, ",") and tn1 == .B) return .B;
            return .I;
        }
        if (tp1 == .I and eq(slb, "trang|j") and tn1 == .B) return .I;
        if (eq(sp1, "truong|wr") and eq(slb, "phong|f")) return .I;
        if (eq(slb, "vu|x") and tn1 == .N and tn2 == .N) return .I;
        if (eq(sp2, "ddong|zf") and eq(sp1, "thap|s") and eq(slb, "muoi|wf")) return .I;
        if (eq(sp1, "xe|") and eq(slb, "bo|f")) return .I;
        if (eq(slb, "hung|f") and tn1 == .N) return .I;
        if (eq(slb, "toan|f") and tn1 == .N and tn2 == .N) return .I;
        if (eq(sp1, "chanh|s") and eq(slb, "nghia|x")) return .I;
        if (eq(sp1, "cuoc|zj") and eq(slb, "song|zs")) return .I;
        if (eq(sp2, "mau|f") and eq(sp1, "da|") and eq(slb, "cam|")) return .I;
        if (eq(slb, "truong|wf") and eq(sn1, "") and eq(sn2, "")) return .I;
        if (eq(sp1, "/ch")) return .I;
        if (tp1 == .I and eq(slb, "hoa|s") and tn1 == .B) {
            if (eq(slb, "hoa|s") and eq(sn1, "thuong|w")) return .B;
            if (eq(sn2, "hoat|j")) return .B;
            return .I;
        }
        if (eq(sp1, "tran|zf") and eq(sn1, "nghia|x")) return .I;
        if (eq(sp1, "cong|z") and eq(slb, "nhan|z")) return .I;
        if (eq(sp1, "chu|ws") and eq(slb, "chung|s") and eq(sn1, "lau|zf")) return .I;
        if (eq(sp2, "dde|zr") and eq(sp1, "tro|wr") and eq(slb, "thanh|f")) return .I;
        if (eq(sp1, "chi|") and eq(slb, "phi|s")) return .I;
        if (eq(sp1, "minh|") and eq(slb, "luan|zj")) return .I;
        if (eq(sp2, "le|z") and eq(slb, "ddu|r")) return .I;
        if (eq(sp1, "ben|zs") and eq(slb, "nghe|s")) return .I;
        if (eq(sp1, "a|") and eq(slb, "gia|")) return .I;
        if (eq(sp1, "duy|") and eq(sn1, "")) return .I;
        if (eq(sp1, "cam|zr") and eq(slb, "ha|f")) return .I;
        if (tp1 == .B and eq(slb, "long|") and tn1 == .N) return .I;
        if (eq(sp1, "ben|zs") and eq(slb, "thanh|f")) return .I;
        if (eq(sp1, "nam|w") and eq(slb, "cam|")) return .I;
        if (eq(sp1, "nha|f") and eq(slb, "lon|ws")) {
            if (eq(sp2, "can|w")) return .B;
            if (eq(slb, "lon|ws") and eq(sn2, ",")) return .B;
            return .I;
        }
        if (eq(sp2, "ba|") and eq(sp1, "thang|s") and eq(slb, "hai|")) return .I;
        if (eq(sp1, "thuc|wj") and eq(slb, "hien|zj")) return .I;
        if (eq(slb, "giang|") and eq(sn2, "")) return .I;
        if (eq(sp1, "my|x") and eq(sn1, ",")) {
            if (eq(sp1, "my|x") and eq(slb, ")")) return .B;
            if (eq(sp1, "my|x") and eq(slb, "ke|zr") and eq(sn1, ",")) return .B;
            return .I;
        }
        if (eq(sp1, "ddoc|zj") and eq(slb, "mau|f")) return .I;
        if (eq(sp1, "trinh|f") and eq(slb, "ddo|zj")) return .I;
        if (eq(slb, "van|w") and eq(sn2, "")) {
            if (eq(slb, "van|w") and eq(sn1, ".")) return .B;
            if (tn1 == .I and tn2 == .N) return .B;
            return .I;
        }
        if (tp1 == .I and eq(slb, "cao|s") and tn1 == .B) return .I;
        if (eq(slb, "dung|x") and tn1 == .N) return .I;
        if (eq(sp1, "thay|zf") and eq(slb, "cai|")) return .I;
        if (eq(sp1, "ddien|zj") and eq(slb, "thoai|j")) return .I;
        if (eq(sp1, "day|z") and eq(slb, "ddien|zj")) {
            if (eq(slb, "ddien|zj") and eq(sn1, "thoai|j")) return .B;
            return .I;
        }
        if (eq(sp1, "phu|s") and eq(slb, "trung|")) return .I;
        if (eq(slb, "thanh|f") and tn1 == .N) return .I;
        if (eq(sp1, "yen|zs") and eq(slb, "trinh|")) return .I;
        if (eq(sp2, "ton|z") and eq(sp1, "that|zs") and eq(slb, "bach|s")) return .I;
        if (eq(sp2, "bo|zj") and eq(sp1, "luat|zj") and eq(slb, "to|zs")) return .I;
        if (eq(sp2, "dduoc|wj") and eq(sp1, "viec|zj") and eq(slb, "lam|f")) return .I;
        if (eq(sp2, "xoa|s") and eq(sp1, "mu|f") and eq(slb, "chu|wx")) return .I;
        if (eq(sp1, "chau|z") and eq(slb, "phi|")) return .I;
        if (eq(sp1, "o|") and eq(slb, "c")) return .I;
        if (eq(sp1, "hoc|j") and eq(slb, "tap|zj")) return .I;
        if (eq(sp1, "rieng|z") and eq(slb, "le|r")) return .I;
        if (eq(sp1, "hom|z") and eq(slb, "qua|")) return .I;
        if (eq(sp1, "bao|") and eq(slb, "gio|wf")) return .I;
        if (eq(sp1, "a|s") and eq(slb, "chau|z")) return .I;
        if (eq(sp1, "nghia|x") and eq(slb, "vu|j")) return .I;
        if (eq(sp1, "that|zs") and eq(slb, "tung|f")) return .I;
        if (eq(sp1, "trung|") and eq(slb, "bo|zj")) return .I;
        if (eq(sp1, "nghia|x") and eq(slb, "viet|zj") and eq(sn1, "nam|")) return .I;
        if (eq(sp1, "toc|zj") and eq(slb, "thieu|zr") and eq(sn1, "so|zs")) return .I;
        if (eq(sp1, "nam|w") and eq(slb, "minh|")) return .I;
        if (eq(sp1, "ong|z") and eq(slb, "kich|s")) return .I;
        if (eq(sp1, "my|x") and eq(slb, "thuan|zj")) return .I;
        if (eq(sp1, "dduc|ws") and eq(slb, "binh|f")) return .I;
        if (eq(sp1, "tuan|zs") and eq(slb, "phung|f")) return .I;
        if (eq(sp1, "van|zj") and eq(slb, "chuyen|zr")) return .I;
        if (eq(sp1, "hai|") and eq(slb, "ca|f")) return .I;
        if (eq(slb, "hai|r") and tn1 == .N) return .I;
        if (eq(sp1, "nuoc|ws") and eq(slb, "ngot|j")) return .I;
        if (eq(sp1, "hoa|f") and eq(slb, "xa|x") and eq(sn1, "hoi|zj")) return .I;
        if (eq(sp1, "mat|wj") and eq(slb, "bang|wf")) return .I;
        if (eq(sp1, "quang|") and eq(slb, "thien|zj")) return .I;
        if (eq(sp1, "ddien|zj") and eq(slb, "ngoc|j")) return .I;
        if (eq(sp1, "ly|s") and eq(slb, "do|")) return .I;
        if (eq(sp1, "cong|z") and eq(slb, "viec|zj")) return .I;
        if (eq(sp1, "hang|f") and eq(slb, "xanh|")) return .I;
        if (eq(sp1, "ba|") and eq(slb, "le|zj")) return .I;
        if (eq(sp1, "chien|zs") and eq(slb, "ddau|zs")) return .I;
        if (eq(sp1, "so|zs") and eq(slb, "luong|wj")) return .I;
        if (eq(sp1, "tung|j") and eq(sn1, "su|wj")) return .I;
        if (eq(slb, "son|") and tn1 == .B) return .I;
        if (eq(sp1, "my|x") and eq(slb, "son|w")) return .I;
        if (eq(sp1, "hoa|f") and eq(slb, "tan|z")) return .I;
        if (eq(sp2, "quyen|zf") and eq(slb, "phap|s")) return .I;
        if (eq(sp1, "tra|f") and eq(sn1, ",")) {
            if (tp2 == .B and tp1 == .B and eq(slb, "xanh|")) return .B;
            return .I;
        }
        if (eq(sp2, "cau|zf") and eq(slb, "te|r")) return .I;
        if (eq(sp1, "a|") and eq(sn1, ",")) {
            if (eq(sp1, "a|") and eq(slb, ")")) return .B;
            return .I;
        }
        if (eq(sp1, "phuong|w") and eq(slb, "an|s")) return .I;
        if (eq(slb, "nguyen|z") and eq(sn1, "-")) return .I;
        if (eq(sp1, "trong|j") and eq(slb, "phu|s")) return .I;
        if (eq(sp1, "ho|zf") and eq(slb, "kinh|s")) return .I;
        if (eq(sp1, "che|zs") and eq(slb, "bien|zs")) return .I;
        if (tp1 == .I and eq(slb, "binh|") and tn1 == .B) return .I;
        if (eq(sp2, "mot|zj") and eq(sp1, "so|zs") and eq(slb, "it|s")) return .I;
        if (eq(sp1, "co|w") and eq(slb, "quan|")) return .I;
        if (eq(sp1, "ong|z") and eq(slb, "buong|z")) return .I;
        if (eq(sp1, "that|zs") and eq(slb, "thuyet|zs")) return .I;
        if (eq(sp1, "truong|wf") and eq(slb, "giang|")) return .I;
        if (tp1 == .I and eq(slb, "tien|z") and tn1 == .B) return .I;
        if (eq(sp1, "ngan|z") and eq(slb, "sach|s")) return .I;
        if (eq(slb, "cong|zj") and eq(sn1, "san|r") and eq(sn2, "viet|zj")) return .I;
        if (tp1 == .I and eq(slb, "chuc|ws") and tn1 == .B) return .I;
        if (eq(sp1, "thanh|f") and eq(slb, "long|")) return .I;
        if (eq(sp1, "my|x") and eq(slb, "ddinh|f")) return .I;
        if (eq(sp1, "hang|f") and eq(slb, "tinh|f")) return .I;
        if (eq(sp1, "dduc|ws") and eq(sn1, ",")) {
            if (eq(slb, ")")) return .B;
            if (tp2 == .I and tp1 == .I) return .B;
            return .I;
        }
        if (eq(sp1, "ho|zf") and eq(sn1, "-")) return .I;
        if (eq(sp1, "lawrence") and eq(slb, "s.ting|")) return .I;
        if (tp1 == .B and eq(slb, "mart")) return .I;
        if (eq(sp1, "gia|") and eq(slb, "cam|zf")) return .I;
        if (tp1 == .B and eq(slb, "sac|s")) return .I;
        if (eq(sp1, "chu|r") and eq(slb, "nhiem|zj")) return .I;
        if (eq(sp1, "cong|z") and eq(slb, "ty|")) return .I;
        if (eq(sp1, "ba|f") and eq(slb, "ddiem|zr")) return .I;
        if (eq(sp2, "nhu|w") and eq(sp1, "the|zs") and eq(slb, "nay|f")) {
            if (eq(sn2, "mot|zj")) return .B;
            if (eq(sp1, "the|zs") and isQt(sn1)) return .B;
            return .I;
        }
        if (tp1 == .I and eq(slb, "hoach|j") and tn1 == .B) return .I;
        if (eq(sp1, "vi|j") and eq(slb, "tri|s")) return .I;
        if (eq(sp1, "may|s") and eq(slb, "bay|")) return .I;
        if (eq(sp1, "ddong|zf") and eq(slb, "phu|s")) return .I;
        if (tp1 == .I and eq(slb, "luc|wj") and tn1 == .B) {
            if (eq(slb, "luc|wj") and eq(sn1, "va|f")) return .B;
            return .I;
        }
        if (eq(sp1, "duong|w") and eq(slb, "vuong|w")) return .I;
        if (eq(slb, "kheng|")) return .I;
        if (eq(sp1, "ben|zs") and eq(sn1, "ddon|zf")) return .I;
        if (eq(sp1, "gia|s") and eq(slb, "thanh|f")) return .I;
        if (tp1 == .B and eq(slb, "ren|")) return .I;
        if (eq(slb, "thong|zs") and tn1 == .B) return .I;
        if (eq(sp1, "ba|") and eq(slb, "lai|")) return .I;
        if (tp1 == .I and eq(slb, "nghiep|zj") and tn1 == .B) return .I;
        if (eq(sp1, "viet|zs") and eq(slb, "nghe|zj") and eq(sn1, "tinh|x")) return .I;
        if (eq(sp1, "xe|") and eq(slb, "jeep")) return .I;
        if (eq(sp1, "lam|") and eq(slb, "ddien|zf")) return .I;
        if (eq(sp1, "phap|s") and eq(slb, "van|z")) return .I;
        if (eq(sp1, "ddam|zf") and eq(slb, "sen|")) return .I;
        if (eq(sp1, "yhán")) return .I;
        if (eq(sp1, "dduc|ws") and eq(slb, "vinh|j")) return .I;
        if (tp1 == .I and eq(slb, "te|zs") and tn1 == .B) return .I;
        if (eq(sp1, "ho|zf") and eq(slb, "si|x")) return .I;
        if (eq(sp2, "ba|f") and eq(sp1, "huyen|zj") and eq(slb, "thanh|")) return .I;
        if (eq(sp1, "vo|x") and eq(sn1, "cau|zf")) return .I;
        if (eq(sp2, "vo|x") and eq(slb, "cau|zf")) return .I;
        if (eq(sp1, "mat|wj") and eq(slb, "ddat|zs")) return .I;
        if (eq(sp1, "ca|r") and eq(slb, "cam|zs")) return .I;
        if (eq(sp1, "hai|") and eq(slb, "tram|z")) return .I;
        if (eq(sp2, "u|") and eq(slb, "ha|j")) return .I;
        if (eq(sp1, "quang|") and eq(slb, "khai|r")) return .I;
        if (eq(sp1, "nghiep|zj") and eq(slb, "vu|j") and eq(sn1, "hanh|f")) return .I;
        if (eq(sp1, "tong|zr") and eq(slb, "cuc|j") and eq(sn1, "truong|wr")) return .I;
        if (eq(sp2, "tong|zr") and eq(sp1, "thu|") and eq(slb, "nhap|zj")) return .I;
        if (eq(sp1, "tuong|wj") and eq(sn1, "van|w")) return .I;
        if (tp1 == .I and eq(slb, "tro|wj") and tn1 == .B) return .I;
        if (eq(sp1, "do|") and eq(slb, "lo|zj")) return .I;
        if (eq(sp1, "hoang|f") and eq(slb, "tri|s")) return .I;
        if (tp1 == .B and eq(slb, "anh|") and tn1 == .N) return .I;
        if (eq(sp2, "despicable") and eq(sp1, "me|") and eq(slb, "2")) return .I;
        if (eq(slb, "panda") and tn1 == .B) return .I;
        if (eq(sp2, "tieng|zs") and eq(sp1, "ddong|zj") and eq(slb, "co|w")) return .I;
        if (eq(slb, "song|z") and eq(sn1, "ngan|z")) return .I;
        if (eq(sp2, "ty|") and eq(slb, "dda|f")) return .I;
        if (eq(sp1, "song|z") and eq(slb, "ngan|z")) return .I;
        if (eq(sp1, "minh|") and eq(slb, "toan|s")) return .I;
        if (eq(sp1, "hoc|j") and eq(slb, "sinh|")) return .I;
        if (eq(sp1, "manh|j") and eq(slb, "tuan|zs")) return .I;
        if (eq(sp2, "nguoi|wf") and eq(sp1, "dan|z") and eq(slb, "ngheo|f")) return .I;
        if (eq(sp2, "") and eq(sp1, "quoc|zs") and eq(slb, "viet|zj")) return .I;
        if (eq(sp1, "kim|") and eq(slb, "em|")) return .I;
        if (eq(sp1, "tai|f") and eq(slb, "xe|zs")) return .I;
        if (eq(sp2, "tran|zf") and eq(sp1, "the|zs") and eq(slb, "ngoc|j")) return .I;
        if (eq(sp1, "ddau|zf") and eq(slb, "moi|zs")) return .I;
        if (tp1 == .I and eq(slb, "ddong|zj") and tn1 == .B) {
            if (eq(sp1, "coc|zs") and eq(sn1, ",")) return .B;
            if (eq(sp1, "thuy|r")) return .B;
            if (eq(slb, "ddong|zj") and eq(sn2, ",")) return .B;
            if (eq(sp1, "tap|zj") and eq(slb, "ddong|zj")) return .B;
            return .I;
        }
        if (eq(sp1, "ddai|f") and eq(slb, "bac|ws")) return .I;
        if (eq(sp1, "o|z") and eq(slb, "loan|")) return .I;
        if (eq(sp2, "cau|zf") and eq(sp1, "ong|z") and eq(slb, "lanh|x")) return .I;
        if (eq(sp2, "bao|s") and eq(sp1, "cong|z") and eq(slb, "an|")) return .I;
        if (eq(sp1, "nam|") and eq(slb, "bo|zj")) return .I;
        if (eq(sp1, "phi|f") and eq(slb, "nhieu|z")) return .I;
        if (eq(slb, "cuong|wf") and eq(sn2, "")) return .I;
        if (eq(sp1, "thai|s") and eq(slb, "huyen|zf")) return .I;
        if (eq(sp1, "ben|zs") and eq(slb, "hai|r")) return .I;
        if (eq(sp1, "ho|zf") and eq(sn1, "vong|j")) return .I;
        if (tp1 == .B and eq(slb, "loc|zj") and tn1 == .N) return .I;
        if (eq(sp1, "hang|f") and eq(slb, "chuc|ws") and eq(sn1, "nguyen|z")) return .I;
        if (eq(sp2, "cong|zj") and eq(sp1, "san|r") and eq(slb, "viet|zj")) return .I;
        if (eq(sp2, "cau|zf") and eq(slb, "thiem|z")) return .I;
        if (eq(slb, "danh|r")) return .I;
        if (eq(sp1, "chi|") and eq(slb, "tieu|z")) return .I;
        if (eq(sp1, "kenneth")) return .I;
        if (eq(sp2, "an|") and eq(sp1, "phu|s") and eq(slb, "ddong|z")) return .I;
        if (eq(sp2, "tho|wf") and eq(sp1, "dduc|ws") and eq(slb, "ba|f")) return .I;
        if (eq(sp1, "tieu|z") and eq(slb, "thu|j")) return .I;
        if (eq(sp1, "chi|") and eq(slb, "mai|")) return .I;
        if (eq(sp2, "cum|j") and eq(sp1, "cang|r") and eq(slb, "hang|f")) return .I;
        if (eq(slb, "thanh|j") and eq(sn1, ",")) return .I;
        if (eq(sp1, "nhu|w") and eq(slb, "vong|j")) return .I;
        if (eq(sp1, "tien|zs") and eq(slb, "ddo|zj")) return .I;
        if (tp1 == .I and eq(slb, "si|x") and tn1 == .B) return .I;
        if (eq(sp1, "an|.")) return .I;
        if (eq(sp2, ",") and eq(sp1, "nao|f") and eq(slb, "la|f")) return .I;
        if (eq(sp1, "ba|f") and eq(slb, "huyen|zj")) return .I;
        if (eq(sp1, "ho|zf") and eq(slb, "dduc|ws")) return .I;
        if (eq(sp1, "ong|z") and eq(slb, "ddia|j")) return .I;
        if (eq(sp1, "ba|") and eq(slb, "ddong|z")) return .I;
        if (eq(sp1, "a|") and eq(sn1, "(")) return .I;
        if (eq(sp1, "y|") and eq(slb, "chu|")) return .I;
        if (eq(sp2, "nen|z") and eq(sp1, "nguoi|wf") and eq(slb, "dan|z")) return .I;
        if (eq(sp1, "mat|wj") and eq(slb, "hang|f")) return .I;
        if (eq(sp1, "ben|zs") and eq(slb, "chuong|w")) return .I;
        if (eq(sp2, "bo|zf") and eq(slb, "ddat|j")) return .I;
        if (eq(sp1, "dduc|ws") and eq(slb, "lap|zj") and eq(sn1, "thuong|wj")) return .I;
        if (eq(sp1, "ha|f") and eq(slb, "ddong|zf")) return .I;
        if (eq(sp2, "may|s") and eq(sp1, "ddien|zj") and eq(slb, "ddam|f")) return .I;
        if (tp1 == .I and eq(slb, "luy|x")) return .I;
        if (eq(sp1, "quyet|zs") and eq(slb, "ddinh|j")) return .I;
        if (eq(sp1, "tra|f") and eq(slb, "my|")) return .I;
        if (eq(slb, "bien|zs") and eq(sn1, "ddoi|zr") and eq(sn2, "gen|")) return .I;
        if (eq(sp1, "cong|zs") and eq(slb, "quynh|f")) return .I;
        if (eq(sp1, "co|s") and eq(slb, "le|x")) return .I;
        if (eq(sp1, "ba|f") and eq(slb, "hom|")) return .I;
        if (eq(sp2, "nhu|w") and eq(sp1, "thuong|wf") and eq(slb, "le|zj")) return .I;
        if (eq(sp1, "nuoc|ws") and eq(slb, "ngoai|f")) return .I;
        if (eq(sp1, "ddoan|f") and eq(slb, "dduc|ws")) return .I;
        if (eq(sp2, "cao|") and eq(slb, "quang|")) return .I;
        if (eq(sp2, "dduc|ws") and eq(sp1, "lap|zj") and eq(slb, "thuong|wj")) return .I;
        if (eq(sp1, "hung|w") and eq(slb, "thuan|zj")) return .I;
        if (eq(sp2, "bien|zs") and eq(sp1, "ddoi|zr") and eq(slb, "gen|")) return .I;
        if (eq(sp2, "ho|zf") and eq(sp1, "thuy|r") and eq(slb, "ddien|zj")) return .I;
        if (eq(sp1, "tai|r") and eq(slb, "trong|j")) return .I;
        if (eq(sp2, "nguoi|wf") and eq(sp1, "lon|ws") and eq(slb, "tuoi|zr")) return .I;
        if (eq(sp2, "") and eq(sp1, "nghe|") and eq(slb, "noi|s")) return .I;
        if (eq(sp1, "my|x") and eq(sn1, "(")) return .I;
        if (eq(sp1, "lai|s") and eq(slb, "thieu|z")) return .I;
        if (eq(sp1, "cong|z") and eq(slb, "trinh|f")) return .I;
        if (eq(sp1, "hai|") and eq(slb, "hoang|f")) return .I;
        if (eq(sp1, "hong|zf") and eq(sn1, "(")) return .I;
        if (eq(slb, "qua|") and eq(sn2, "lai|j")) {
            if (eq(sp1, "ddo|zr")) return .B;
            return .I;
        }
        if (eq(sp1, "truong|wf") and eq(slb, "yen|z")) return .I;
        if (eq(sp1, "qua|") and eq(sn1, "lai|j")) {
            if (tp1 == .B and eq(slb, "ddo|zr")) return .B;
            return .I;
        }
        if (eq(sp1, "uyen|z") and eq(slb, "ly|")) return .I;
        if (eq(sp1, "cong|z") and eq(slb, "bo|zs")) return .I;
        if (eq(sp1, "bo|zj") and eq(slb, "truong|wr")) return .I;
        if (eq(sp1, "ddoan|f") and eq(slb, "thuong|wj")) return .I;
        if (eq(sp1, "the|zs") and eq(slb, "hung|f")) return .I;
        if (eq(sp1, "xe|") and eq(slb, "tai|r")) return .I;
        if (eq(sp1, "xe|") and eq(slb, "khach|s")) return .I;
        if (eq(sp2, "di|f") and eq(slb, "no|wr")) return .I;
        if (eq(slb, "m'ga|") and tn1 == .B) return .I;
        if (tp2 == .B and tp1 == .B and eq(slb, "ddin|")) return .I;
        if (eq(sp2, "lanh|x") and eq(slb, "thang|w")) return .I;
        if (eq(sp1, "cua|wr") and eq(slb, "can|j")) return .I;
        if (eq(sp1, "the|zs") and eq(slb, "nha|x") and eq(sn1, "")) return .I;
        if (eq(sp2, "ong|z") and eq(slb, "đuai")) return .I;
        if (eq(sp1, "ddong|zf") and eq(slb, "khanh|s")) return .I;
        if (eq(sp2, "be|s") and eq(slb, "duyen|z")) return .I;
        if (eq(slb, "nguyen|zx") and tn1 == .N) return .I;
        if (tp1 == .B and eq(slb, "tam|z") and tn1 == .N) return .I;
        if (tp1 == .B and eq(slb, "hieu|zs") and tn1 == .N) return .I;
        if (eq(sp1, "hang|f") and eq(slb, "bot|zj")) return .I;
        if (eq(sp2, "lua|s") and eq(sp1, "ddong|z") and eq(slb, "xuan|z")) return .I;
        if (eq(sp1, "duy|") and eq(sn1, "-")) return .I;
        if (eq(sp2, "tich|j") and eq(sp1, "ddoan|f") and eq(slb, "chu|r")) return .I;
        if (eq(sp2, "van|zj") and eq(slb, "mua|f")) return .I;
        if (eq(slb, "giang|") and tn1 == .B and tn2 == .I) return .I;
        if (eq(sp2, "cuoi|wf") and eq(slb, "kha|f")) return .I;
        if (eq(sp2, "vung|f") and eq(sp1, "cao|") and eq(slb, "nguyen|z")) return .I;
        if (tp1 == .B and eq(slb, "h'ly|") and tn1 == .B) return .I;
        if (eq(sp2, "hoi|zj") and eq(slb, "truc|s")) return .I;
        if (eq(sp1, "bien|zs") and eq(slb, "ddoi|zr")) return .I;
        if (eq(sp2, "cuc|j") and eq(sp1, "tac|s") and eq(slb, "chien|zs")) return .I;
        if (eq(sp1, "dduc|ws") and eq(slb, "viet|zj")) return .I;
        if (eq(sp1, "cach|s") and eq(sn1, "moc|zj")) return .I;
        if (eq(sp1, "ddong|zf") and eq(slb, "ddang|w")) return .I;
        if (eq(sp1, "thap|s") and eq(slb, "cham|f")) {
            if (eq(sp1, "thap|s") and eq(sn1, "my|x")) return .B;
            return .I;
        }
        if (tp1 == .I and eq(slb, "thiet|zs") and tn1 == .B) return .I;
        if (eq(sp1, "suc|ws") and eq(slb, "manh|j")) return .I;
        if (eq(sp1, "thanh|f") and eq(slb, "pho|zs")) {
            if (eq(sp2, "hinh|f")) return .B;
            return .I;
        }
        if (eq(slb, "thuc|ws") and tn1 == .B and tn2 == .I) {
            if (tp1 == .B and eq(slb, "thuc|ws")) return .B;
            return .I;
        }
        if (eq(sp1, "chuong|w") and eq(slb, "trinh|f")) return .I;
        if (eq(sp1, "the|zr") and eq(slb, "che|zs")) return .I;
        if (eq(sp1, "cho|wj") and eq(slb, "ddem|zj")) return .I;
        if (eq(slb, "mai|") and eq(sn1, "cong|z")) return .I;
        if (eq(sp2, "chat|zs") and eq(sp1, "ddoc|zj") and eq(slb, "hai|j")) return .I;
        if (eq(sp1, "tong|zr") and eq(slb, "bien|z")) return .I;
        if (eq(sp1, "thoi|wf") and eq(slb, "gian|")) return .I;
        if (eq(sp1, "a|") and eq(slb, "xo|wf")) return .I;
        if (eq(sp1, "y|") and eq(slb, "lan|")) return .I;
        if (eq(slb, "the|zs") and eq(sn1, "nha|x")) return .I;
        if (eq(sp1, "hai|") and eq(slb, "dduc|wj")) return .I;
        if (eq(sp1, "thu|r") and eq(slb, "tuong|ws")) return .I;
        if (eq(sp2, "hoi|zj") and eq(slb, "he|f")) return .I;
        if (eq(sp2, "nuoc|ws") and eq(sp1, "giai|r") and eq(slb, "khat|s")) return .I;
        if (eq(sp1, "nuoc|ws") and eq(slb, "sach|j")) return .I;
        if (eq(sp2, ",") and eq(sp1, "bien|zr") and eq(slb, "ddong|z")) return .I;
        if (eq(sp1, "mai|") and eq(slb, "cong|z")) return .I;
        if (eq(sp2, "kungfu") and eq(slb, "2")) return .I;
        if (eq(sp1, "quyen|zf") and eq(slb, "anh|")) return .I;
        if (eq(sp1, "thue|zs") and eq(slb, "thu|") and eq(sn1, "nhap|zj")) return .I;
        if (eq(sp1, "bien|zr") and eq(slb, "ho|zf")) return .I;
        if (eq(sp1, "hang|f") and eq(slb, "xom|s")) return .I;
        if (eq(sp1, "ddong|zf") and eq(slb, "ho|zf")) return .I;
        if (eq(sp1, "tra|f") and eq(sn1, "(")) return .I;
        if (eq(sp1, "toc|zs") and eq(slb, "ddo|zj")) return .I;
        if (eq(sp1, "nha|f") and eq(slb, "rong|zf")) return .I;
        if (eq(sp2, "ddong|zf") and eq(sp1, "tien|zf") and eq(slb, "mat|wj")) return .I;
        if (eq(sp1, "tinh|f") and eq(slb, "co|wf")) return .I;
        if (eq(sp1, "ben|zs") and eq(slb, "thuy|r")) return .I;
        if (eq(sp1, "ddien|zj") and eq(slb, "nam|")) return .I;
        if (eq(sp1, "hang|f") and eq(slb, "bac|j")) return .I;
        if (eq(sp1, "dduc|ws") and eq(slb, "minh|")) return .I;
        if (eq(sp1, "a|") and eq(slb, "roang|f")) return .I;
        if (eq(slb, "hu|r") and eq(sn1, "-")) return .I;
        if (eq(sp1, "phan|zf") and eq(slb, "lang|w")) return .I;
        if (eq(slb, "duy|") and eq(sn1, "")) return .I;
        if (eq(slb, "complex") and eq(sn1, "(")) return .I;
        if (eq(sp2, "") and eq(sp1, "vay|zj") and eq(slb, "thi|f")) return .I;
        if (eq(sp2, "ben|z") and eq(slb, "ddon|w")) return .I;
        if (eq(slb, "nuoi|z") and eq(sn1, "") and eq(sn2, "")) return .I;
        if (eq(sp1, "hai|") and eq(slb, "then|j")) return .I;
        if (eq(sp2, "nhat|zj") and eq(sp1, "ban|r") and eq(slb, "b")) return .I;
        if (eq(sp1, "hoi|zj") and eq(sn1, "lan|zf")) return .I;
        if (eq(sp2, "su|wj") and eq(sp1, "chu|r") and eq(slb, "tri|f")) return .I;
        if (eq(sp1, "learning") and eq(slb, "to|")) return .I;
        if (eq(sp1, "thi|") and eq(slb, "ngon|z")) return .I;
        if (eq(slb, "xơr")) return .I;
        if (eq(sp2, "len|z") and eq(sp1, "con|w") and eq(slb, "sot|zs")) return .I;
        if (eq(sp1, "buon|z") and eq(slb, "kuôp")) return .I;
        if (eq(sp1, "ddo|zx") and eq(slb, "huu|wx")) return .I;
        if (eq(slb, "hoa|f") and tn1 == .N and tn2 == .N) return .I;
        if (eq(sp1, "ddam|w") and eq(slb, "b'lon|")) return .I;
        if (eq(sp2, "lai|s") and eq(sp1, "xe|") and eq(slb, "om|z")) return .I;
        if (eq(sp1, "c.h.t.n.thi|j")) return .I;
        if (eq(sp2, "mo|wr") and eq(sp1, "dduong|wf") and eq(slb, "bay|")) return .I;
        if (eq(sp2, "tu|wf") and eq(sp1, "nguyen|z") and eq(slb, "nhan|z")) return .I;
        if (eq(sp1, "ba|f") and eq(slb, "keo|f")) return .I;
        if (eq(sp2, "xa|x") and eq(slb, "tien|zs")) return .I;
        if (eq(sn1, "am|wf")) return .I;
        if (eq(sp1, "ky|s") and eq(slb, "toa|f") and eq(sn1, "soan|j")) return .I;
        if (eq(sp1, "truc|s") and eq(slb, "su|w")) return .I;
        if (eq(slb, "hoa|r") and tn1 == .B) return .I;
        if (eq(slb, "sy|x")) return .I;
        if (eq(sp1, "huyet|zs") and eq(slb, "mach|j")) return .I;
        if (eq(sp2, "tang|zf") and eq(sp1, "ddong|zf") and eq(slb, "giao|")) return .I;
        if (eq(sp1, "a|") and eq(slb, "kiem|zj")) return .I;
        if (eq(sp2, "nguoi|wf") and eq(sp1, "lam|f") and eq(slb, "viec|zj")) return .I;
        if (eq(sp2, "tho|zr") and eq(sp1, "song|z") and eq(slb, "hong|zf")) return .I;
        if (tp1 == .B and eq(slb, "hlới") and tn1 == .B) return .I;
        if (eq(slb, "nhat|zj") and eq(sn2, "b")) return .I;
        if (eq(sp2, "qua|") and eq(slb, "lai|j")) {
            if (eq(sp2, "qua|") and eq(sp1, "ddo|zr") and eq(slb, "lai|j")) return .B;
            return .I;
        }
        if (eq(sp1, "gia|") and eq(slb, "ddinh|f")) return .I;
        if (tp1 == .I and eq(slb, "ddo|wj") and tn1 == .B) return .I;
        if (eq(sp1, "xuan|z") and eq(sn1, "-")) return .I;
        if (eq(sp1, "quan|r") and eq(slb, "ly|s")) return .I;
        if (eq(sp1, "ddieu|zf") and eq(slb, "chinh|r")) return .I;
        if (eq(sp1, "hang|f") and eq(slb, "rao|f")) return .I;
        if (eq(sp1, "j.")) return .I;
        if (eq(slb, "hai|r") and eq(sn1, "-")) return .I;
        if (eq(sp1, "huu|wx") and eq(slb, "tri|s")) {
            if (eq(slb, "tri|s") and eq(sn2, ",")) return .B;
            return .I;
        }
        if (eq(sp1, "a|.") and eq(sn1, ",")) return .I;
        if (eq(sp2, "ong|z") and eq(sp1, "nam|w") and eq(slb, "ddang|f")) return .I;
        if (eq(sp2, "chau|z") and eq(slb, "a|")) return .I;
        if (eq(sp2, "ddang|r") and eq(sp1, "lan|zf") and eq(slb, "thu|ws")) return .I;
        if (tp1 == .I and eq(slb, "tra|") and tn1 == .B) return .I;
        if (eq(sp2, "nghi|r") and eq(slb, "suc|ws")) return .I;
        if (eq(sp1, "dden|zf") and eq(slb, "lu|wf")) return .I;
        if (eq(sp1, "my|x") and eq(slb, "thanh|j")) return .I;
        if (eq(sp1, "ngoc|j") and eq(slb, "luan|zj")) return .I;
        if (eq(sp1, "sinh|") and eq(slb, "song|zs")) return .I;
        if (eq(sp1, "thuc|wj") and eq(slb, "tien|zx")) return .I;
        if (eq(sp1, "cau|zf") and eq(slb, "kho|")) return .I;
        if (eq(sp1, "ddeo|f") and eq(slb, "sen|")) return .I;
        if (eq(sp1, "ddao|j") and eq(slb, "dduc|ws")) return .I;
        if (eq(sp1, "nga|") and eq(slb, "man|z")) return .I;
        if (eq(sp1, "lam|f") and eq(slb, "an|w")) return .I;
        if (eq(sp2, "hoi|zj") and eq(sp1, "ddang|r") and eq(slb, "lan|zf")) return .I;
        if (tp2 == .B and tp1 == .B and eq(slb, "nom|z")) return .I;
        if (eq(sp1, "ban|r") and eq(slb, "ly|s")) {
            if (eq(sp1, "ban|r") and eq(slb, "ly|s") and eq(sn1, "a|")) return .B;
            return .I;
        }
        if (tp1 == .B and eq(slb, "bian")) return .I;
        if (eq(slb, "dah") and eq(sn1, "wen")) return .I;
        if (eq(sp1, "ddoi|zj") and eq(slb, "can|zs")) return .I;
        if (eq(sp2, "chi|j") and eq(sp1, "hai|") and eq(slb, "tram|zf")) return .I;
        if (eq(sp1, "tong|zr") and eq(slb, "thanh|") and eq(sn1, "tra|")) return .I;
        if (eq(slb, "ha|f") and tn1 == .N and tn2 == .N) return .I;
        if (eq(slb, "kieu|zf") and tn1 == .B) return .I;
        if (eq(sp1, "thieu|zs") and eq(slb, "gia|")) return .I;
        if (eq(sp1, "bo|r") and eq(slb, "cua|r") and eq(sn1, "chay|j")) return .I;
        if (eq(sp1, "cua|wr") and eq(slb, "hang|f")) return .I;
        if (tp1 == .I and eq(slb, "kien|zs") and tn1 == .B) return .I;
        if (eq(sp1, "cong|z") and eq(slb, "khai|")) return .I;
        if (eq(sp2, "") and eq(slb, "diem|zx")) return .I;
        if (tp1 == .B and eq(slb, "zich") and tn1 == .B) return .I;
        if (eq(sp1, "thue|zs") and eq(slb, "gia|s")) return .I;
        if (eq(sp1, "thuoc|zs") and eq(slb, "nam|")) return .I;
        if (eq(sp2, "dde|zr") and eq(sp1, "tro|wr") and eq(slb, "lai|j")) return .I;
        if (eq(sp2, "co|s") and eq(sp1, "han|j") and eq(slb, "ngach|j")) return .I;
        if (eq(slb, "son|w") and eq(sn1, "") and eq(sn2, "")) return .I;
        if (eq(sp2, "loi|wf") and eq(slb, "ddap|s")) return .I;
        if (eq(sn1, "hyun")) return .I;
        if (tp1 == .B and eq(slb, "huong|w") and tn1 == .N) return .I;
        if (eq(sp2, "bo|r") and eq(sp1, "cua|r") and eq(slb, "chay|j")) return .I;
        if (eq(sp1, "nghia|x") and eq(slb, "trang|")) return .I;
        if (eq(sp1, "bac|s") and eq(slb, "muoi|wf")) return .I;
        if (eq(sp2, "ddo|zx") and eq(slb, "ngoan|j")) return .I;
        if (eq(slb, "nham|") and tn1 == .B and tn2 == .B) return .I;
        if (eq(sp1, "pho|zs") and eq(slb, "la|f") and eq(sn1, ",")) return .I;
        if (eq(sp2, "y|") and eq(slb, "hoc|j")) return .I;
        if (eq(slb, "ngoc|j") and tn1 == .N and tn2 == .N) return .I;
        if (eq(sp2, "nu|wx") and eq(sp1, "tuong|ws") and eq(slb, "cuop|ws")) return .I;
        if (eq(sp1, "ho|zf") and eq(slb, "tung|f")) return .I;
        if (tp1 == .B and eq(slb, "v.bao|r")) return .I;
        if (eq(sp1, "the|zr") and eq(slb, "thao|")) return .I;
        if (eq(sp2, "ho|zf") and eq(sp1, "chinh|s") and eq(slb, "vinh|")) return .I;
        if (eq(sp1, "ddong|zf") and eq(slb, "bang|wf")) return .I;
        if (eq(sp1, "robin")) return .I;
        if (eq(sp1, "be|s") and eq(slb, "n.")) return .I;
        if (eq(slb, "minh|") and eq(sn1, "")) return .I;
        if (tp1 == .B and eq(slb, "ddan|s") and tn1 == .B) return .I;
        if (eq(sp2, "") and eq(sp1, "bao|r") and eq(slb, "trung|")) return .I;
        if (eq(sp1, "dan|z") and eq(slb, "lang|f")) return .I;
        if (eq(sp2, "co|s") and eq(slb, "tho|j")) return .I;
        if (eq(sp1, "su|wj") and eq(slb, "co|zs")) return .I;
        if (eq(sp1, "can|w") and eq(slb, "cu|ws")) return .I;
        if (eq(sp2, "mat|wj") and eq(slb, "bien|zr")) return .I;
        if (eq(sp1, "cau|zf") and eq(slb, "mon|z")) return .I;
        if (eq(sp1, "thanh|f") and eq(slb, "son|w")) return .I;
        if (eq(sp1, "van|zj") and eq(slb, "tai|r")) return .I;
        if (eq(sp2, "huynh|f") and eq(slb, "my|x")) return .I;
        if (eq(sp1, "tung|f") and eq(slb, "mau|zj")) return .I;
        if (eq(sp1, "xac|s") and eq(slb, "ddinh|j")) return .I;
        if (eq(sp1, "vu|x") and eq(sn1, "binh|f")) return .I;
        if (eq(sp1, "bui|f")) {
            if (eq(sp2, "song|z")) return .B;
            return .I;
        }
        if (eq(sp2, "do|") and eq(sp1, "du|wj") and eq(slb, "an|s")) return .I;
        if (eq(sp1, "giai|r") and eq(slb, "thich|s")) return .I;
        if (eq(sp1, "song|z") and eq(slb, "be|s")) return .I;
        if (eq(sp1, "ho|zf") and eq(slb, "chinh|s")) return .I;
        if (eq(sp2, "thay|zs") and eq(sp1, "ba|f") and eq(slb, "con|")) return .I;
        if (eq(slb, "hung|w") and eq(sn1, "") and eq(sn2, "")) return .I;
        if (eq(sp2, "lua|s") and eq(sp1, "he|f") and eq(slb, "thu|")) return .I;
        if (tp1 == .I and eq(slb, "tuong|wj") and tn1 == .B) {
            if (eq(sp2, "van|zj") and eq(sp1, "chuyen|zr") and eq(slb, "tuong|wj")) return .B;
            if (eq(sn1, "phat|zj")) return .B;
            return .I;
        }
        if (eq(sp1, "chay|j") and eq(slb, "lay|zs") and eq(sn1, "nguoi|wf")) return .I;
        if (tp1 == .B and eq(slb, "bao|r") and tn1 == .N) return .I;
        if (tp1 == .I and eq(slb, "ve|zj") and tn1 == .B) return .I;
        if (tp1 == .I and eq(slb, "giao|s") and tn1 == .B) return .I;
        if (eq(sp1, "ddoan|f") and eq(sn1, "hai|f")) return .I;
        if (eq(sp1, "mat|wj") and eq(slb, "tien|zf")) return .I;
        if (eq(sp2, "ddao|r") and eq(sp1, "ba|") and eq(slb, "binh|f")) return .I;
        if (eq(sp1, "tra|f") and eq(slb, "noc|s")) return .I;
        if (eq(sp1, "me|j") and eq(slb, "con|")) return .I;
        if (eq(sp1, "tay|") and eq(slb, "trai|s")) return .I;
        if (eq(sp2, "len|z") and eq(sp1, "tieng|zs") and eq(slb, "noi|s")) return .I;
        if (eq(sp2, "dduong|wf") and eq(sp1, "ddat|zs") and eq(slb, "ddo|r")) return .I;
        if (eq(sp2, "may|s") and eq(sp1, "bay|") and eq(slb, "truc|wj")) return .I;
        if (eq(sp2, "thuat|zj") and eq(slb, "ke|f")) return .I;
        if (eq(sp1, "cong|z") and eq(slb, "so|wr")) return .I;
        if (eq(sp1, "tu|wj") and eq(slb, "trung|")) return .I;
        if (eq(sp1, "ong|z") and eq(slb, "dau|zf")) return .I;
        if (tp2 == .B and tp1 == .I and eq(slb, "t.")) return .I;
        if (eq(sp1, "binh|f") and eq(slb, "thuong|wf")) return .I;
        if (eq(slb, "hoan|f") and eq(sn2, "sđk")) return .I;
        if (eq(sp1, "tieu|z") and eq(slb, "huy|r")) return .I;
        if (eq(sp1, "cong|z") and eq(slb, "suong|w")) return .I;
        if (eq(sp2, "mat|zs") and eq(sp1, "suc|ws") and eq(slb, "lao|")) return .I;
        if (eq(sp1, "quan|") and eq(slb, "hanh|f") and eq(sn1, "chinh|s")) return .I;
        if (eq(sp1, "tet|zs") and eq(sn1, "lich|j")) return .I;
        if (eq(sp1, "cong|z") and eq(slb, "van|w")) return .I;
        if (eq(sp1, "fred")) return .I;
        if (eq(sp1, "y|") and eq(slb, "xoan|")) return .I;
        if (eq(sp1, "ea")) return .I;
        if (eq(sp1, "my|x") and eq(slb, "hung|w")) return .I;
        if (eq(sp2, "bac|s") and eq(slb, "nhi|j")) return .I;
        if (eq(sp1, "ho|zf") and eq(slb, "sen|")) return .I;
        if (eq(sp1, "luc|wj") and eq(slb, "luong|wj")) return .I;
        if (eq(sp2, "ra|") and eq(sp1, "hieu|zj") and eq(slb, "ung|ws")) return .I;
        if (eq(sp1, "ho|zf") and eq(slb, "hien|zs")) return .I;
        if (eq(sp1, "ba|") and eq(slb, "bo|f")) return .I;
        if (eq(sp1, "vu|x") and eq(slb, "thuong|wj")) return .I;
        if (eq(sp1, "quan|") and eq(slb, "quyen|zf") and eq(sn1, "luc|wj")) return .I;
        if (eq(sp1, "con|") and eq(slb, "cong|z")) return .I;
        if (eq(sp1, "a|") and eq(slb, "vuong|w")) return .I;
        if (eq(sp1, "the|zs") and eq(slb, "nao|f")) return .I;
        if (eq(sp1, "ba|") and eq(slb, "xay|z")) return .I;
        if (eq(sp2, "chay|j") and eq(sp1, "lay|zs") and eq(slb, "nguoi|wf")) return .I;
        if (tp1 == .I and eq(slb, "nguyen|zj") and tn1 == .B) return .I;
        if (eq(sp1, "thanh|f") and eq(slb, "loc|zj")) return .I;
        if (eq(sp1, "hang|f") and eq(slb, "cot|s")) return .I;
        if (eq(sp1, "bo|zs") and eq(slb, "la|s")) return .I;
        if (eq(sp1, "ong|z") and eq(slb, "ddoi|zj")) return .I;
        if (eq(sp1, "hang|f") and eq(slb, "ddao|f")) return .I;
        if (eq(sp1, "chinh|s") and eq(slb, "tri|j")) return .I;
        if (eq(slb, "cua|") and eq(sn1, "bat|ws")) return .I;
        if (eq(slb, "tap|zj") and tn1 == .N and tn2 == .N) return .I;
        if (eq(slb, "phuong|w") and eq(sn1, "") and eq(sn2, "")) return .I;
        if (eq(slb, "kho|s") and eq(sn1, "lo|s")) return .I;
        if (eq(slb, "khe|s")) return .I;
        if (eq(sp1, "tam|z") and eq(slb, "su|wj")) return .I;
        if (tp2 == .N and tp1 == .B and eq(slb, "bich|s")) return .I;
        if (eq(sp1, "a|") and eq(slb, "gioi|s")) return .I;
        if (eq(sp1, "ao|s") and eq(slb, "quan|")) return .I;
        if (eq(sp2, "ddem|z") and eq(slb, "troi|wf")) return .I;
        if (eq(slb, "thang|s") and eq(sn2, "nga|")) return .I;
        if (eq(sp1, "hoi|zj") and eq(slb, "ddien|zr")) return .I;
        if (eq(slb, "lo|s") and eq(sn1, "cai|s")) return .I;
        if (eq(sp2, "vinh|x") and eq(slb, "b")) return .I;
        if (tp2 == .B and tp1 == .B and eq(slb, "ryan")) return .I;
        if (tp1 == .I and eq(slb, "khi|r")) return .I;
        if (eq(sp2, "ong|z") and eq(sp1, "ba|") and eq(slb, "ddon|wf")) return .I;
        if (eq(sp1, "tinh|f") and eq(slb, "huong|zs")) return .I;
        if (eq(sp2, "toi|zs") and eq(slb, "om|")) return .I;
        if (eq(sp1, "tri|s") and eq(slb, "nho|ws")) return .I;
        if (eq(slb, "an|z") and eq(sn1, "") and eq(sn2, "")) return .I;
        if (eq(sp1, "thuong|w") and eq(slb, "tin|s")) return .I;
        if (eq(sp2, "thanh|") and eq(sp1, "xuan|z") and eq(slb, "bac|ws")) return .I;
        if (eq(slb, "ericsson") and tn1 == .B) return .I;
        if (eq(sp2, "vo|z") and eq(slb, "tam|z")) return .I;
        if (eq(sp1, "gioi|ws") and eq(slb, "han|j")) return .I;
        if (eq(slb, "a|") and eq(sn1, "tho|")) return .I;
        if (eq(sp1, "be|zs") and eq(sn1, "ddan|f")) return .I;
        if (eq(sp2, "hoi|r") and eq(slb, "hoi|r")) return .I;
        if (eq(sp1, "lo|s") and eq(sn1, "khon|z")) return .I;
        if (eq(slb, "xeng|f")) return .I;
        if (eq(slb, "xuan|z") and eq(sn1, "loan|")) return .I;
        if (eq(sp2, "rach|j") and eq(slb, "me|s")) return .I;
        if (eq(sp1, "khanh|s") and eq(slb, "ngoc|j")) return .I;
        if (eq(slb, "vo|z") and eq(sn2, "bong|s")) return .I;
        if (eq(sp2, "muoi|wf") and eq(slb, "1917")) return .I;
        if (eq(sp1, "thang|s") and eq(slb, "muoi|wf") and eq(sn1, "nga|")) return .I;
        if (eq(sp2, "ddat|zs") and eq(sp1, "mau|f") and eq(slb, "mo|wx")) return .I;
        if (eq(sp1, "dduong|wf") and eq(slb, "day|z")) return .I;
        if (eq(sp1, "ngat|zs") and eq(slb, "nguong|wr")) return .I;
        if (eq(sp1, "ra|") and eq(slb, "vao|f") and eq(sn1, ",")) return .I;
        if (eq(sp2, "bong|s") and eq(sp1, "dda|s") and eq(slb, "chau|z")) return .I;
        if (eq(sp1, "tre|r") and eq(sn1, "nhat|zj")) return .I;
        if (eq(sp2, "chi|j") and eq(slb, "hung|wf")) return .I;
        if (eq(slb, "chau|z") and eq(sn1, "")) return .I;
        if (tp1 == .B and eq(slb, "loan|") and tn1 == .N) return .I;
        if (eq(sp2, "an|") and eq(sp1, "ninh|") and eq(slb, "ddong|z")) return .I;
        if (eq(sp2, "ddoan|f") and eq(slb, "hai|f")) return .I;
        if (eq(sp1, "thuong|w") and eq(slb, "yeu|z")) return .I;
        if (eq(slb, "cuu|wr") and eq(sn1, "long|") and eq(sn2, "co|s")) return .I;
        if (eq(sp2, "di|f") and eq(slb, "lat|wj")) return .I;
        if (tp1 == .B and eq(slb, "luoc|zs")) return .I;
        if (eq(slb, "luyen|zs") and tn1 == .N) return .I;
        if (eq(sp1, "bao|s") and eq(slb, "tu|wr")) return .I;
        if (eq(sp1, "kho|s") and eq(slb, "de|zx")) return .I;
        if (eq(sp1, "ddieu|zf") and eq(slb, "khoan|r")) return .I;
        if (eq(sp2, "ngay|f") and eq(sp1, "mot|zj") and eq(slb, "so|zs")) return .I;
        if (eq(sp1, "ddien|zj") and eq(slb, "phong|") and eq(sn1, ",")) return .I;
        if (eq(sp1, "hoa|f") and eq(slb, "binh|f") and eq(sn1, "2004")) return .I;
        if (eq(sp2, "nam|") and eq(sp1, "thoi|wf") and eq(slb, "hoi|zj")) return .I;
        if (eq(sp1, "lam|f") and eq(slb, "thue|z")) return .I;
        if (eq(slb, "su|wr") and tn1 == .N and tn2 == .N) return .I;
        if (tp1 == .B and eq(slb, "c.đ.")) return .I;
        if (eq(sp2, "bac|ws") and eq(slb, "chanh|s")) return .I;
        if (eq(sp1, "sinh|") and eq(slb, "nhat|zj")) return .I;
        if (eq(sp2, "tu|wf") and eq(sp1, "dduong|wf") and eq(slb, "co|w")) return .I;
        if (eq(sp2, "co|s") and eq(sp1, "li|s") and eq(slb, "do|")) return .I;
        if (eq(sn1, "thuot|zj")) return .I;
        if (eq(sp2, "co|s") and eq(sp1, "tinh|f") and eq(slb, "cam|r")) return .I;
        if (tp1 == .I and eq(slb, "na|j")) return .I;
        if (eq(sp2, "vo|z") and eq(slb, "bong|s")) return .I;
        if (eq(sp1, "phat|j") and eq(sn1, "tiep|zs")) return .I;
        if (eq(sp1, "lap|zj") and eq(slb, "phuc|s")) return .I;
        if (tp2 == .B and tp1 == .B and eq(slb, "reef")) return .I;
        if (eq(sp1, "nam|") and eq(slb, "nhat|zs") and eq(sn1, "thong|zs")) return .I;
        if (eq(sp2, "cong|zs") and eq(slb, "han|f")) return .I;
        if (eq(sp2, "song|z") and eq(sp1, "ba|") and eq(slb, "ha|j")) return .I;
        if (eq(sp2, "co|s") and eq(sp1, "hang|j") and eq(slb, "muc|j")) return .I;
        if (eq(sp2, "di|f") and eq(slb, "luom|wj")) return .I;
        if (eq(sp2, "vinh|x") and eq(sp1, "thanh|j") and eq(slb, "trung|")) return .I;
        if (eq(sp1, "ben|zs") and eq(slb, "binh|f") and eq(sn1, "ddong|z")) return .I;
        if (eq(sp1, "ben|zs") and eq(sn1, "ddinh|f")) return .I;
        if (tp1 == .I and eq(slb, "san|j")) return .I;
        if (eq(sp1, "cai|s") and eq(slb, "khon|z") and eq(sn1, ",")) return .I;
        if (eq(sp2, "cam|zf") and eq(sp1, "van|w") and eq(slb, "kinh|f")) return .I;
        if (eq(sp2, "thanh|f") and eq(sp1, "su|wj") and eq(slb, "that|zj")) return .I;
        if (eq(sp1, "v.") and eq(sn1, ",")) return .I;
        if (eq(sp1, "cua|wr") and eq(slb, "ong|z")) return .I;
        if (eq(sp1, "tre|r") and eq(slb, "em|")) return .I;
        if (eq(sp1, "quang|") and eq(sn1, "-")) return .I;
        if (eq(slb, "sp.") and tn1 == .B) return .I;
        if (eq(sp2, "lam|f") and eq(slb, "loat|j")) return .I;
        if (eq(sp1, "hinh|f") and eq(sn1, "nhat|zj")) return .I;
        if (eq(sp2, "nha|f") and eq(sp1, "giao|s") and eq(slb, "duc|j")) return .I;
        if (eq(slb, "v.") and eq(sn2, ",")) return .I;
        if (tp2 == .B and tp1 == .B and eq(slb, "din|")) return .I;
        if (eq(sp2, "thong|zs") and eq(slb, "hong|zf")) return .I;
        if (eq(sp1, "toi|ws") and eq(sn1, "lui|")) return .I;
        if (eq(sp1, "yeu|z") and eq(slb, "thuong|w")) return .I;
        if (eq(sp2, "mo|f") and eq(sp1, "cua|") and eq(slb, "bat|ws")) return .I;
        if (eq(slb, "luc|wj") and tn1 == .N) return .I;
        if (eq(sp2, "nguyen|zx") and eq(slb, "h.")) return .I;
        if (eq(sp1, "chu|r") and eq(slb, "yeu|zs")) return .I;
        if (eq(sp1, "cai|") and eq(slb, "nghien|zj")) return .I;
        if (tp1 == .B and eq(slb, "yol")) return .I;
        if (eq(sp1, "chan|z") and eq(sn1, "chan|z")) return .I;
        if (tp1 == .I and eq(slb, "ta|s") and tn1 == .B) return .I;
        if (tp1 == .I and eq(slb, "tap|ws")) return .I;
        if (tp1 == .I and eq(slb, "gia|") and tn1 == .B) {
            if (eq(sp1, "lao|x")) return .B;
            return .I;
        }
        if (eq(sp1, "phan|") and eq(sn1, "")) return .I;
        if (eq(sp1, "hang|f") and eq(slb, "buom|zf")) return .I;
        if (eq(sp1, "huong|w") and eq(slb, "thao|r")) return .I;
        if (eq(slb, "modified") and tn1 == .B and tn2 == .B) return .I;
        if (eq(sp1, "y|") and eq(slb, "con|")) return .I;
        if (eq(sp1, "cua|wr") and eq(slb, "duong|w") and eq(sn1, ",")) return .I;
        if (isQt(sp2) and eq(sp1, "nghe|") and eq(slb, "noi|s")) return .I;
        if (eq(sp1, "to|zs") and eq(slb, "oanh|")) return .I;
        if (eq(sp2, "nguyen|zx") and eq(sp1, "huu|wx") and eq(slb, "hanh|j")) return .I;
        if (eq(sp1, "gioi|ws") and eq(slb, "thieu|zj")) return .I;
        if (tp1 == .I and eq(slb, "doanh|") and tn1 == .B) return .I;
        if (eq(sp2, "an|w") and eq(sp1, "cua|r") and eq(slb, "dde|zr")) return .I;
        if (eq(sp1, "chau|z") and eq(slb, "my|x")) return .I;
        if (eq(sp1, "truong|wf") and eq(slb, "luu|w")) return .I;
        if (eq(sp2, "nganh|f") and eq(sp1, "hang|f") and eq(slb, "khong|z")) return .I;
        if (eq(sp1, "ddong|zf") and eq(slb, "mo|z") and eq(sn1, "(")) return .I;
        if (eq(sp1, "truoc|ws") and eq(slb, "dday|z") and eq(sn1, ",")) return .I;
        if (eq(sp1, "culex")) return .I;
        if (eq(sp2, "nam|") and eq(sp1, "trung|") and eq(slb, "quoc|zs")) return .I;
        if (eq(sp1, "a|r") and eq(slb, "rap|zj")) return .I;
        if (eq(sp1, "thuoc|zs") and eq(slb, "tay|z")) return .I;
        if (eq(sp2, ":") and eq(sp1, "khu|") and eq(slb, "bao|r")) return .I;
        if (eq(slb, "mon|w") and tn1 == .B and tn2 == .B) return .I;
        if (eq(sp1, "tinh|f") and eq(sn1, "nghia|x")) return .I;
        if (eq(sp2, "cua|r") and eq(sp1, "an|w") and eq(slb, "cua|r")) return .I;
        if (eq(sp2, "lam|f") and eq(sp1, "chung|ws") and eq(slb, "minh|")) return .I;
        if (eq(sp1, "cung|f") and eq(slb, "cuc|wj")) return .I;
        if (tp1 == .B and eq(slb, "b.fall")) return .I;
        if (eq(sp1, "nguyen|z") and eq(sn1, "-")) return .I;
        if (eq(sp1, "to|") and eq(sn1, ")")) return .I;
        if (eq(sp2, "cang|r") and eq(sp1, "ba|") and eq(slb, "cap|zs")) return .I;
        if (eq(sp1, "long|") and eq(slb, "b")) return .I;
        if (eq(sp1, "van|zj") and eq(slb, "hanh|f")) return .I;
        if (eq(sp1, "bac|s") and eq(slb, "ton|z")) return .I;
        if (eq(sp1, "ho|zf") and eq(slb, "met|j")) return .I;
        if (eq(sp2, "vao|f") and eq(sp1, "dde|zf") and eq(slb, "tai|f")) return .I;
        if (eq(sp2, "thanh|f") and eq(sp1, "tam|z") and eq(slb, "ddiem|zr")) return .I;
        if (eq(sp2, "xa|x") and eq(slb, "ha|j")) return .I;
        if (eq(sp1, "chi|") and eq(slb, "tra|r")) return .I;
        if (eq(sp1, "song|") and eq(slb, "phung|j")) return .I;
        if (eq(slb, "ddi|") and eq(sn1, "tim|f") and eq(sn2, "dduong|wf")) return .I;
        if (eq(sp1, "y|") and eq(slb, "mi|")) return .I;
        if (eq(sp1, "bo|zj") and eq(slb, "ddoi|zj")) {
            if (tn1 == .B and tn2 == .I) return .B;
            return .I;
        }
        if (eq(sp2, "het|zs") and eq(slb, "mat|ws")) return .I;
        if (eq(sp2, "toi|ws") and eq(slb, "lui|")) return .I;
        if (eq(sp1, "hai|") and eq(slb, "long|")) return .I;
        if (eq(sp1, "hang|f") and eq(slb, "bang|f")) return .I;
        if (eq(sp1, "cua|wr") and eq(slb, "tung|f")) return .I;
        if (eq(sp2, "ong|z") and eq(sp1, "tu|wf") and eq(slb, "choi|zs")) return .I;
        if (eq(sp1, "o|z") and eq(slb, "cho|wj") and eq(sn1, "dua|wf")) return .I;
        if (eq(slb, "toan|f") and eq(sn1, "tap|zj") and eq(sn2, ",")) return .I;
        if (eq(sp1, "vang|f") and eq(slb, "vang|f")) return .I;
        if (eq(sp1, "khong|z") and eq(slb, "khi|s")) return .I;
        if (eq(sp1, "ho|zf") and eq(slb, "liem|z")) return .I;
        if (eq(sp2, "benh|zj") and eq(sp1, "viem|z") and eq(slb, "nao|x")) {
            if (eq(sp1, "viem|z") and eq(slb, "nao|x") and eq(sn1, "sieu|z")) return .B;
            return .I;
        }
        if (eq(sp2, "nguoi|wf") and eq(sp1, "than|z") and eq(slb, "quen|")) return .I;
        if (eq(sp1, "nhat|zs") and eq(slb, "a|")) return .I;
        if (eq(sp2, "vua|") and eq(slb, "thai|s")) return .I;
        if (eq(sp1, "the|zs") and eq(slb, "gioi|ws")) return .I;
        if (eq(sp2, "") and eq(sp1, "nao|f") and eq(slb, "la|f")) return .I;
        if (eq(slb, "toi|ws") and eq(sn2, "lui|")) return .I;
        if (eq(sp1, "tet|zs") and eq(slb, "tay|z")) return .I;
        if (eq(sp2, "tan|z") and eq(slb, "sanh|")) return .I;
        if (eq(sp1, "hang|f") and eq(slb, "ma|x")) return .I;
        if (eq(sp1, "modified")) return .I;
        if (eq(slb, "na|") and eq(sn1, ",")) return .I;
        if (eq(sp1, "tien|zf") and eq(slb, "dde|zf")) return .I;
        if (eq(sp1, "nam|") and eq(slb, "thoi|wf") and eq(sn1, "hoi|zj")) return .I;
        if (eq(sp1, "tay|z") and eq(slb, "bac|ws") and eq(sn1, "-")) return .I;
        if (eq(slb, "an|w") and eq(sn1, "cua|r") and eq(sn2, "dde|zr")) return .I;
        if (eq(sp1, "quan|z") and eq(slb, "ddoi|zj")) return .I;
        if (eq(sp2, "ton|z") and eq(sp1, "that|zs") and eq(slb, "lap|zj")) return .I;
        if (eq(sp2, "hay|") and eq(sp1, "biet|zs") and eq(slb, "may|zs")) return .I;
        if (eq(sp1, "cho|wj") and eq(slb, "dua|wf")) return .I;
        if (eq(sp2, "cau|zf") and eq(sp1, "noi|zs") and eq(slb, "tiep|zs")) return .I;
        if (eq(sp1, "song|z") and eq(slb, "ddoc|zs")) return .I;
        if (eq(sp2, "-") and eq(sp1, "ddong|z") and eq(slb, "nam|")) return .I;
        if (eq(slb, "an|") and eq(sn1, "(")) return .I;
        if (eq(sp1, "ho|zf") and eq(slb, "thanh|") and eq(sn1, "son|w")) return .I;
        if (eq(sp1, "chinh|s") and eq(slb, "gian|s")) return .I;
        if (eq(sp1, "ben|zs") and eq(slb, "ddinh|f")) return .I;
        if (eq(sp1, "song|z") and eq(sn1, "ha|j")) return .I;
        if (eq(sp2, "ra|") and eq(sp1, "mat|wj") and eq(slb, "dduong|wf")) return .I;
        if (eq(sp2, "ddi|") and eq(sp1, "tinh|s") and eq(slb, "lai|j")) return .I;
        if (eq(sp1, "nha|f") and eq(slb, "trang|ws")) return .I;
        if (eq(sp1, "a|s") and eq(slb, "ddong|z")) return .I;
        if (eq(sp1, "tau|f") and eq(sn1, "ngam|zf")) return .I;
        if (eq(sp1, "song|z") and eq(slb, "cai|s")) return .I;
        if (eq(sp2, "tau|f") and eq(slb, "ngam|zf")) return .I;
        if (eq(sp1, "ddi|") and eq(slb, "tinh|s") and eq(sn1, "lai|j")) return .I;
        if (eq(sp1, "cung|f") and eq(slb, "voi|ws") and eq(sn1, "he|zj")) return .I;
        if (eq(sp1, "nam|w") and eq(slb, "huong|w")) return .I;
        if (eq(sp1, "chac|ws") and eq(slb, "bang|w")) return .I;
        if (eq(sp1, "vien|zj") and eq(slb, "phi|s")) return .I;
        if (eq(sp1, "yeu|z") and eq(slb, "cau|zf")) return .I;
        if (eq(sp1, "phuc|j") and eq(slb, "vu|j")) return .I;
        if (eq(sp1, "thoi|wf") and eq(slb, "vu|j")) return .I;
        if (eq(sp1, "ba|") and eq(slb, "ddon|zf")) return .I;
        if (eq(sp1, "bich|s") and eq(slb, "dau|zj")) return .I;
        if (eq(sp1, "cam|") and eq(slb, "ly|")) return .I;
        if (eq(sp2, "tang|w") and eq(sp1, "trong|j") and eq(slb, "luong|wj")) return .I;
        if (eq(sp1, "si|x") and eq(slb, "quan|")) return .I;
        if (eq(sp1, "hang|f") and eq(slb, "dduong|wf")) return .I;
        if (eq(slb, "a|") and eq(sn2, "huyen|zj")) return .I;
        if (eq(slb, "ddi|") and eq(sn1, "tinh|s") and eq(sn2, "lai|j")) return .I;
        if (eq(sp1, "hoi|r") and eq(sn1, "hoi|r")) return .I;
        if (eq(sp1, "phan|zj") and eq(slb, "su|wj")) return .I;
        if (eq(sp1, "hoc|j") and eq(slb, "van|zs")) return .I;
        if (eq(sp2, "xe|") and eq(sp1, "ra|") and eq(slb, "vao|f")) return .I;
        if (eq(sp1, "gio|s") and eq(slb, "lao|f")) return .I;
        if (eq(sp1, "bien|zr") and eq(slb, "ddong|z") and eq(sn1, ".")) return .I;
        if (eq(sp2, "cau|zf") and eq(sp1, "my|x") and eq(slb, "thanh|")) return .I;
        if (eq(sp1, "cho|") and eq(slb, "biet|zs") and eq(sn1, "quan|")) return .I;
        if (eq(sp2, "cac|s") and eq(sp1, "lang|f") and eq(slb, "que|z")) return .I;
        if (eq(sp1, "ba|") and eq(slb, "tho|j")) return .I;
        if (eq(sp1, "nam|w") and eq(slb, "ddo|zj")) return .I;
        if (eq(sp2, "ca|s") and eq(sp1, "cua|wr") and eq(slb, "ddai|j")) return .I;
        if (eq(sp2, "khong|z") and eq(sp1, "trung|") and eq(slb, "thuc|wj")) return .I;
        return .B;
    }
    return .N;
}

test "parse" {
    var syllables: []const []const u8 = &.{ "", "quan|zj", "cong|z", "", "" };
    var tags: []const Tag = &.{ .N, .B, .I, .N, .N };
    try std.testing.expectEqual(parse(2, syllables, tags), .B);
}

test "rules #650 - #655" {
    // Parent conditions
    const sp1: []const u8 = "le|z";
    const tag: Tag = .B;

    try std.testing.expectEqual(parse(2, &.{ "", sp1, "", "", "" }, &.{ .N, .N, tag, .N, .N }), .I);

    // object.prevTag1 == "I" : object.conclusion = "B"
    try std.testing.expectEqual(parse(2, &.{ "", sp1, "", "", "" }, &.{ .N, .I, tag, .N, .N }), .B);

    // object.prevTag1 == "B" and object.word == "," and object.nextTag1 == "B" : object.conclusion = "B"
    try std.testing.expectEqual(parse(2, &.{ "", sp1, ",", "", "" }, &.{ .N, .B, tag, .B, .N }), .B);

    // object.prevWord2 == "kéo" : object.conclusion = "B"
    try std.testing.expectEqual(parse(2, &.{ "keo|s", sp1, "", "", "" }, &.{ .N, .N, tag, .N, .N }), .B);

    // object.word == "bảo" : object.conclusion = "B"
    try std.testing.expectEqual(parse(2, &.{ "", sp1, "bao|r", "", "" }, &.{ .N, .N, tag, .N, .N }), .B);

    // object.prevTag2 == "B" and object.prevTag1 == "B" and object.word == "." : object.conclusion = "B"
    try std.testing.expectEqual(parse(2, &.{ "", sp1, ".", "", "" }, &.{ .B, .B, tag, .N, .N }), .B);

    // object.nextTag2 == "I" : object.conclusion = "B"
    try std.testing.expectEqual(parse(2, &.{ "", sp1, "", "", "" }, &.{ .N, .N, tag, .N, .I }), .B);
}

test "rules #1406 - #1409" {
    var tag: Tag = .B;
    try std.testing.expectEqual(parse(2, &.{ "", "", "", "", "" }, &.{ .N, .N, tag, .N, .N }), .B);

    // object.prevWord2 == "-" and object.prevWord1 == "đông" and object.word == "nam" : object.conclusion = "I"
    try std.testing.expectEqual(parse(2, &.{ "-", "ddong|z", "nam|", "", "" }, &.{ .N, .N, tag, .N, .N }), .I);

    // object.word == "an" and object.nextWord1 == "(" : object.conclusion = "I"
    try std.testing.expectEqual(parse(2, &.{ "", "", "an|", "(", "" }, &.{ .N, .N, tag, .N, .N }), .I);

    // object.prevWord1 == "hồ" and object.word == "thanh" and object.nextWord1 == "sơn" : object.conclusion = "I"
    try std.testing.expectEqual(parse(2, &.{ "", "ho|zf", "thanh|", "son|w", "" }, &.{ .N, .N, tag, .N, .N }), .I);

    // object.prevWord1 == "chính" and object.word == "gián" : object.conclusion = "I"
    try std.testing.expectEqual(parse(2, &.{ "", "chinh|s", "gian|s", "", "" }, &.{ .N, .N, tag, .N, .N }), .I);
}

test "rules #9 - #12" {
    var tag: Tag = .I;
    try std.testing.expectEqual(parse(2, &.{ "", "", "", "", "" }, &.{ .N, .N, tag, .N, .N }), .I);

    // object.prevWord1 == "con" and object.word == "gái" : object.conclusion = "B"
    try std.testing.expectEqual(parse(2, &.{ "", "con|", "gai|s", "", "" }, &.{ .N, .N, tag, .N, .N }), .B);

    // object.prevWord1 == "chủ" and object.word == "đầu" : object.conclusion = "B"
    try std.testing.expectEqual(parse(2, &.{ "", "chu|r", "ddau|zf", "", "" }, &.{ .N, .N, tag, .N, .N }), .B);

    // object.prevWord2 == "chất" and object.prevWord1 == "độc" and object.word == "da" : object.conclusion = "B"
    try std.testing.expectEqual(parse(2, &.{ "chat|zs", "ddoc|zj", "da|", "", "" }, &.{ .N, .N, tag, .N, .N }), .B);

    // object.prevWord1 == "tái" and object.word == "định" and object.nextWord1 == "cư" : object.conclusion = "B"
    try std.testing.expectEqual(parse(2, &.{ "", "tai|s", "ddinh|j", "cu|w", "" }, &.{ .N, .N, tag, .N, .N }), .B);
}
