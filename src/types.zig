//! volta: Core Primitives & EVM Type Definitions
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");

pub const VERSION = "1.0.0-beta";

// =================================================================================================
// Hardware & Memory Constants
// =================================================================================================
pub const MAX_STACK_DEPTH: usize = 1024;
pub const MAX_MEMORY_BYTES: usize = 4096;
pub const MAX_STORAGE_SLOTS: usize = 512;
pub const MAX_ROLLBACK_LOGS: usize = 256;
pub const MAX_BASIC_BLOCKS: usize = 256;
pub const MAX_DICTIONARY_CONSTS: usize = 128;
pub const COVERAGE_BITMAP_SIZE: usize = 65536; // 64KB AFL Shared Memory Table
pub const MAX_ACCOUNTS: usize = 32;

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
};

// =================================================================================================
// EVM Standard Opcodes
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

    BLOCKHASH = 0x40,
    COINBASE = 0x41,
    TIMESTAMP = 0x42,
    NUMBER = 0x43,
    PREVRANDAO = 0x44,
    GASLIMIT = 0x45,
    CHAINID = 0x46,
    SELFBALANCE = 0x47,

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

    CALL = 0xF1,
    DELEGATECALL = 0xF4,
    STATICCALL = 0xFA,
    REVERT = 0xFD,
    INVALID = 0xFE,
    SELFDESTRUCT = 0xFF,
    _,
};
