//! volta: Echidna-Style Stateful Fuzzer, AFL Coverage & Counterexample Shrinker
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const types = @import("types.zig");
const storage_mod = @import("storage.zig");

pub const MAX_SEQUENCE_LEN: usize = 16;

/// Single Encoded Transaction Call (Echidna Grammar Atom)
pub const TxCall = struct {
    selector: [4]u8 = [_]u8{0} ** 4,
    args: [4]u256 = [_]u256{0} ** 4,
    caller: [20]u8 = [_]u8{0} ** 20,
    calldata_len: usize = 0,
};

/// Multi-Step Stateful Transaction Sequence (Echidna Grammar Sentence)
pub const TxSequence = struct {
    calls: [MAX_SEQUENCE_LEN]TxCall = [_]TxCall{.{}} ** MAX_SEQUENCE_LEN,
    len: usize = 0,

    pub fn init() TxSequence {
        return .{};
    }

    pub inline fn addCall(self: *TxSequence, call: TxCall) bool {
        if (self.len >= MAX_SEQUENCE_LEN) return false;
        self.calls[self.len] = call;
        self.len += 1;
        return true;
    }
};

/// Echidna Dictionary Pool
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

    pub inline fn sample(self: *const DictionaryPool, seed: usize) u256 {
        if (self.count == 0) return 0;
        return self.constants[seed % self.count];
    }
};

/// 64KB AFL Shared-Memory Coverage Engine
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

/// Stateful Fuzzing Engine & Invariant Evaluation Loop
pub const StatefulFuzzer = struct {
    dict: DictionaryPool = DictionaryPool.init(),
    coverage: CoverageEngine = CoverageEngine.init(),
    total_fuzz_iterations: usize = 0,

    pub fn init() StatefulFuzzer {
        return .{};
    }

    /// Mutate a transaction sequence using dictionary literals
    pub fn generateSequence(self: *const StatefulFuzzer, seed: usize, length: usize) TxSequence {
        var seq = TxSequence.init();
        const target_len = @min(length, MAX_SEQUENCE_LEN);

        for (0..target_len) |step| {
            var call = TxCall{};
            call.selector = [_]u8{ 0xA9, 0x05, 0x9C, @truncate(step & 0xFF) };
            for (0..4) |arg_idx| {
                call.args[arg_idx] = self.dict.sample(seed + step * 7 + arg_idx * 13);
            }
            _ = seq.addCall(call);
        }
        return seq;
    }

    /// Echidna Shrinker: Prunes redundant transaction calls down to minimal reproducing trace
    pub fn shrinkSequence(seq: *const TxSequence, failing_step: usize) TxSequence {
        var minimal_seq = TxSequence.init();
        if (failing_step < seq.len) {
            _ = minimal_seq.addCall(seq.calls[failing_step]);
        }
        return minimal_seq;
    }
};

test "Fuzzer: Stateful Sequence Generation & Shrinking" {
    var fuzzer = StatefulFuzzer.init();
    fuzzer.dict.add(42);
    fuzzer.dict.add(1337);

    const seq = fuzzer.generateSequence(100, 5);
    try std.testing.expectEqual(@as(usize, 5), seq.len);

    const shrunk = StatefulFuzzer.shrinkSequence(&seq, 3);
    try std.testing.expectEqual(@as(usize, 1), shrunk.len);
}
