// u32 cityhash, customized Fnv1a as fingerprint
// 1-gram U: 11620, U1: 1283, U2: 710, U3+: 9627, M: 1656827
// 2-gram U: 2666022, U1: 1075256, U2: 369392, U3+: 1221374, M: 414990
// 3-gram U: 18228074, U1: 11405980, U2: 2479025, U3+: 4343069, M: 141624
// 4-gram U: 38701839, U1: 28874573, U2: 4412961, U3+: 5414305, M: 56755
// 5-gram U: 49034524, U1: 40203323, U2: 4543598, U3+: 4287603, M: 48105
// 6-gram U: 49381946, U1: 42503176, U2: 3863873, U3+: 3014897, M: 37901
// (( STEP 3: Count and write n-gram done! Duration 1.99 mins ))

// 2048 cached syllable_ids
// 1-gram U: 11621, U1: 1283, U2: 710, U3+: 9628, M: 10069810
// 2-gram U: 2666022, U1: 1075256, U2: 369392, U3+: 1221374, M: 414990
// 3-gram U: 18228074, U1: 11405980, U2: 2479025, U3+: 4343069, M: 141624
// 4-gram U: 38701839, U1: 28874573, U2: 4412961, U3+: 5414305, M: 56755
// 5-gram U: 49034524, U1: 40203323, U2: 4543598, U3+: 4287603, M: 48105
// 6-gram U: 49381946, U1: 42503176, U2: 3863873, U3+: 3014897, M: 37901
// (( STEP 3: Count and write n-gram done! Duration 1.81 mins ))

const std = @import("std");
const mem = std.mem;

const Text = @import("../textoken/text_data_struct.zig").Text;
const Syllable = @import("../phoneme/syllable_data_structs.zig").Syllable;
const hash_count = @import("./hash_count.zig");
const HashCount123 = hash_count.HashCount123;
const HashCount456 = hash_count.HashCount456;

const Gram = Syllable.UniqueId;
const BLANK: Gram = Syllable.NONE_ID;
const SyllableIdArray = std.ArrayList(Syllable.UniqueId);
const fvn1a32 = @import("../hashing/fvn1a32.zig");

pub fn NGram(for_real: bool) type {
    return struct {

        // Configs for ../data/combined.txt 944 MB
        c1_grams: HashCount123([1]Gram, if (!for_real) 64 else 16_384) = undefined,
        c2_grams: HashCount123([2]Gram, if (!for_real) 64 else 4_194_304) = undefined,
        c3_grams: HashCount123([3]Gram, if (!for_real) 64 else 33_554_432) = undefined, //2^25
        c4_grams: HashCount456([4]Gram, if (!for_real) 64 else 67_108_864) = undefined, //2^26
        c5_grams: HashCount456([5]Gram, if (for_real) 64 else 67_108_864) = undefined, //2^26
        c6_grams: HashCount456([6]Gram, if (for_real) 64 else 67_108_864) = undefined, //2^26
        // L??m tr??n th??nh powerOfTwo ????? ?????m b???o th??? t??? t??ng d???n c???a hash values

        // Configs for ../phaps/data/all.txt 8.6 MB
        // c1_grams: HashCount123([1]Gram, if (!for_real) 64 else 16_384) = undefined,
        // c2_grams: HashCount123([2]Gram, if (!for_real) 64 else 2_097_152) = undefined,
        // c3_grams: HashCount123([3]Gram, if (!for_real) 64 else 4_194_304) = undefined,
        // c4_grams: HashCount456([4]Gram, if (!for_real) 64 else 4_194_304) = undefined,
        // c5_grams: HashCount456([5]Gram, if (!for_real) 64 else 8_388_608) = undefined,
        // c6_grams: HashCount456([6]Gram, if (!for_real) 64 else 8_388_608) = undefined,
        // L??m tr??n th??nh powerOfTwo ????? ?????m b???o th??? t??? t??ng d???n c???a hash values

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
            var file = try std.fs.cwd().openFile(filename, .{ .read = true });
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
            comptime filename5: []const u8,
            comptime filename6: []const u8,
        ) !void {
            //

            try self.syllable_ids.append(BLANK);
            try self.syllable_ids.append(BLANK);
            try self.syllable_ids.append(BLANK);
            try self.syllable_ids.append(BLANK);
            try self.syllable_ids.append(BLANK);
            try self.syllable_ids.append(BLANK);

            const n = self.syllable_ids.items.len;
            const _percents: u8 = 5;
            const _percents_delta = (n * _percents / 100);
            var percents_threshold = _percents_delta;
            var percents: u8 = 0;

            try self.c1_grams.init(self.allocator);
            try self.c2_grams.init(self.allocator);
            try self.c3_grams.init(self.allocator);
            try self.c4_grams.init(self.allocator);
            try self.c5_grams.init(self.allocator);
            try self.c6_grams.init(self.allocator);

            var i: usize = 5;
            const syll_ids = self.syllable_ids.items;
            var grams: [6]Gram = .{ 0, syll_ids[0], syll_ids[1], syll_ids[2], syll_ids[3], syll_ids[4] };

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
                    std.debug.print("Counting 1..6-grams {d}%\n", .{percents});
                }

                for (buf[0 .. max - i]) |syll_id| {
                    grams[0] = grams[1];
                    grams[1] = grams[2];
                    grams[2] = grams[3];
                    grams[3] = grams[4];
                    grams[4] = grams[5];
                    grams[5] = syll_id;

                    var fp = fvn1a32.hash_u16(fvn1a32.init_offset, grams[0]);
                    _ = self.c1_grams.put_with_fp(.{grams[0]}, @truncate(u16, fp));

                    if (grams[0] == BLANK) {
                        if (grams[1] == BLANK) continue;
                        fp = fvn1a32.hash_u16(fp, grams[1]);
                        _ = self.c2_grams.put_with_fp(grams[0..2].*, @truncate(u16, fp));

                        if (grams[2] == BLANK) continue;
                        fp = fvn1a32.hash_u16(fp, grams[2]);
                        _ = self.c3_grams.put_with_fp(grams[0..3].*, @truncate(u16, fp));

                        if (grams[3] == BLANK) continue;
                        fp = fvn1a32.hash_u16(fp, grams[3]);
                        _ = self.c4_grams.put_with_fp(grams[0..4].*, @truncate(u24, fp));

                        // if (grams[4] == BLANK) continue;
                        // fp = fvn1a32.hash_u16(fp, grams[4]);
                        // _ = self.c5_grams.put_with_fp(grams[0..5].*, @truncate(u24, fp));

                        // if (grams[5] == BLANK) continue;
                        // fp = fvn1a32.hash_u16(fp, grams[5]);
                        // _ = self.c6_grams.put_with_fp(grams, @truncate(u24, fp));
                        //
                    } else { // grams[0] != BLANK
                        //
                        fp = fvn1a32.hash_u16(fp, grams[1]);
                        _ = self.c2_grams.put_with_fp(grams[0..2].*, @truncate(u16, fp));

                        if (grams[1] == BLANK or grams[2] == BLANK) continue;
                        fp = fvn1a32.hash_u16(fp, grams[2]);
                        _ = self.c3_grams.put_with_fp(grams[0..3].*, @truncate(u16, fp));

                        if (grams[2] == BLANK) continue;
                        fp = fvn1a32.hash_u16(fp, grams[3]);
                        _ = self.c4_grams.put_with_fp(grams[0..4].*, @truncate(u24, fp));

                        // if (grams[3] == BLANK) continue;
                        // fp = fvn1a32.hash_u16(fp, grams[4]);
                        // _ = self.c5_grams.put_with_fp(grams[0..5].*, @truncate(u24, fp));

                        // if (grams[4] == BLANK) continue;
                        // fp = fvn1a32.hash_u16(fp, grams[5]);
                        // _ = self.c6_grams.put_with_fp(grams, @truncate(u24, fp));
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

            try writeGramCounts(self.c5_grams, filename5, 5);
            self.c5_grams.deinit();

            try writeGramCounts(self.c6_grams, filename6, 6);
            self.c6_grams.deinit();
        }

        const PAD = "\n                        ";
        pub fn countAndWrite23(self: *Self, comptime filename2: []const u8, comptime filename3: []const u8) !void {
            const syllable_ids = self.syllable_ids.items;
            const ten_percents = syllable_ids.len / 10;
            var percents_threshold = ten_percents;
            var percents: u8 = 0;

            try self.c2_grams.init(self.allocator);
            try self.c3_grams.init(self.allocator);

            var grams: [3]Gram = .{ BLANK, BLANK, BLANK };
            var i: usize = 0;

            while (i < syllable_ids.len) : (i += 1) {
                // Show progress
                if (i >= percents_threshold) {
                    percents += 10;
                    std.debug.print("\nCounting 2,3-gram {d}%", .{percents});
                    percents_threshold += ten_percents;
                }

                grams[0] = grams[1];
                grams[1] = grams[2];
                grams[2] = syllable_ids[i];

                if (!(grams[1] == BLANK and grams[2] == BLANK))
                    _ = self.c2_grams.put(grams[1..3].*);

                if (!(grams[1] == BLANK) and
                    !(grams[0] == BLANK and grams[2] == BLANK))
                    _ = self.c3_grams.put(grams);
            } // while

            try writeGramCounts(self.c2_grams, filename2, 2);
            self.c2_grams.deinit();

            try writeGramCounts(self.c3_grams, filename3, 3);
            self.c3_grams.deinit();
        }

        pub fn countAndWrite06(self: *Self, comptime filename6: []const u8) !void {
            const syllable_ids = self.syllable_ids.items;
            const ten_percents = syllable_ids.len / 10;
            var percents_threshold = ten_percents;
            var percents: u8 = 0;

            try self.c6_grams.init(self.allocator);

            var grams: [6]Gram = .{ BLANK, BLANK, BLANK, BLANK, BLANK, BLANK };
            var i: usize = 0;

            while (i < syllable_ids.len) : (i += 1) {
                // Show progress
                if (i >= percents_threshold) {
                    percents += 10;
                    // std.debug.print(PAD ++ "Counting 6-gram {d}%", .{percents});
                    percents_threshold += ten_percents;
                }

                grams[0] = grams[1];
                grams[1] = grams[2];
                grams[2] = grams[3];
                grams[3] = grams[4];
                grams[4] = grams[5];
                grams[5] = syllable_ids[i];

                if (grams[1] == BLANK or grams[2] == BLANK) continue;
                if (grams[3] == BLANK or grams[4] == BLANK) continue;
                if (grams[0] == BLANK and grams[5] == BLANK) continue;
                _ = self.c6_grams.put(grams);
            } // while

            try writeGramCounts(self.c6_grams, filename6, 6);
            self.c6_grams.deinit();
        }

        pub fn countAndWrite15(self: *Self, comptime filename1: []const u8, comptime filename5: []const u8) !void {
            const syllable_ids = self.syllable_ids.items;
            const ten_percents = syllable_ids.len / 10;
            var percents_threshold = ten_percents;
            var percents: u8 = 0;

            try self.c1_grams.init(self.allocator);
            try self.c5_grams.init(self.allocator);

            var grams: [5]Gram = .{ BLANK, BLANK, BLANK, BLANK, BLANK };
            var i: usize = 0;

            while (i < syllable_ids.len) : (i += 1) {
                // Show progress
                if (i >= percents_threshold) {
                    percents += 10;
                    // std.debug.print(PAD ++ "Counting 1,5-gram {d}%", .{percents});
                    percents_threshold += ten_percents;
                }

                grams[0] = grams[1];
                grams[1] = grams[2];
                grams[2] = grams[3];
                grams[3] = grams[4];
                grams[4] = syllable_ids[i];

                if (grams[4] != BLANK)
                    _ = self.c1_grams.put(.{grams[4]});

                if (!(grams[1] == BLANK or grams[2] == BLANK or grams[3] == BLANK) and
                    !(grams[0] == BLANK and grams[4] == BLANK))
                    _ = self.c5_grams.put(grams);
            }

            try writeGramCounts(self.c1_grams, filename1, 1);
            self.c1_grams.deinit();

            try writeGramCounts(self.c5_grams, filename5, 5);
            self.c5_grams.deinit();
        }

        pub fn countAndWrite04(self: *Self, comptime filename4: []const u8) !void {
            const syllable_ids = self.syllable_ids.items;
            const ten_percents = syllable_ids.len / 10;
            var percents_threshold = ten_percents;
            var percents: u8 = 0;

            try self.c4_grams.init(self.allocator);

            var grams: [4]Gram = .{ BLANK, BLANK, BLANK, BLANK };
            var i: usize = 0;

            while (i < syllable_ids.len) : (i += 1) {
                // Show progress
                if (i >= percents_threshold) {
                    percents += 10;
                    // std.debug.print("\nCounting 4-gram {d}%", .{percents});
                    percents_threshold += ten_percents;
                }

                grams[0] = grams[1];
                grams[1] = grams[2];
                grams[2] = grams[3];
                grams[3] = syllable_ids[i];

                if (!(grams[1] == BLANK or grams[2] == BLANK) and
                    !(grams[0] == BLANK and grams[3] == BLANK))
                    _ = self.c4_grams.put(grams);
            }

            try writeGramCounts(self.c4_grams, filename4, 4);
            self.c4_grams.deinit();
        }
    };
}

fn orderFn(comptime T: type) type {
    return struct {
        pub fn order_by_count_desc(context: void, a: T, b: T) bool {
            _ = context;
            return a.count > b.count;
        }
    };
}

fn writeGramCounts(grams: anytype, comptime filename: []const u8, n: u8) !void {
    var file = try std.fs.cwd().createFile(filename ++ ".bin", .{});
    defer file.close();

    var f1 = try std.fs.cwd().createFile(filename ++ ".one", .{});
    defer f1.close();

    var f2 = try std.fs.cwd().createFile(filename ++ ".two", .{});
    defer f2.close();

    var f3 = try std.fs.cwd().createFile(filename ++ ".three", .{});
    defer f3.close();

    var f4 = try std.fs.cwd().createFile(filename ++ ".four", .{});
    defer f4.close();

    var f5 = try std.fs.cwd().createFile(filename ++ ".five", .{});
    defer f5.close();

    var wrt = std.io.bufferedWriter(file.writer());
    var writer = wrt.writer();

    var f1_wrt = std.io.bufferedWriter(f1.writer());
    var f1_writer = f1_wrt.writer();

    var f2_wrt = std.io.bufferedWriter(f2.writer());
    var f2_writer = f2_wrt.writer();

    var f3_wrt = std.io.bufferedWriter(f3.writer());
    var f3_writer = f3_wrt.writer();

    var f4_wrt = std.io.bufferedWriter(f4.writer());
    var f4_writer = f4_wrt.writer();

    var f5_wrt = std.io.bufferedWriter(f5.writer());
    var f5_writer = f5_wrt.writer();

    var total: usize = 0;
    var t1: usize = 0;
    var t2: usize = 0;
    var t3: usize = 0;
    var t4: usize = 0;
    var t5: usize = 0;
    var max: u24 = 0;
    var count: u24 = undefined;

    if (grams.len > 0) {
        for (grams.slice()) |item| {
            count = item.count;
            switch (count) {
                0 => {}, // do nothing
                1 => {
                    t1 += 1;
                    _ = try f1_writer.write(std.mem.asBytes(&item.keyRepresent()));
                    if (n == 1) {
                        _ = try writer.write(std.mem.asBytes(&count));
                        _ = try writer.write(std.mem.asBytes(&item.keyRepresent()));
                    }
                },
                2 => {
                    t2 += 1;
                    _ = try f2_writer.write(std.mem.asBytes(&item.keyRepresent()));
                    if (n == 1) {
                        _ = try writer.write(std.mem.asBytes(&count));
                        _ = try writer.write(std.mem.asBytes(&item.keyRepresent()));
                    }
                },
                3 => {
                    t3 += 1;
                    _ = try f3_writer.write(std.mem.asBytes(&item.keyRepresent()));
                    if (n == 1) {
                        _ = try writer.write(std.mem.asBytes(&count));
                        _ = try writer.write(std.mem.asBytes(&item.keyRepresent()));
                    }
                },
                4 => {
                    t4 += 1;
                    _ = try f4_writer.write(std.mem.asBytes(&item.keyRepresent()));
                    if (n == 1) {
                        _ = try writer.write(std.mem.asBytes(&count));
                        _ = try writer.write(std.mem.asBytes(&item.keyRepresent()));
                    }
                },
                5 => {
                    t5 += 1;
                    _ = try f5_writer.write(std.mem.asBytes(&item.keyRepresent()));
                    if (n == 1) {
                        _ = try writer.write(std.mem.asBytes(&count));
                        _ = try writer.write(std.mem.asBytes(&item.keyRepresent()));
                    }
                },
                else => {
                    total += count;
                    if (count > max) max = count;
                    _ = try writer.write(std.mem.asBytes(&count));
                    _ = try writer.write(std.mem.asBytes(&item.keyRepresent()));
                },
            }
        }
    }

    try wrt.flush();
    try f1_wrt.flush();
    try f2_wrt.flush();
    try f3_wrt.flush();
    try f4_wrt.flush();
    try f5_wrt.flush();

    total += t1 + 2 * t2 + 3 * t3 + 4 * t4; // finalize total
    std.debug.print("\n{}-gram U: {}, U1: {}, U2: {}, U3: {}, U4: {}, U5: {}, U6+: {}, T: {}, M: {}", .{ n, grams.len, t1, t2, t3, t4, t5, grams.len - t1 - t2 - t3 - t4 - t5, total, max });
}

test "ngram" {
    const text_utils = @import("../textoken/text_utils.zig");
    var gram: NGram(false) = .{};
    // gram.init(std.testing.allocator);
    gram.init(std.heap.page_allocator);
    defer gram.deinit();

    var text = Text{
        // .init_allocator = std.testing.allocator,
        .init_allocator = std.heap.page_allocator,
    };
    try text.initFromInputBytes("C??? nh?? nh?? nh?? nh?? nh?? nh?? nh?? nh?? nh?? ????i th??? nghi???m nh?? , c??? nh?? ! TAQs c??? nh??");
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
        "data/temp.n5",
        "data/temp.n6",
    );
}
