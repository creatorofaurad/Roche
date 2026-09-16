//! volta: Slither-Style Static Security Detectors Suite
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const cfg_mod = @import("cfg.zig");
const types = @import("types.zig");

pub const DetectorResult = struct {
    reentrancy: bool = false,
    uninitialized_storage_read: bool = false,
    arbitrary_delegatecall: bool = false,
    vulnerability_count: usize = 0,
};

pub const DetectorSuite = struct {
    /// Detect Checks-Effects-Interactions Reentrancy Violations
    pub fn auditReentrancy(cfg: *const cfg_mod.ControlFlowGraph) bool {
        var call_seen_in_prev_block = false;
        for (0..cfg.block_count) |i| {
            const b = cfg.blocks[i];

            // 1. Inter-block check
            if (call_seen_in_prev_block and b.last_state_write_pc != null) {
                return true;
            }

            // 2. Intra-block check
            if (b.first_external_call_pc) |call_pc| {
                if (b.last_state_write_pc) |write_pc| {
                    if (write_pc > call_pc) {
                        return true;
                    }
                }
                call_seen_in_prev_block = true;
            }
        }
        return false;
    }

    /// Detect Potential Uninitialized Storage Reads (SLOAD before SSTORE across entry)
    pub fn auditUninitializedStorage(cfg: *const cfg_mod.ControlFlowGraph) bool {
        if (cfg.block_count == 0) return false;
        const entry_block = cfg.blocks[0];
        if (entry_block.first_state_read_pc) |read_pc| {
            if (entry_block.last_state_write_pc == null or entry_block.last_state_write_pc.? > read_pc) {
                return true; // SLOAD executed before any SSTORE in entry block
            }
        }
        return false;
    }

    /// Run all static detectors across the CFG
    pub fn runAll(cfg: *const cfg_mod.ControlFlowGraph) DetectorResult {
        var res = DetectorResult{};
        res.reentrancy = auditReentrancy(cfg);
        res.uninitialized_storage_read = auditUninitializedStorage(cfg);

        if (res.reentrancy) res.vulnerability_count += 1;
        if (res.uninitialized_storage_read) res.vulnerability_count += 1;

        return res;
    }
};

test "Detectors: Reentrancy Detector" {
    // Vulnerable: CALL followed by SSTORE
    const vuln_code = [_]u8{ 0x60, 0x00, 0xF1, 0x60, 0x01, 0x60, 0x00, 0x55, 0x00 };
    const cfg_vuln = cfg_mod.ControlFlowGraph.build(&vuln_code);
    try std.testing.expect(DetectorSuite.auditReentrancy(&cfg_vuln));

    // Safe: SSTORE followed by CALL
    const safe_code = [_]u8{ 0x60, 0x01, 0x60, 0x00, 0x55, 0x60, 0x00, 0xF1, 0x00 };
    const cfg_safe = cfg_mod.ControlFlowGraph.build(&safe_code);
    try std.testing.expect(!DetectorSuite.auditReentrancy(&cfg_safe));
}
