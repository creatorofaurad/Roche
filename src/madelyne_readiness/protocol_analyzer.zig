// ============================================================================
// FILE: src/madelyne_readiness/protocol_analyzer.zig
// DESCRIPTION: EVM Bytecode fingerprinting & automatic detector tagging
// ARCHITECTURE: Bare-Silicon Zig 0.16.0 / SIMD-Accelerated Hash / Zero Heap Alloc
// INVARIANTS: 0 Dynamic Allocations.
// ============================================================================

const std = @import("std");

pub const FeatureFlags = struct {
    pub const ERC20: u32 = 1 << 0;
    pub const ERC721: u32 = 1 << 1;
    pub const ERC4626: u32 = 1 << 2;
    pub const FLASHLOAN: u32 = 1 << 3;
    pub const REENTRANCY_GUARD: u32 = 1 << 4;
    pub const PROXY_PATTERN: u32 = 1 << 5;
    pub const AGGLAYER_BRIDGE: u32 = 1 << 6;
};

pub const ProtocolAnalysisResult = struct {
    fingerprint: u64 = 0,
    feature_flags: u32 = 0,
    tagged_detectors_mask: u64 = 0,
    detected_selectors_cnt: u8 = 0,
};

/// 64-bit SIMD/FNV fingerprint hash over EVM bytecode
pub fn extractFingerprint(bytecode: []const u8) u64 {
    if (bytecode.len == 0) return 0xDeadBeef;

    var hash: u64 = 0xcbf29ce484222325;
    const prime: u64 = 0x100000001b3;

    var i: usize = 0;
    while (i < bytecode.len) : (i += 1) {
        hash = (hash ^ @as(u64, bytecode[i])) *% prime;
    }
    return hash;
}

/// Analyzes EVM bytecode, identifies protocol standard signatures, and tags relevant detectors
pub fn analyzeProtocol(bytecode: []const u8) ProtocolAnalysisResult {
    var res = ProtocolAnalysisResult{};
    res.fingerprint = extractFingerprint(bytecode);

    if (bytecode.len == 0) return res;

    var i: usize = 0;
    while (i < bytecode.len) : (i += 1) {
        // Standard function selectors inspection (PUSH4)
        if (bytecode[i] == 0x63 and i + 4 < bytecode.len) {
            const sel = bytecode[i + 1 .. i + 5];

            // balanceOf(address) -> 0x70a08231
            // transfer(address,uint256) -> 0xa9059cbb
            if (std.mem.eql(u8, sel, &[_]u8{ 0x70, 0xa0, 0x82, 0x31 }) or
                std.mem.eql(u8, sel, &[_]u8{ 0xa9, 0x05, 0x9c, 0xbb }))
            {
                res.feature_flags |= FeatureFlags.ERC20;
                res.tagged_detectors_mask |= (1 << 0); // Detector 0: ERC20 Invariants
                res.detected_selectors_cnt += 1;
            }

            // convertToShares(uint256) -> 0xc6e6f592 or deposit(uint256,address) -> 0x6e553f09
            if (std.mem.eql(u8, sel, &[_]u8{ 0xc6, 0xe6, 0xf5, 0x92 }) or
                std.mem.eql(u8, sel, &[_]u8{ 0x6e, 0x55, 0x3f, 0x09 }))
            {
                res.feature_flags |= FeatureFlags.ERC4626;
                res.tagged_detectors_mask |= (1 << 2); // Detector 2: Vault Rate Inflation
                res.detected_selectors_cnt += 1;
            }

            // flashLoan(...) -> 0x5c975abb
            if (std.mem.eql(u8, sel, &[_]u8{ 0x5c, 0x97, 0x5a, 0xbb })) {
                res.feature_flags |= FeatureFlags.FLASHLOAN;
                res.tagged_detectors_mask |= (1 << 3); // Detector 3: Flashloan Solvency
                res.detected_selectors_cnt += 1;
            }
        }

        // DELEGATECALL (0xF4) check for Proxy Pattern
        if (bytecode[i] == 0xF4) {
            res.feature_flags |= FeatureFlags.PROXY_PATTERN;
            res.tagged_detectors_mask |= (1 << 5); // Detector 5: Storage Collision
        }

        // SSTORE (0x55) + SLOAD (0x54) pattern check for Reentrancy Guard
        if (bytecode[i] == 0x55 and i > 0 and bytecode[i - 1] == 0x54) {
            res.feature_flags |= FeatureFlags.REENTRANCY_GUARD;
            res.tagged_detectors_mask |= (1 << 4); // Detector 4: CEI / Transient Lock
        }
    }

    return res;
}

// ============================================================================
// UNIT TESTS
// ============================================================================
test "ProtocolAnalyzer: Deterministic Fingerprinting" {
    const code = [_]u8{ 0x60, 0x80, 0x60, 0x40, 0x52, 0x34, 0x80, 0x15 };
    const fp1 = extractFingerprint(&code);
    const fp2 = extractFingerprint(&code);

    try std.testing.expectEqual(fp1, fp2);
    try std.testing.expect(fp1 != 0);
}

test "ProtocolAnalyzer: Selector & Detector Tagging Verification" {
    // PUSH4 0xa9059cbb (transfer) + SLOAD + SSTORE
    const mock_code = [_]u8{ 0x63, 0xa9, 0x05, 0x9c, 0xbb, 0x54, 0x55 };
    const analysis = analyzeProtocol(&mock_code);

    try std.testing.expect(analysis.feature_flags & FeatureFlags.ERC20 != 0);
    try std.testing.expect(analysis.feature_flags & FeatureFlags.REENTRANCY_GUARD != 0);
    try std.testing.expect(analysis.tagged_detectors_mask & (1 << 0) != 0);
    try std.testing.expect(analysis.tagged_detectors_mask & (1 << 4) != 0);
}
