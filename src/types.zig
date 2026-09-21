//! roche: Core Primitives & EVM Type Definitions
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");

pub const VERSION = "1.0.0-beta";

// =================================================================================================
// Hardware & Memory Constants
// =================================================================================================
pub const MAX_STACK_DEPTH: usize = 1024;
pub const MAX_MEMORY_BYTES: usize = 131072; // 128 KB aligned static buffer for deep multicall / nested ABI frames
pub const MAX_CALLDATA_BYTES: usize = 131072; // 128 KB calldata capacity
pub const MAX_BYTECODE_SIZE: usize = 24576; // EIP-170 max code size (24 KB)
pub const MAX_TRANSIENT_STORAGE_KEYS: usize = 1024;
pub const MAX_STORAGE_SLOTS: usize = 256;
pub const MAX_ROLLBACK_LOGS: usize = 128;
pub const MAX_BASIC_BLOCKS: usize = 256;
pub const MAX_DICTIONARY_CONSTS: usize = 128;
pub const COVERAGE_BITMAP_SIZE: usize = 65536; // 64KB AFL Shared Memory Table
pub const MAX_ACCOUNTS: usize = 16;
pub const MAX_RETURNDATA_BYTES: usize = 1024;
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

    pub inline fn sub(a: U256, b: U256) U256 {
        var res: U256 = undefined;
        var borrow: u64 = 0;
        for (0..4) |idx| {
            const diff1 = @subWithOverflow(a.limbs[idx], b.limbs[idx]);
            const diff2 = @subWithOverflow(diff1[0], borrow);
            res.limbs[idx] = diff2[0];
            borrow = @as(u64, diff1[1]) | @as(u64, diff2[1]);
        }
        return res;
    }

    pub inline fn xorVec(a: U256, b: U256) Vec4u64 {
        return a.toVector() ^ b.toVector();
    }
};

comptime {
    std.debug.assert(@sizeOf(U256) == 32);
    std.debug.assert(@alignOf(U256) == 32);
}

// =================================================================================================
// Kernel Invariant & State Delta Types (Zero Dynamic Heap Allocations)
// =================================================================================================
pub const MAX_STATE_DELTAS: usize = 4096;
pub const MAX_TRANSIENT_DELTAS: usize = 1024;
pub const MAX_CHECKPOINTS: usize = 512;
pub const MAX_UNDO_ENTRIES: usize = 8192;
pub const MAX_DETECTOR_FINDINGS: usize = 512;
pub const MAX_CALL_DEPTH: usize = 1024;

pub const StorageKey = struct {
    address: [20]u8 = [_]u8{0} ** 20,
    slot: [32]u8 = [_]u8{0} ** 32,

    pub inline fn eq(self: StorageKey, other: StorageKey) bool {
        return std.mem.eql(u8, &self.address, &other.address) and std.mem.eql(u8, &self.slot, &other.slot);
    }
};

pub const DELTA_PERSISTENT: u16 = 1 << 0;
pub const DELTA_TRANSIENT: u16  = 1 << 1;
pub const DELTA_REVERTED: u16   = 1 << 2;
pub const DELTA_SSTORE: u16     = 1 << 3;
pub const DELTA_TSTORE: u16     = 1 << 4;
pub const DELTA_DIRTY: u16      = 1 << 5;

pub const StorageDeltaEntry = struct {
    key: StorageKey = .{},
    pre: [32]u8 = [_]u8{0} ** 32,
    post: [32]u8 = [_]u8{0} ** 32,
    frame_id: u32 = 0,
    checkpoint_id: u32 = 0,
    flags: u16 = 0,
};

pub const Checkpoint = struct {
    checkpoint_id: u32 = 0,
    delta_idx: usize = 0,
    transient_idx: usize = 0,
    undo_idx: usize = 0,
};

pub const UndoEntry = struct {
    key: StorageKey = .{},
    val: [32]u8 = [_]u8{0} ** 32,
    is_transient: bool = false,
};

pub const StateDeltaJournal = struct {
    entries: [MAX_STATE_DELTAS]StorageDeltaEntry = [_]StorageDeltaEntry{.{}} ** MAX_STATE_DELTAS,
    len: usize = 0,

    checkpoints: [MAX_CHECKPOINTS]Checkpoint = [_]Checkpoint{.{}} ** MAX_CHECKPOINTS,
    checkpoint_len: usize = 0,

    undo_log: [MAX_UNDO_ENTRIES]UndoEntry = [_]UndoEntry{.{}} ** MAX_UNDO_ENTRIES,
    undo_len: usize = 0,

    pub fn init() StateDeltaJournal {
        return .{};
    }

    pub fn reset(self: *StateDeltaJournal) void {
        self.len = 0;
        self.checkpoint_len = 0;
        self.undo_len = 0;
    }

    pub fn beginCheckpoint(self: *StateDeltaJournal) u32 {
        const cp_id: u32 = @truncate(self.checkpoint_len);
        if (self.checkpoint_len < MAX_CHECKPOINTS) {
            self.checkpoints[self.checkpoint_len] = .{
                .checkpoint_id = cp_id,
                .delta_idx = self.len,
                .transient_idx = 0,
                .undo_idx = self.undo_len,
            };
            self.checkpoint_len += 1;
        }
        return cp_id;
    }

    pub fn commitCheckpoint(self: *StateDeltaJournal, cp_id: u32) void {
        if (self.checkpoint_len > 0 and self.checkpoints[self.checkpoint_len - 1].checkpoint_id == cp_id) {
            self.checkpoint_len -= 1;
        }
    }

    pub fn revertToCheckpoint(self: *StateDeltaJournal, cp_id: u32) void {
        var target_cp: ?Checkpoint = null;
        while (self.checkpoint_len > 0) {
            self.checkpoint_len -= 1;
            const cp = self.checkpoints[self.checkpoint_len];
            if (cp.checkpoint_id == cp_id) {
                target_cp = cp;
                break;
            }
        }
        if (target_cp) |cp| {
            // Mark rolled back deltas as reverted
            var idx = cp.delta_idx;
            while (idx < self.len) : (idx += 1) {
                self.entries[idx].flags |= DELTA_REVERTED;
            }
            self.len = cp.delta_idx;
            self.undo_len = cp.undo_idx;
        }
    }

    pub fn recordSSTORE(self: *StateDeltaJournal, address: [20]u8, slot: [32]u8, pre: [32]u8, post: [32]u8, frame_id: u32) void {
        if (self.len < MAX_STATE_DELTAS) {
            self.entries[self.len] = .{
                .key = .{ .address = address, .slot = slot },
                .pre = pre,
                .post = post,
                .frame_id = frame_id,
                .checkpoint_id = if (self.checkpoint_len > 0) self.checkpoints[self.checkpoint_len - 1].checkpoint_id else 0,
                .flags = DELTA_PERSISTENT | DELTA_SSTORE | DELTA_DIRTY,
            };
            self.len += 1;
        }
    }

    pub fn getPreState(self: *const StateDeltaJournal, address: [20]u8, slot: [32]u8) ?[32]u8 {
        const key = StorageKey{ .address = address, .slot = slot };
        for (0..self.len) |i| {
            if (self.entries[i].key.eq(key) and (self.entries[i].flags & DELTA_REVERTED == 0)) {
                return self.entries[i].pre;
            }
        }
        return null;
    }

    pub fn getPostState(self: *const StateDeltaJournal, address: [20]u8, slot: [32]u8) ?[32]u8 {
        const key = StorageKey{ .address = address, .slot = slot };
        var i: usize = self.len;
        while (i > 0) {
            i -= 1;
            if (self.entries[i].key.eq(key) and (self.entries[i].flags & DELTA_REVERTED == 0)) {
                return self.entries[i].post;
            }
        }
        return null;
    }
};

pub const TransientDeltaEntry = struct {
    key: StorageKey = .{},
    old_val: [32]u8 = [_]u8{0} ** 32,
    new_val: [32]u8 = [_]u8{0} ** 32,
    frame_id: u32 = 0,
    checkpoint_id: u32 = 0,
    reverted: bool = false,
};

pub const TransientStorageJournal = struct {
    entries: [MAX_TRANSIENT_DELTAS]TransientDeltaEntry = [_]TransientDeltaEntry{.{}} ** MAX_TRANSIENT_DELTAS,
    len: usize = 0,
    total_recorded: usize = 0,
    checkpoint_len: usize = 0,
    checkpoints: [MAX_CHECKPOINTS]usize = [_]usize{0} ** MAX_CHECKPOINTS,

    pub fn init() TransientStorageJournal {
        return .{};
    }

    pub fn recordTSTORE(self: *TransientStorageJournal, address: [20]u8, slot: [32]u8, old_v: [32]u8, new_v: [32]u8, frame_id: u32) void {
        if (self.len < MAX_TRANSIENT_DELTAS) {
            self.entries[self.len] = .{
                .key = .{ .address = address, .slot = slot },
                .old_val = old_v,
                .new_val = new_v,
                .frame_id = frame_id,
                .checkpoint_id = @truncate(self.checkpoint_len),
                .reverted = false,
            };
            self.len += 1;
            if (self.len > self.total_recorded) self.total_recorded = self.len;
        }
    }

    pub fn checkpoint(self: *TransientStorageJournal) usize {
        const cp = self.len;
        if (self.checkpoint_len < MAX_CHECKPOINTS) {
            self.checkpoints[self.checkpoint_len] = cp;
            self.checkpoint_len += 1;
        }
        return cp;
    }

    pub fn rollback(self: *TransientStorageJournal, cp: usize) void {
        var idx = cp;
        while (idx < self.len) : (idx += 1) {
            self.entries[idx].reverted = true;
        }
        self.len = cp;
        if (self.checkpoint_len > 0) {
            self.checkpoint_len -= 1;
        }
    }

    pub fn clearTransactionTransient(self: *TransientStorageJournal) void {
        self.len = 0;
        self.total_recorded = 0;
        self.checkpoint_len = 0;
    }
};

// =================================================================================================
// Call Frame Stack & Reentrancy Mask
// =================================================================================================
pub const CallKind = enum(u8) {
    call,
    callcode,
    delegatecall,
    staticcall,
    create,
    create2,
};

pub const FRAME_HAS_VALUE: u32         = 1 << 0;
pub const FRAME_IS_HOOK: u32           = 1 << 1;
pub const FRAME_IS_CALLBACK: u32       = 1 << 2;
pub const FRAME_IS_STATIC: u32         = 1 << 3;
pub const FRAME_IN_AFTER_SWAP: u32     = 1 << 4;
pub const FRAME_IN_BEFORE_SWAP: u32    = 1 << 5;
pub const FRAME_IN_TOKEN_RECEIVER: u32 = 1 << 6;
pub const FRAME_REENTRANCY_ARMED: u32  = 1 << 7;

pub const CallFrame = struct {
    frame_id: u32 = 0,
    parent_frame_id: u32 = 0,

    address: [20]u8 = [_]u8{0} ** 20,
    caller: [20]u8 = [_]u8{0} ** 20,
    origin: [20]u8 = [_]u8{0} ** 20,

    value: [32]u8 = [_]u8{0} ** 32,
    gas: u64 = 0,

    call_kind: CallKind = .call,

    storage_checkpoint: u32 = 0,
    transient_checkpoint: u32 = 0,

    selector: [4]u8 = [_]u8{0} ** 4,
    flags: u32 = 0,

    has_external_call_occurred: bool = false,
    post_call_write_occurred: bool = false,
};

pub const CallFrameStack = struct {
    frames: [MAX_CALL_DEPTH]CallFrame = [_]CallFrame{.{}} ** MAX_CALL_DEPTH,
    depth: usize = 0,

    pub fn init() CallFrameStack {
        return .{};
    }

    pub fn push(self: *CallFrameStack, frame: CallFrame) bool {
        if (self.depth < MAX_CALL_DEPTH) {
            self.frames[self.depth] = frame;
            self.depth += 1;
            return true;
        }
        return false;
    }

    pub fn pop(self: *CallFrameStack) ?CallFrame {
        if (self.depth > 0) {
            self.depth -= 1;
            return self.frames[self.depth];
        }
        return null;
    }

    pub fn current(self: *CallFrameStack) ?*CallFrame {
        if (self.depth > 0) {
            return &self.frames[self.depth - 1];
        }
        return null;
    }

    pub fn currentConst(self: *const CallFrameStack) ?*const CallFrame {
        if (self.depth > 0) {
            return &self.frames[self.depth - 1];
        }
        return null;
    }
};

pub const ReentrancyMask = packed struct(u64) {
    external_call: bool = false,
    value_call: bool = false,
    delegatecall: bool = false,
    staticcall: bool = false,
    token_transfer: bool = false,
    hook_call: bool = false,
    callback_call: bool = false,
    persistent_write: bool = false,
    transient_write: bool = false,
    log_emit: bool = false,
    create_op: bool = false,
    selfdestruct_op: bool = false,
    _reserved: u52 = 0,
};

pub const OpMask = struct {
    pub const SLOAD: u64        = 1 << 0;
    pub const SSTORE: u64       = 1 << 1;
    pub const TLOAD: u64        = 1 << 2;
    pub const TSTORE: u64       = 1 << 3;
    pub const CALL: u64         = 1 << 4;
    pub const CALLCODE: u64     = 1 << 5;
    pub const DELEGATECALL: u64 = 1 << 6;
    pub const STATICCALL: u64   = 1 << 7;
    pub const CREATE: u64       = 1 << 8;
    pub const CREATE2: u64      = 1 << 9;
    pub const LOG0: u64         = 1 << 10;
    pub const LOG1: u64         = 1 << 11;
    pub const LOG2: u64         = 1 << 12;
    pub const LOG3: u64         = 1 << 13;
    pub const LOG4: u64         = 1 << 14;
    pub const BALANCE: u64      = 1 << 15;
    pub const EXTCODESIZE: u64  = 1 << 16;
    pub const EXTCODECOPY: u64  = 1 << 17;
    pub const EXTCODEHASH: u64  = 1 << 18;
    pub const REVERT: u64       = 1 << 19;
    pub const SELFDESTRUCT: u64 = 1 << 20;
    pub const MSTORE: u64       = 1 << 21;
    pub const MLOAD: u64        = 1 << 22;
    pub const RETURN: u64       = 1 << 23;
};

// =================================================================================================
// SIMD Register Shadow Table & Divergence Evaluation
// =================================================================================================
pub const ShadowVec256 = @Vector(4, u64);
pub const OpcodeMaskVec = @Vector(4, u64);
pub const DivergenceScoreVec = @Vector(8, f32);

pub const ShadowRegisterFile = struct {
    actual_state: [32]U256 = [_]U256{U256.ZERO} ** 32,
    ideal_state: [32]U256 = [_]U256{U256.ZERO} ** 32,
    divergence_scores: [32]f32 = [_]f32{0.0} ** 32,
    len: usize = 0,

    pub fn init() ShadowRegisterFile {
        return .{};
    }

    pub inline fn recordSlot(self: *ShadowRegisterFile, slot_idx: usize, actual: u256, ideal: u256) void {
        if (slot_idx < 32) {
            self.actual_state[slot_idx] = U256.fromNative(actual);
            self.ideal_state[slot_idx] = U256.fromNative(ideal);
            const xor_v = self.actual_state[slot_idx].toVector() ^ self.ideal_state[slot_idx].toVector();
            const has_diff = @reduce(.Or, xor_v != @as(Vec4u64, @splat(0)));
            self.divergence_scores[slot_idx] = if (has_diff) 1.0 else 0.0;
            if (slot_idx >= self.len) self.len = slot_idx + 1;
        }
    }

    pub inline fn hasDivergence(self: *const ShadowRegisterFile) bool {
        for (0..self.len) |i| {
            if (self.divergence_scores[i] > 0.0) return true;
        }
        return false;
    }
};
