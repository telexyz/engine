// n-gram/ a: 2,       b: 3..5,    c: 6..11,   d: 12..25, e: 26..80, f: remain
// 2-gram/ a: 1444334, b: 424429,  c: 276007,  d: 199301, e: 170952, f: 150211
// 3-gram/ a: 2343228, b: 1995402, c: 955810,  d: 533752, e: 339218, f: 174532
// 4-gram/ a: 4407945, b: 3114767, c: 1252778, d: 601206, e: 322523, f: 121206
// (( STEP 3: Count and write n-gram done! Duration 1.15 mins ))
// TODO: use BitWriter to write fuse filter out

const std = @import("std");
const mem = std.mem;

const Text = @import("../textoken/text_data_struct.zig").Text;
const Syllable = @import("../phoneme/syllable_data_structs.zig").Syllable;
const BinaryFuse = @import("../fastfilter/binaryfusefilter.zig").BinaryFuse;

const Gram = Syllable.UniqueId;
const BLANK: Gram = Syllable.NONE_ID;
const SyllableIdArray = std.ArrayList(Syllable.UniqueId);

pub fn NGram() type {
    return struct {
        c1_grams: std.AutoHashMap(u64, u32) = undefined,
        c2_grams: std.AutoHashMap(u64, u32) = undefined,
        c3_grams: std.AutoHashMap(u64, u32) = undefined,
        c4_grams: std.AutoHashMap(u64, u32) = undefined,

        syllable_ids: SyllableIdArray = undefined,
        allocator: std.mem.Allocator = undefined,

        const Self = @This();

        pub fn init(self: *Self, init_allocator: std.mem.Allocator) void {
            self.allocator = init_allocator;
        }

        pub fn loadSyllableIdsFromText(self: *Self, text: Text) !void {
            const syll_ids = text.tokens_infos.items(.syllable_id);
            self.syllable_ids = try SyllableIdArray.initCapacity(
                self.allocator,
                syll_ids.len * 3 / 2,
            );

            var prev_syll_id: Syllable.UniqueId = BLANK;
            try self.syllable_ids.append(BLANK);

            for (syll_ids) |syll_id| {
                if (syll_id == BLANK and prev_syll_id == BLANK) continue;
                try self.syllable_ids.append(syll_id);
                prev_syll_id = syll_id;
            }

            try self.syllable_ids.append(BLANK);
        }

        pub fn loadSyllableIdsCdxFile(self: *Self, filename: []const u8) !void {
            var file = try std.fs.cwd().openFile(filename, .{});
            defer file.close();

            const input_bytes = try file.reader().readAllAlloc(
                self.allocator,
                1024 * 1024 * 1024,
            ); // max 1Gb
            defer self.allocator.free(input_bytes);

            const n = input_bytes.len;
            self.syllable_ids = try SyllableIdArray.initCapacity(self.allocator, n / 6);

            // Decode base64
            var char_to_index = [_]Syllable.UniqueId{0xff} ** 256;
            for (std.base64.standard_alphabet_chars) |c, i|
                char_to_index[c] = @intCast(Syllable.UniqueId, i);

            // Init syllable_ids from bytes
            var in_blank_zone = true;
            try self.syllable_ids.append(BLANK);

            var syll_id: Syllable.UniqueId = undefined;
            var i: usize = 0;

            while (i < n) : (i += 1) {
                var char = input_bytes[i];
                if (char >= 24) {
                    char = input_bytes[i + 1];
                    syll_id = char_to_index[char] << 12;

                    char = input_bytes[i + 2];
                    syll_id |= char_to_index[char] << 6;

                    i += 3;
                    char = input_bytes[i];
                    syll_id |= char_to_index[char];

                    try self.syllable_ids.append(syll_id);
                    in_blank_zone = false;
                    //
                } else if (!in_blank_zone) {
                    try self.syllable_ids.append(BLANK);
                    in_blank_zone = true;
                }
            }

            try self.syllable_ids.append(BLANK);
        }

        pub fn deinit(self: *Self) void {
            self.syllable_ids.deinit();
        }

        pub fn countAndWrite(
            self: *Self,
            comptime filename1: []const u8,
            comptime filename2: []const u8,
            comptime filename3: []const u8,
            comptime filename4: []const u8,
        ) !void {
            //

            try self.syllable_ids.append(BLANK);
            try self.syllable_ids.append(BLANK);
            try self.syllable_ids.append(BLANK);
            try self.syllable_ids.append(BLANK);

            const n = self.syllable_ids.items.len;
            const _percents: u8 = 5;
            const _percents_delta = (n * _percents / 100);
            var percents_threshold = _percents_delta;
            var percents: u8 = 0;

            self.c1_grams = std.AutoHashMap(u64, u32).init(self.allocator);
            self.c2_grams = std.AutoHashMap(u64, u32).init(self.allocator);
            self.c3_grams = std.AutoHashMap(u64, u32).init(self.allocator);
            self.c4_grams = std.AutoHashMap(u64, u32).init(self.allocator);

            var i: usize = 5;
            const syll_ids = self.syllable_ids.items;
            var grams: [4]Gram = .{ 0, syll_ids[0], syll_ids[1], syll_ids[2] };

            var tmp: [2048]Gram = undefined;
            var buf = tmp[0..];

            while (i < n) : (i += 2048) {
                var max = i + 2048;
                if (max > n) max = n;
                std.mem.copy(Gram, buf, syll_ids[i..max]);

                // Show progress
                if (max > percents_threshold) {
                    percents += _percents;
                    percents_threshold += _percents_delta;
                    std.debug.print("Counting 1..4-grams {d}%\n", .{percents});
                }

                for (buf[0 .. max - i]) |syll_id| {
                    grams[0] = grams[1];
                    grams[1] = grams[2];
                    grams[2] = grams[3];
                    grams[3] = syll_id;

                    var key: u64 = grams[0];
                    const gop1 = try self.c1_grams.getOrPutValue(key, 0);
                    gop1.value_ptr.* += 1;

                    if (grams[0] == BLANK) {
                        //
                        if (grams[1] == BLANK) continue;
                        key = (key << 16) + grams[1];
                        const gop2 = try self.c2_grams.getOrPutValue(key, 0);
                        gop2.value_ptr.* += 1;

                        if (grams[2] == BLANK) continue;
                        key = (key << 16) + grams[2];
                        const gop3 = try self.c3_grams.getOrPutValue(key, 0);
                        gop3.value_ptr.* += 1;

                        if (grams[3] == BLANK) continue;
                        key = (key << 16) + grams[3];
                        const gop4 = try self.c4_grams.getOrPutValue(key, 0);
                        gop4.value_ptr.* += 1;
                        //
                    } else { // grams[0] != BLANK
                        //
                        key = (key << 16) + grams[1];
                        const gop2 = try self.c2_grams.getOrPutValue(key, 0);
                        gop2.value_ptr.* += 1;

                        if (grams[1] == BLANK or grams[2] == BLANK) continue;
                        key = (key << 16) + grams[2];
                        const gop3 = try self.c3_grams.getOrPutValue(key, 0);
                        gop3.value_ptr.* += 1;

                        if (grams[2] == BLANK) continue;
                        key = (key << 16) + grams[3];
                        const gop4 = try self.c4_grams.getOrPutValue(key, 0);
                        gop4.value_ptr.* += 1;
                    }
                } // for syll_id
            } // while

            try writeGramCounts(self.c1_grams, filename1, 1);
            self.c1_grams.deinit();

            try writeGramCounts(self.c2_grams, filename2, 2);
            self.c2_grams.deinit();

            try writeGramCounts(self.c3_grams, filename3, 3);
            self.c3_grams.deinit();

            try writeGramCounts(self.c4_grams, filename4, 4);
            self.c4_grams.deinit();
        }
    };
}

fn writeGramCounts(grams: anytype, comptime filename: []const u8, n: u8) !void {
    const allocator = std.heap.page_allocator;

    var a_keys = std.ArrayList(u64).init(allocator);
    var b_keys = std.ArrayList(u64).init(allocator);
    var c_keys = std.ArrayList(u64).init(allocator);
    var d_keys = std.ArrayList(u64).init(allocator);
    var e_keys = std.ArrayList(u64).init(allocator);
    var f_keys = std.ArrayList(u64).init(allocator);

    defer a_keys.deinit();
    defer b_keys.deinit();
    defer c_keys.deinit();
    defer d_keys.deinit();
    defer e_keys.deinit();
    defer f_keys.deinit();

    var ta: u32 = 0;
    var tb: u32 = 0;
    var tc: u32 = 0;
    var td: u32 = 0;
    var te: u32 = 0;
    var tf: u32 = 0;

    var it = grams.iterator();
    while (it.next()) |kv| {
        if (n == 1) {
            // 1-gram
            // ......
            //
        } else { // 2,3,4-gram
            switch (kv.value_ptr.*) { // count
                1 => if (n == 2) {
                    ta += 1;
                    try a_keys.append(kv.key_ptr.*);
                },
                2 => {
                    ta += 1;
                    try a_keys.append(kv.key_ptr.*);
                },
                3...5 => {
                    tb += 1;
                    try b_keys.append(kv.key_ptr.*);
                },
                6...11 => {
                    tc += 1;
                    try c_keys.append(kv.key_ptr.*);
                },
                12...25 => {
                    td += 1;
                    try d_keys.append(kv.key_ptr.*);
                },
                26...80 => {
                    te += 1;
                    try e_keys.append(kv.key_ptr.*);
                },
                else => {
                    tf += 1;
                    try f_keys.append(kv.key_ptr.*);
                },
            }
        }
    }

    if (n == 1) {
        std.debug.print("n-gram/ a: count=2, b: count=3..5, c: count=6..11, d: count=12..25, e: count=26..80, f: remain", .{});
        return; // 1-gram don't use binary fuse
    }

    std.debug.print(
        "\n{}-gram/ a: {}, b: {}, c: {}, d: {}, e: {}, f: {}",
        .{ n, ta, tb, tc, td, te, tf },
    );

    const a_filter = try BinaryFuse(u08).init(allocator, a_keys.items.len);
    const b_filter = try BinaryFuse(u16).init(allocator, b_keys.items.len);

    defer a_filter.deinit();
    defer b_filter.deinit();

    try a_filter.populate(allocator, a_keys.items);
    try b_filter.populate(allocator, b_keys.items);

    // BFF: Binary Fuse Filter
    var fa = try std.fs.cwd().createFile(filename ++ "_a.bff", .{});
    var fb = try std.fs.cwd().createFile(filename ++ "_b.bff", .{});
    var fc = try std.fs.cwd().createFile(filename ++ "_c.bff", .{});
    var fd = try std.fs.cwd().createFile(filename ++ "_d.bff", .{});
    var fe = try std.fs.cwd().createFile(filename ++ "_e.bff", .{});
    var ff = try std.fs.cwd().createFile(filename ++ "_f.bff", .{});

    defer fa.close();
    defer fb.close();
    defer fc.close();
    defer fd.close();
    defer fe.close();
    defer ff.close();

    // var fa_wrt = std.io.bufferedWriter(fa.writer());
    // var fa_writer = fa_wrt.writer();
    // try fa_wrt.flush();
}

test "ngram" {
    const text_utils = @import("../textoken/text_utils.zig");
    var gram: NGram() = .{};
    // gram.init(std.testing.allocator);
    gram.init(std.heap.page_allocator);
    defer gram.deinit();

    var text = Text{
        // .init_allocator = std.testing.allocator,
        .init_allocator = std.heap.page_allocator,
    };
    try text.initFromInputBytes("Cả nhà nhà nhà nhà nhà nhà nhà nhà nhà đơi thử nghiệm nhé , cả nhà ! TAQs cả nhà");
    defer text.deinit();

    var it = std.mem.tokenize(u8, text.input_bytes, " ");
    var attrs: Text.TokenAttributes = .{
        .category = .alphmark,
        .fenced_by_spaces = .both,
    };
    while (it.next()) |tkn| {
        try text.recordToken(tkn, attrs, false);
    }

    text.tokens_num_finalized = true;
    text_utils.parseTokens(&text);
    try gram.loadSyllableIdsFromText(text);

    try gram.countAndWrite(
        "data/temp.n1",
        "data/temp.n2",
        "data/temp.n3",
        "data/temp.n4",
    );
}
