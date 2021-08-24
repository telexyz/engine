const std = @import("std");
const Syllable = @import("./src/phoneme/syllable_data_structs.zig").Syllable;
const isValidSyll = @import("./src/phoneme/syllable_parsers.zig").validateSyllable;

test "find-out more slots that not valid syllables" {
    var j: Syllable.UniqueId = 0;
    var i: Syllable.UniqueId = 0;
    var n: Syllable.UniqueId = 0;

    std.debug.print("\n\nFinding invalid slots ...\n\n", .{});

    while (i < Syllable.MAXX_ID) : (i += 1) {
        if (!isValidSyll(Syllable.newFromId(i))) {
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
