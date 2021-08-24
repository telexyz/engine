const std = @import("std");
const Syllable = @import("./src/phoneme/syllable_data_structs.zig").Syllable;
const parsers = @import("./src/phoneme/syllable_parsers.zig");

pub fn main() !void {
    var input_file = try std.fs.cwd().openFile("data/08-syllower_freqs.txt", .{
        .read = true,
    });
    defer input_file.close();

    var input_bytes = try input_file.reader().readAllAlloc(
        std.heap.page_allocator,
        1024 * 1024,
    );
    defer std.heap.page_allocator.free(input_bytes);

    var syllable_ids_counts = std.AutoHashMap(Syllable.UniqueId, u32).init(std.heap.page_allocator);
    defer syllable_ids_counts.deinit();

    var buffer: [15]u8 = undefined;
    var it = std.mem.tokenize(u8, input_bytes, "\n");
    while (it.next()) |str| {
        var i: u8 = 0;
        while (str[i] != ' ') : (i += 1) {}
        const count = try std.fmt.parseInt(u32, str[0..i], 10);
        const token = str[i + 1 ..];
        var syllable = parsers.parseXyzToGetSyllable(token);
        syllable.normalize();
        // std.debug.print("{s} {s} {}\n", .{ token, syllable.printBuffUtf8(buffer[0..]), syllable }); //DEBUG
        try syllable_ids_counts.put(syllable.toId(), count);
    }

    var i: Syllable.UniqueId = 0;
    var n: Syllable.UniqueId = 0;
    var x: Syllable.UniqueId = 0;

    while (i < Syllable.MAXX_ID) : (i += 1) {
        if (parsers.validateSyllable(Syllable.newFromId(i))) {
            const r = syllable_ids_counts.get(i);
            if (r == null) {
                // Chỉ print thanh 's'
                var syll = Syllable.newFromId(i);
                if (syll.tone == .s) {
                    std.debug.print("{s} ", .{syll.printBuffUtf8(buffer[0..])});
                    x += 1;
                    if (@rem(x, 20) == 0) std.debug.print("\n\n", .{});
                    // if (@rem(x, 400) == 0) std.debug.print("\n\n", .{});
                }
                n += 1;
            }
        }
    }
    std.debug.print("\n\nTotal maybe invalid slots: {d}\n\n", .{n});
}

test "find-out more slots that not valid syllables" {
    var j: Syllable.UniqueId = 0;
    var i: Syllable.UniqueId = 0;
    var n: Syllable.UniqueId = 0;

    std.debug.print("\n\nFinding invalid slots ...\n\n", .{});

    while (i < Syllable.MAXX_ID) : (i += 1) {
        if (!parsers.validateSyllable(Syllable.newFromId(i))) {
            n += 1;
            std.debug.print("{d} ", .{i});
            if (i != j + 1) { // not consecutive
                std.debug.print("\n\n", .{});
            }
            j = i;
        }
    }
    std.debug.print("\n\nTotal invalid slots: {d}\n\n", .{n});
}
