const std = @import("std");

const Text = @import("./text_data_struct.zig").Text;
const syllable_data_structs = @import("./syllable_data_structs.zig");
const Syllable = syllable_data_structs.Syllable;
const BLANK: Syllable.UniqueId = 0;

fn order_by_count_desc(context: void, a: *GramTrie.Node, b: *GramTrie.Node) bool {
    _ = context;
    return a.count > b.count;
}

pub fn writeGramCounts(gram: *GramTrie, len: u8, filename: []const u8) !void {
    var buffer: [13 * 5]u8 = undefined;

    var list = gram.n_gram_lists[len];
    // Sort by count desc
    std.sort.sort(*GramTrie.Node, list.items, {}, order_by_count_desc);

    var file = try std.fs.cwd().createFile(filename, .{});
    defer file.close();
    var wrt = std.io.bufferedWriter(file.writer());

    for (list.items) |item| {
        const count = item.count;
        if (count < 3) break;
        var node = item;
        var n: usize = 0;
        while (true) {
            const buff = buffer[n..];
            const syll = Syllable.newFromId(node.key).printBuffUtf8(buff);
            n += syll.len;
            // std.debug.print("\n{s}", .{syll});
            if (node.parent != &gram.root) {
                buffer[n] = 32;
                n += 1;
            } else break;
            node = node.parent;
        }
        try wrt.writer().print("{d} {s}\n", .{
            count,
            buffer[0..n],
        });
    }

    try wrt.flush();
}

pub const GramTrie = struct {
    const Key = Syllable.UniqueId;
    const Children = std.AutoHashMap(Key, *Node);

    pub const Node = struct {
        key: Key,
        count: u32 = 0,
        parent: *Node = undefined,
        children: Children = undefined,

        fn getOrPutThenCount(self: *Node, key: Key, allocator: *std.mem.Allocator) !*Node {
            var node = self.children.get(key);
            const not_new = (node != null);

            if (not_new) {
                node.?.count += 1;
                return node.?;
            } else {
                var new_node = try allocator.create(Node);
                new_node.key = key;
                new_node.parent = self;
                new_node.children = Children.init(allocator);
                new_node.count = 1;
                try self.children.put(key, new_node);
                return new_node;
            }
        }
    };

    const NGramList = std.ArrayList(*Node);

    pub const MAX_N = 5;

    root: Node = .{ .key = BLANK },

    n_gram_lists: *[MAX_N]NGramList = undefined,

    arena: std.heap.ArenaAllocator = undefined,

    allocator: *std.mem.Allocator = undefined,

    pub fn init(self: *GramTrie, init_allocator: *std.mem.Allocator) void {
        self.arena = std.heap.ArenaAllocator.init(init_allocator);
        self.allocator = &self.arena.allocator;
        self.root.children = Children.init(&self.arena.allocator);
    }

    pub fn deinit(self: *GramTrie) void {
        self.arena.deinit();
    }

    pub fn count(self: *GramTrie, keys: []const Key) !*Node {
        var curr_node = &self.root;
        for (keys) |key, i| {
            // std.debug.print("key={d} count={d}, ", .{ key, curr_node.count });
            if (key == BLANK) break;
            curr_node = try curr_node.getOrPutThenCount(key, self.allocator);
            if (curr_node.count == 1) { // first apprear
                try self.n_gram_lists[i].append(curr_node);
            }
        }
        // std.debug.print("count={d}\n", .{curr_node.count});
        return curr_node;
    }

    pub const Error = error{
        TextNotFinalized,
    };

    pub fn init_n_gram_lists(self: *GramTrie, n: usize) !void {
        self.n_gram_lists = try self.allocator.create([MAX_N]NGramList);
        var i: u8 = 0;
        while (i < MAX_N) : (i += 1) {
            self.n_gram_lists[i] = try NGramList.initCapacity(self.allocator, n);
        }
    }

    pub fn parse(self: *GramTrie, text: Text) !void {
        if (!text.tokens_number_finalized) return Error.TextNotFinalized;

        try self.init_n_gram_lists(text.syllable_types.count());

        var keys: [5]Syllable.UniqueId = .{ BLANK, BLANK, BLANK, BLANK, BLANK };

        for (text.tokens_infos) |token_info| {
            //
            keys[4] = keys[3];
            keys[3] = keys[2];
            keys[2] = keys[1];
            keys[1] = keys[0];
            keys[0] = token_info.syllable_id;
            _ = try self.count(&keys);
        }
    }
};

test "GramTrie" {
    var gt: GramTrie = .{};
    gt.init(std.testing.allocator); // use std.heap.page_allocator for real
    try gt.init_n_gram_lists(1);

    defer gt.deinit();

    std.debug.print("\nGramTrie:\n", .{});

    var node = try gt.count(&.{ 5, 1, 2 });
    try std.testing.expect(2 == node.key);
    try std.testing.expect(1 == node.count);
    try std.testing.expect(5 == gt.n_gram_lists[0].items[0].key);
    try std.testing.expect(1 == gt.n_gram_lists[1].items[0].key);
    try std.testing.expect(2 == gt.n_gram_lists[2].items[0].key);
    try std.testing.expect(1 == gt.n_gram_lists[0].items.len);
    try std.testing.expect(1 == gt.n_gram_lists[1].items.len);
    try std.testing.expect(1 == gt.n_gram_lists[2].items.len);
    try std.testing.expect(0 == gt.n_gram_lists[3].items.len);
    try std.testing.expect(0 == gt.n_gram_lists[4].items.len);

    node = try gt.count(&.{ 5, 1, 2 });
    try std.testing.expect(2 == node.key);
    try std.testing.expect(2 == node.count);
    try std.testing.expect(1 == gt.n_gram_lists[0].items.len);
    try std.testing.expect(1 == gt.n_gram_lists[1].items.len);
    try std.testing.expect(1 == gt.n_gram_lists[2].items.len);
    try std.testing.expect(0 == gt.n_gram_lists[3].items.len);
    try std.testing.expect(0 == gt.n_gram_lists[4].items.len);

    node = try gt.count(&.{ 5, 1, 0 });
    try std.testing.expect(1 == node.key);
    try std.testing.expect(3 == node.count);
    try std.testing.expect(3 == gt.n_gram_lists[0].items[0].count);
    try std.testing.expect(3 == gt.n_gram_lists[1].items[0].count);
    try std.testing.expect(2 == gt.n_gram_lists[2].items[0].count);
    try std.testing.expect(1 == gt.n_gram_lists[0].items.len);
    try std.testing.expect(1 == gt.n_gram_lists[1].items.len);
    try std.testing.expect(1 == gt.n_gram_lists[2].items.len);
    try std.testing.expect(0 == gt.n_gram_lists[3].items.len);
    try std.testing.expect(0 == gt.n_gram_lists[4].items.len);

    node = try gt.count(&.{ 4, 0, 4, 4 });
    try std.testing.expect(4 == node.key);
    try std.testing.expect(1 == node.count);
    try std.testing.expect(4 == gt.n_gram_lists[0].items[1].key);
    try std.testing.expect(1 == gt.n_gram_lists[0].items[1].count);
    try std.testing.expect(2 == gt.n_gram_lists[0].items.len);
    try std.testing.expect(1 == gt.n_gram_lists[1].items.len);
    try std.testing.expect(1 == gt.n_gram_lists[2].items.len);
    try std.testing.expect(0 == gt.n_gram_lists[3].items.len);
    try std.testing.expect(0 == gt.n_gram_lists[4].items.len);
}

test "parse ngram from text" {
    const text_utils = @import("./text_utils.zig");
    var gt: GramTrie = .{};
    gt.init(std.testing.allocator); // use std.heap.page_allocator for real
    defer gt.deinit();

    std.debug.print("\nNGram:\n", .{});

    var text = Text{
        .init_allocator = std.testing.allocator,
    };
    try text.initFromInputBytes("Cả nhà đơi thử nghiệm nhé , cả nhà ! TAQs");
    defer text.deinit();

    var it = std.mem.tokenize(text.input_bytes, " ");
    var attrs: Text.TokenAttributes = .{
        .category = .alphabet,
        .surrounded_by_spaces = .both,
    };
    while (it.next()) |tkn| {
        try text.recordToken(tkn, attrs);
    }

    text.tokens_number_finalized = true;
    text_utils.parseTokens(&text);
    try gt.parse(text);
    try writeGramCounts(&gt, 1, "data/temp.txt");
}

// try n_gram.writeGramCounts(&gram, 1, "data/17-bi_gram.txt");
// try n_gram.writeGramCounts(&gram, 2, "data/18-tri_gram.txt");
// try n_gram.writeGramCounts(&gram, 3, "data/19-four_gram.txt");
// try n_gram.writeGramCounts(&gram, 4, "data/20-five_gram.txt");
