//! volta: Core Primitives & EVM Type Definitions
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");

pub const VERSION = "1.0.0-beta";

// =================================================================================================
// Hardware & Memory Constants
// =================================================================================================
pub const MAX_STACK_DEPTH: usize = 1024;
pub const MAX_MEMORY_BYTES: usize = 4096;
pub const MAX_STORAGE_SLOTS: usize = 256;
pub const MAX_ROLLBACK_LOGS: usize = 128;
pub const MAX_BASIC_BLOCKS: usize = 256;
pub const MAX_DICTIONARY_CONSTS: usize = 128;
pub const COVERAGE_BITMAP_SIZE: usize = 65536; // 64KB AFL Shared Memory Table
pub const MAX_ACCOUNTS: usize = 16;
pub const MAX_RETURNDATA_BYTES: usize = 1024;
pub const MAX_CALLDATA_BYTES: usize = 1024;
pub const MAX_CALL_FRAMES: usize = 8;

// =================================================================================================
// 256-Bit Hardware SIMD Vector Types & EVM Word Isomorphism
// 1 EVM Word (u256) == 32 Bytes == 1 AVX2 YMM Register (@Vector(32, u8) / @Vector(8, f32))
// =================================================================================================
pub const Vec32u8 = @Vector(32, u8);
pub const Vec32i8 = @Vector(32, i8);
pub const Vec8f = @Vector(8, f32);
pub const Vec4u64 = @Vector(4, u64);

/// 64-Byte Cache-Aligned Q8_0 SIMD Block (32 quantized weights)
pub const BlockQ8_0 = extern struct {
    scale: f32,
    reserved: [28]u8 = [_]u8{0} ** 28,
    qs: [32]i8,
};

comptime {
    std.debug.assert(@sizeOf(BlockQ8_0) == 64);
}

// =================================================================================================
// EVM Execution Status
// =================================================================================================
pub const ExecutionStatus = enum {
    SUCCESS,
    REVERTED,
    STACK_UNDERFLOW,
    STACK_OVERFLOW,
    INVALID_JUMP,
    INVALID_OPCODE,
    OUT_OF_BOUNDS,
    STATIC_MODE_VIOLATION,
};

// =================================================================================================
// EVM Standard & Cancun Opcodes
// =================================================================================================
pub const Opcode = enum(u8) {
    STOP = 0x00,
    ADD = 0x01,
    MUL = 0x02,
    SUB = 0x03,
    DIV = 0x04,
    SDIV = 0x05,
    MOD = 0x06,
    SMOD = 0x07,
    ADDMOD = 0x08,
    MULMOD = 0x09,
    EXP = 0x0A,
    SIGNEXTEND = 0x0B,

    LT = 0x10,
    GT = 0x11,
    SLT = 0x12,
    SGT = 0x13,
    EQ = 0x14,
    ISZERO = 0x15,
    AND = 0x16,
    OR = 0x17,
    XOR = 0x18,
    NOT = 0x19,
    BYTE = 0x1A,
    SHL = 0x1B,
    SHR = 0x1C,
    SAR = 0x1D,

    KECCAK256 = 0x20,

    ADDRESS = 0x30,
    BALANCE = 0x31,
    ORIGIN = 0x32,
    CALLER = 0x33,
    CALLVALUE = 0x34,
    CALLDATALOAD = 0x35,
    CALLDATASIZE = 0x36,
    CALLDATACOPY = 0x37,
    CODESIZE = 0x38,
    CODECOPY = 0x39,
    GASPRICE = 0x3A,
    EXTCODESIZE = 0x3B,
    EXTCODECOPY = 0x3C,
    RETURNDATASIZE = 0x3D,
    RETURNDATACOPY = 0x3E,
    EXTCODEHASH = 0x3F,

    BLOCKHASH = 0x40,
    COINBASE = 0x41,
    TIMESTAMP = 0x42,
    NUMBER = 0x43,
    PREVRANDAO = 0x44,
    GASLIMIT = 0x45,
    CHAINID = 0x46,
    SELFBALANCE = 0x47,
    BASEFEE = 0x48,
    BLOBHASH = 0x49,
    BLOBBASEFEE = 0x4A,

    POP = 0x50,
    MLOAD = 0x51,
    MSTORE = 0x52,
    MSTORE8 = 0x53,
    SLOAD = 0x54,
    SSTORE = 0x55,
    JUMP = 0x56,
    JUMPI = 0x57,
    PC = 0x58,
    MSIZE = 0x59,
    GAS = 0x5A,
    JUMPDEST = 0x5B,
    TLOAD = 0x5C,
    TSTORE = 0x5D,
    MCOPY = 0x5E,
    PUSH0 = 0x5F,

    PUSH1 = 0x60,
    PUSH2 = 0x61,
    PUSH3 = 0x62,
    PUSH4 = 0x63,
    PUSH5 = 0x64,
    PUSH6 = 0x65,
    PUSH7 = 0x66,
    PUSH8 = 0x67,
    PUSH9 = 0x68,
    PUSH10 = 0x69,
    PUSH11 = 0x6A,
    PUSH12 = 0x6B,
    PUSH13 = 0x6C,
    PUSH14 = 0x6D,
    PUSH15 = 0x6E,
    PUSH16 = 0x6F,
    PUSH17 = 0x70,
    PUSH18 = 0x71,
    PUSH19 = 0x72,
    PUSH20 = 0x73,
    PUSH21 = 0x74,
    PUSH22 = 0x75,
    PUSH23 = 0x76,
    PUSH24 = 0x77,
    PUSH25 = 0x78,
    PUSH26 = 0x79,
    PUSH27 = 0x7A,
    PUSH28 = 0x7B,
    PUSH29 = 0x7C,
    PUSH30 = 0x7D,
    PUSH31 = 0x7E,
    PUSH32 = 0x7F,

    DUP1 = 0x80,
    DUP2 = 0x81,
    DUP3 = 0x82,
    DUP4 = 0x83,
    DUP5 = 0x84,
    DUP6 = 0x85,
    DUP7 = 0x86,
    DUP8 = 0x87,
    DUP9 = 0x88,
    DUP10 = 0x89,
    DUP11 = 0x8A,
    DUP12 = 0x8B,
    DUP13 = 0x8C,
    DUP14 = 0x8D,
    DUP15 = 0x8E,
    DUP16 = 0x8F,

    SWAP1 = 0x90,
    SWAP2 = 0x91,
    SWAP3 = 0x92,
    SWAP4 = 0x93,
    SWAP5 = 0x94,
    SWAP6 = 0x95,
    SWAP7 = 0x96,
    SWAP8 = 0x97,
    SWAP9 = 0x98,
    SWAP10 = 0x99,
    SWAP11 = 0x9A,
    SWAP12 = 0x9B,
    SWAP13 = 0x9C,
    SWAP14 = 0x9D,
    SWAP15 = 0x9E,
    SWAP16 = 0x9F,

    LOG0 = 0xA0,
    LOG1 = 0xA1,
    LOG2 = 0xA2,
    LOG3 = 0xA3,
    LOG4 = 0xA4,

    CREATE = 0xF0,
    CALL = 0xF1,
    CALLCODE = 0xF2,
    RETURN = 0xF3,
    DELEGATECALL = 0xF4,
    CREATE2 = 0xF5,
    STATICCALL = 0xFA,
    REVERT = 0xFD,
    INVALID = 0xFE,
    SELFDESTRUCT = 0xFF,
    _,
};

// =================================================================================================
// 256-Bit Hardware SIMD Integer Representation (AVX2 4x64-bit Limbs)
// =================================================================================================
pub const U256 = extern struct {
    limbs: [4]u64 align(32),

    pub const ZERO = U256{ .limbs = .{ 0, 0, 0, 0 } };
    pub const ONE = U256{ .limbs = .{ 1, 0, 0, 0 } };
    pub const MAX = U256{ .limbs = .{ ~@as(u64, 0), ~@as(u64, 0), ~@as(u64, 0), ~@as(u64, 0) } };

    pub inline fn fromU64(v: u64) U256 {
        return .{ .limbs = .{ v, 0, 0, 0 } };
    }

    pub inline fn fromNative(val: u256) U256 {
        return .{
            .limbs = .{
                @truncate(val),
                @truncate(val >> 64),
                @truncate(val >> 128),
                @truncate(val >> 192),
            },
        };
    }

    pub inline fn toNative(self: U256) u256 {
        return @as(u256, self.limbs[0]) |
            (@as(u256, self.limbs[1]) << 64) |
            (@as(u256, self.limbs[2]) << 128) |
            (@as(u256, self.limbs[3]) << 192);
    }

    pub inline fn toVector(self: U256) Vec4u64 {
        return @as(Vec4u64, self.limbs);
    }

    pub inline fn fromVector(v: Vec4u64) U256 {
        return .{ .limbs = @as([4]u64, v) };
    }

    pub inline fn add(a: U256, b: U256) struct { res: U256, carry: u8 } {
        var res: U256 = undefined;
        const c0 = @addWithOverflow(a.limbs[0], b.limbs[0]);
        res.limbs[0] = c0[0];
        const c1_init = @addWithOverflow(a.limbs[1], c0[1]);
        const c1 = @addWithOverflow(c1_init[0], b.limbs[1]);
        res.limbs[1] = c1[0];
        const c1_carry = c1_init[1] | c1[1];

        const c2_init = @addWithOverflow(a.limbs[2], c1_carry);
        const c2 = @addWithOverflow(c2_init[0], b.limbs[2]);
        res.limbs[2] = c2[0];
        const c2_carry = c2_init[1] | c2[1];

        const c3_init = @addWithOverflow(a.limbs[3], c2_carry);
        const c3 = @addWithOverflow(c3_init[0], b.limbs[3]);
        res.limbs[3] = c3[0];
        const c3_carry = c3_init[1] | c3[1];

        return .{ .res = res, .carry = c3_carry };
    }

    pub inline fn eq(a: U256, b: U256) bool {
        const va: Vec4u64 = a.toVector();
        const vb: Vec4u64 = b.toVector();
        const cmp = va == vb;
        return @reduce(.And, cmp);
    }

    pub inline fn lt(a: U256, b: U256) bool {
        var i: usize = 4;
        while (i > 0) {
            i -= 1;
            if (a.limbs[i] < b.limbs[i]) return true;
            if (a.limbs[i] > b.limbs[i]) return false;
        }
        return false;
    }
};

comptime {
    std.debug.assert(@sizeOf(U256) == 32);
    std.debug.assert(@alignOf(U256) == 32);
}
