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

    CALL = 0xF1,
    DELEGATECALL = 0xF4,
    STATICCALL = 0xFA,
    REVERT = 0xFD,
    INVALID = 0xFE,
    SELFDESTRUCT = 0xFF,
    _,
};
