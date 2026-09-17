// ============================================================================
// VOLTA SILICON KERNEL: Port of Foundry Havoc Mutation & Invariant Strategy
// Invariant: Zero Heap Allocation | 64-Byte Cache Aligned | Zig 0.16.0
// ============================================================================

const std = @import("std");

pub const MAX_CALLDATA_LEN = 1024;
pub const MAX_CALL_SEQUENCE = 64;

pub const TxStep = struct {
    sender: [20]u8,
    target: [20]u8,
    value: u256,
    calldata: [MAX_CALLDATA_LEN]u8,
    calldata_len: usize,
};

pub const HavocEngine = struct {
    rng_state: u64,
    boundary_values: [16]u256,
    address_pool: [8][20]u8,

    pub fn init(seed: u64) HavocEngine {
        const engine = HavocEngine{
            .rng_state = if (seed == 0) 0x123456789ABCDEF0 else seed,
            .boundary_values = [_]u256{
                0,
                1,
                2,
                3,
                10,
                100,
                1000,
                1_000_000_000_000_000_000, // 1 ETH
                std.math.maxInt(u8),
                std.math.maxInt(u16),
                std.math.maxInt(u32),
                std.math.maxInt(u64),
                std.math.maxInt(u128),
                std.math.maxInt(u256) - 1,
                std.math.maxInt(u256),
                0xDEADBEEF,
            },
            .address_pool = [_][20]u8{
                [_]u8{0x00} ** 20,
                [_]u8{0x01} ** 20,
                [_]u8{0xAA} ** 20,
                [_]u8{0xBB} ** 20,
                [_]u8{0xCC} ** 20,
                [_]u8{0xDD} ** 20,
                [_]u8{0xEE} ** 20,
                [_]u8{0xFF} ** 20,
            },
        };
        return engine;
    }

    pub inline fn nextU64(self: *HavocEngine) u64 {
        var x = self.rng_state;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.rng_state = x;
        return x;
    }

    pub fn mutateStep(self: *HavocEngine, step: *TxStep) void {
        const mode = self.nextU64() % 6;
        switch (mode) {
            0 => { // Bit-flip mutation
                if (step.calldata_len > 0) {
                    const byte_idx = self.nextU64() % step.calldata_len;
                    const bit_idx: u3 = @intCast(self.nextU64() % 8);
                    step.calldata[byte_idx] ^= (@as(u8, 1) << bit_idx);
                }
            },
            1 => { // Boundary value injection
                if (step.calldata_len >= 36) {
                    const val_idx = self.nextU64() % self.boundary_values.len;
                    const val = self.boundary_values[val_idx];
                    var i: usize = 0;
                    while (i < 32) : (i += 1) {
                        const shift: u8 = @intCast((31 - i) * 8);
                        step.calldata[4 + i] = @intCast((val >> shift) & 0xFF);
                    }
                }
            },
            2 => { // Address pool swapping
                const addr_idx = self.nextU64() % self.address_pool.len;
                @memcpy(&step.sender, &self.address_pool[addr_idx]);
            },
            3 => { // Value boundary swap
                const val_idx = self.nextU64() % self.boundary_values.len;
                step.value = self.boundary_values[val_idx];
            },
            4 => { // SIMD 32-byte block xor
                if (step.calldata_len >= 32) {
                    const v: @Vector(32, u8) = step.calldata[0..32].*;
                    const mask: @Vector(32, u8) = @splat(@as(u8, @intCast(self.nextU64() & 0xFF)));
                    step.calldata[0..32].* = v ^ mask;
                }
            },
            else => { // Calldata byte swap
                if (step.calldata_len > 1) {
                    const idx1 = self.nextU64() % step.calldata_len;
                    const idx2 = self.nextU64() % step.calldata_len;
                    const tmp = step.calldata[idx1];
                    step.calldata[idx1] = step.calldata[idx2];
                    step.calldata[idx2] = tmp;
                }
            },
        }
    }
};
