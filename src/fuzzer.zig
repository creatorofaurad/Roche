//! volta: Echidna-Style Stateful Fuzzer, AFL Coverage & Counterexample Shrinker
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.
//! 256-Bit AVX2 SIMD Coverage Bitmap Reset & Hierarchical Delta-Debugging (HDD).

const std = @import("std");
const types = @import("types.zig");
const storage_mod = @import("storage.zig");

pub const MAX_SEQUENCE_LEN: usize = 32;

/// Single Encoded Transaction Call (Echidna Grammar Atom)
pub const TxCall = struct {
    selector: [4]u8 = [_]u8{0} ** 4,
    args: [4]u256 = [_]u256{0} ** 4,
    caller: [20]u8 = [_]u8{0} ** 20,
    value: u256 = 0,
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

    pub inline fn clone(self: *const TxSequence) TxSequence {
        var copy = TxSequence.init();
        for (0..self.len) |i| {
            _ = copy.addCall(self.calls[i]);
        }
        return copy;
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
        self.add(1_000);
        self.add(1_000_000); // 1e6 (USDC decimals)
        self.add(1_000_000_000_000_000_000); // 1e18 (ETH standard)
        self.add(std.math.maxInt(u64));
        self.add(std.math.maxInt(u128));
        self.add(std.math.maxInt(u256) - 1);
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

/// 64KB AFL Shared-Memory Coverage Engine with Native AVX2 SIMD Zeroing
pub const CoverageEngine = struct {
    bitmap: [types.COVERAGE_BITMAP_SIZE]u8 align(64) = [_]u8{0} ** types.COVERAGE_BITMAP_SIZE,
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

    /// AVX2 256-Bit Hardware Vectorized Fast Bitmap Zeroing (2048 SIMD writes)
    pub inline fn resetAll(self: *CoverageEngine) void {
        const zero_vec: @Vector(32, u8) = @splat(0);
        var i: usize = 0;
        while (i < types.COVERAGE_BITMAP_SIZE) : (i += 32) {
            const ptr: *align(1) @Vector(32, u8) = @ptrCast(&self.bitmap[i]);
            ptr.* = zero_vec;
        }
        self.prev_pc = 0;
        self.total_edges_hit = 0;
    }
};

/// Mutation Strategy Enum
pub const MutationType = enum {
    DICTIONARY_REPLACE,
    BIT_FLIP,
    ARITHMETIC_STEP,
    BOUNDARY_VALUE,
    SHUFFLE_CALLS,
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

    /// Multi-Step Grammar & Dictionary Mutator
    pub fn mutateSequence(self: *const StatefulFuzzer, seq: *TxSequence, seed: u64) void {
        if (seq.len == 0) return;
        const mut_type = @as(MutationType, @enumFromInt(seed % 5));
        const call_idx = seed % seq.len;
        const arg_idx = (seed >> 8) % 4;

        switch (mut_type) {
            .DICTIONARY_REPLACE => {
                seq.calls[call_idx].args[arg_idx] = self.dict.sample(@truncate(seed));
            },
            .BIT_FLIP => {
                const bit_pos: u8 = @truncate(seed & 0xFF);
                seq.calls[call_idx].args[arg_idx] ^= (@as(u256, 1) << @intCast(bit_pos));
            },
            .ARITHMETIC_STEP => {
                const delta = (seed >> 16) & 0xFF;
                if ((seed & 1) == 0) {
                    seq.calls[call_idx].args[arg_idx] +%= delta;
                } else {
                    seq.calls[call_idx].args[arg_idx] -%= delta;
                }
            },
            .BOUNDARY_VALUE => {
                const boundary_choice = (seed >> 24) % 4;
                seq.calls[call_idx].args[arg_idx] = switch (boundary_choice) {
                    0 => 0,
                    1 => 1,
                    2 => std.math.maxInt(u128),
                    else => std.math.maxInt(u256),
                };
            },
            .SHUFFLE_CALLS => {
                if (seq.len > 1) {
                    const swap_target = (seed >> 32) % seq.len;
                    const tmp = seq.calls[call_idx];
                    seq.calls[call_idx] = seq.calls[swap_target];
                    seq.calls[swap_target] = tmp;
                }
            },
        }
    }

    /// Echidna / Delta-Debugging Shrinker: Single failing step extraction
    pub fn shrinkSequence(seq: *const TxSequence, failing_step: usize) TxSequence {
        var minimal_seq = TxSequence.init();
        if (failing_step < seq.len) {
            _ = minimal_seq.addCall(seq.calls[failing_step]);
        }
        return minimal_seq;
    }

    /// Hierarchical Delta-Debugging (HDD): Bisection and chunked trace reduction (O(N log N))
    pub fn minimizeTraceBisection(
        seq: *const TxSequence,
        verifier_context: anytype,
        verifier_fn: *const fn (@TypeOf(verifier_context), *const TxSequence) bool,
    ) TxSequence {
        if (seq.len <= 1) return seq.*;

        var current = seq.*;
        var chunk_size: usize = current.len / 2;

        while (chunk_size > 0) {
            var i: usize = 0;
            while (i + chunk_size <= current.len) {
                // Construct candidate sequence without this chunk
                var candidate = TxSequence.init();
                for (0..current.len) |idx| {
                    if (idx < i or idx >= i + chunk_size) {
                        _ = candidate.addCall(current.calls[idx]);
                    }
                }

                if (candidate.len > 0 and verifier_fn(verifier_context, &candidate)) {
                    current = candidate;
                    chunk_size = @min(chunk_size, current.len / 2);
                    break;
                } else {
                    i += chunk_size;
                }
            }
            chunk_size /= 2;
        }

        return current;
    }
};

test "Fuzzer: Stateful Sequence Generation & Shrinking" {
    var fuzzer = StatefulFuzzer.init();
    fuzzer.dict.add(42);
    fuzzer.dict.add(1337);

    var seq = fuzzer.generateSequence(100, 5);
    try std.testing.expectEqual(@as(usize, 5), seq.len);

    // Test Mutator
    fuzzer.mutateSequence(&seq, 0x12345678);
    try std.testing.expectEqual(@as(usize, 5), seq.len);

    // Test Shrinker
    const shrunk = StatefulFuzzer.shrinkSequence(&seq, 3);
    try std.testing.expectEqual(@as(usize, 1), shrunk.len);

    // Test AVX2 SIMD Coverage Reset
    fuzzer.coverage.recordBranch(0x10);
    fuzzer.coverage.recordBranch(0x20);
    try std.testing.expect(fuzzer.coverage.total_edges_hit > 0);
    fuzzer.coverage.resetAll();
    try std.testing.expectEqual(@as(usize, 0), fuzzer.coverage.total_edges_hit);
    for (fuzzer.coverage.bitmap) |byte| {
        try std.testing.expectEqual(@as(u8, 0), byte);
    }
}
