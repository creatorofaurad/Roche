//! volta: Echidna-Style Dictionary Pool & 64KB AFL Coverage Feedback Engine
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const types = @import("types.zig");

pub const DictionaryPool = struct {
    constants: [types.MAX_DICTIONARY_CONSTS]u256 = [_]u256{0} ** types.MAX_DICTIONARY_CONSTS,
    count: usize = 0,

    pub fn init() DictionaryPool {
        var pool = DictionaryPool{};
        pool.seedDefaults();
        return pool;
    }

    pub fn seedDefaults(self: *DictionaryPool) void {
        self.count = 0;
        self.add(0);
        self.add(1);
        self.add(2);
        self.add(10);
        self.add(100);
        self.add(1_000_000); // 1e6 (USDC decimals)
        self.add(1_000_000_000_000_000_000); // 1e18 (ETH standard)
        self.add(std.math.maxInt(u128));
        self.add(std.math.maxInt(u256));
    }

    pub fn extractFromBytecode(self: *DictionaryPool, bytecode: []const u8) void {
        var pc: usize = 0;
        while (pc < bytecode.len) {
            const op = bytecode[pc];
            pc += 1;

            if (op >= 0x60 and op <= 0x7F) { // PUSH1 to PUSH32
                const num_bytes: usize = op - 0x60 + 1;
                var val: u256 = 0;
                for (0..num_bytes) |_| {
                    if (pc < bytecode.len) {
                        val = (val << 8) | @as(u256, bytecode[pc]);
                        pc += 1;
                    }
                }
                self.add(val);
            }
        }
    }

    pub inline fn add(self: *DictionaryPool, val: u256) void {
        if (self.count >= types.MAX_DICTIONARY_CONSTS) return;
        for (0..self.count) |i| {
            if (self.constants[i] == val) return;
        }
        self.constants[self.count] = val;
        self.count += 1;
    }
};

pub const CoverageEngine = struct {
    bitmap: [types.COVERAGE_BITMAP_SIZE]u8 = [_]u8{0} ** types.COVERAGE_BITMAP_SIZE,
    prev_pc: usize = 0,
    total_edges_hit: usize = 0,

    pub fn init() CoverageEngine {
        return .{};
    }

    pub inline fn recordBranch(self: *CoverageEngine, current_pc: usize) void {
        const edge = ((self.prev_pc >> 1) ^ current_pc) & (types.COVERAGE_BITMAP_SIZE - 1);
        if (self.bitmap[edge] == 0) {
            self.total_edges_hit += 1;
        }
        self.bitmap[edge] +%= 1;
        self.prev_pc = current_pc;
    }

    pub inline fn resetTrace(self: *CoverageEngine) void {
        self.prev_pc = 0;
    }

    pub inline fn resetAll(self: *CoverageEngine) void {
        @memset(&self.bitmap, 0);
        self.prev_pc = 0;
        self.total_edges_hit = 0;
    }
};

test "Fuzzer: Dictionary and Coverage Feedback" {
    var dict = DictionaryPool.init();
    const code = [_]u8{ 0x60, 0x42, 0x61, 0x03, 0xE8, 0x00 };
    dict.extractFromBytecode(&code);
    try std.testing.expect(dict.count >= 11);

    var cov = CoverageEngine.init();
    cov.recordBranch(0x10);
    cov.recordBranch(0x20);
    try std.testing.expect(cov.total_edges_hit >= 1);
}
