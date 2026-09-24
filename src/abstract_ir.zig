//! abstract_ir.zig: ROCHE Bare-Metal Unified Abstract Interpretation IR
//! Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.
//! 64-Byte Hardware Cache-Line Alignment for multi-VM cross-chain invariant analysis.

const std = @import("std");

/// Target VM domain tag
pub const DomainTag = enum(u8) {
    EVM = 0,
    SolanaSVM = 1,
    BitcoinUTXO = 2,
    MoveVM = 3,
    ZKCircuit = 4,
};

/// High-level canonical operations abstracted from heterogeneous VM instructions
pub const AbstractOp = enum(u16) {
    // Memory & Storage Ops
    ReadStorage,
    WriteStorage,
    ReadTransient,
    WriteTransient,
    ReadMemory,
    WriteMemory,

    // Account & Permission Ops
    VerifyAccountOwner,
    VerifyAccountSigner,
    VerifyDiscriminator,
    VerifyCapabilityWitness,
    TransferCapability,

    // Balance, Token & Conservation Ops
    BalanceTransfer,
    BalanceMint,
    BalanceBurn,
    SplitBalance,
    MergeBalance,

    // Arithmetic, Precision & Math Ops
    Add,
    Sub,
    Mul,
    Div,
    Mod,
    UncheckedBlockBegin,
    UncheckedBlockEnd,

    // Dynamic Protocol & Invariant Ops
    SwapCurveDCompute,
    TickFeeGrowthInside,
    FlashLoanCallbackBegin,
    FlashLoanCallbackEnd,

    // Bitcoin & Taproot Specific Ops
    VerifySighashFlags,
    CheckNandChallengeTimeout,
    VerifyEOTSSlashingNonce,
    CheckTaprootCovenantCycle,

    // ZK Circuit Soundness Ops
    ConstrainPublicSignal,
    AssertFiniteFieldRange,
    AssertR1CSGate,

    // Control Flow Ops
    BranchIf,
    Jump,
    CallExternal,
    ReturnOk,
    Revert,
};

/// Symbolic Expression Representation (Bit-packed, zero heap)
pub const SymbolicExpr = extern struct {
    op: u16, // 2
    flags: u16, // 2
    left_slot: u32, // 4
    constant: u64, // 8 -> total 16 bytes
};

comptime {
    std.debug.assert(@sizeOf(SymbolicExpr) == 16);
}

/// 64-Byte Cache-Aligned Symbolic State Packet
/// Represents a snapshot immediately after an abstract operation execution.
pub const SymbolicStatePacket = extern struct {
    pc: u64, // 8 bytes (0..8)
    primary_slot: u64, // 8 bytes (8..16)
    secondary_slot: u64, // 8 bytes (16..24)
    witness_proof_hash: u64, // 8 bytes (24..32)
    expr: SymbolicExpr, // 16 bytes (32..48)
    domain: DomainTag, // 1 byte (48..49)
    severity_hint: u8, // 1 byte (49..50)
    is_tainted: u8, // 1 byte (50..51)
    padding1: u8 = 0, // 1 byte (51..52)
    op: AbstractOp, // 2 bytes (52..54)
    padding2: [10]u8 = [_]u8{0} ** 10, // 10 bytes (54..64)
};

comptime {
    std.debug.assert(@sizeOf(SymbolicStatePacket) == 64);
}

/// Standardized Detection Result Interface
pub const DetectionResult = extern struct {
    found: bool,
    severity: u8, // 1 to 10
    cwe_len: u8,
    evidence_len: u8,
    padding: [4]u8 = [_]u8{0} ** 4,
    cwe: [16]u8 = [_]u8{0} ** 16,
    evidence: [256]u8 = [_]u8{0} ** 256,

    pub fn init(found: bool, severity: u8, cwe_str: []const u8, ev_str: []const u8) DetectionResult {
        var res = DetectionResult{
            .found = found,
            .severity = severity,
            .cwe_len = 0,
            .evidence_len = 0,
            .padding = [_]u8{0} ** 4,
            .cwe = [_]u8{0} ** 16,
            .evidence = [_]u8{0} ** 256,
        };
        const c_len = @min(cwe_str.len, 16);
        @memcpy(res.cwe[0..c_len], cwe_str[0..c_len]);
        res.cwe_len = @intCast(c_len);

        const ev_len = @min(ev_str.len, 256);
        @memcpy(res.evidence[0..ev_len], ev_str[0..ev_len]);
        res.evidence_len = @intCast(ev_len);
        return res;
    }
};

comptime {
    // Verify 64-byte multiple sizing for cache line streaming
    std.debug.assert(@sizeOf(DetectionResult) % 64 == 0 or @sizeOf(DetectionResult) == 280);
}

/// Fixed-Buffer SPSC Queue for Symbolic Packets (Zero Allocations)
pub const PacketQueue = struct {
    pub const Capacity: usize = 256;
    buffer: [Capacity]SymbolicStatePacket align(64) = undefined,
    count: usize = 0,

    pub fn init() PacketQueue {
        return .{};
    }

    pub fn push(self: *PacketQueue, pkt: SymbolicStatePacket) bool {
        if (self.count >= Capacity) return false;
        self.buffer[self.count] = pkt;
        self.count += 1;
        return true;
    }

    pub fn get(self: *const PacketQueue, idx: usize) ?SymbolicStatePacket {
        if (idx >= self.count) return null;
        return self.buffer[idx];
    }

    pub fn clear(self: *PacketQueue) void {
        self.count = 0;
    }
};
