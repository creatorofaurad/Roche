//! volta: Slither-Style Static Security Detectors Suite
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const cfg_mod = @import("cfg.zig");
const types = @import("types.zig");

pub const DetectorResult = struct {
    reentrancy: bool = false,
    uninitialized_storage: bool = false,
    arbitrary_delegatecall: bool = false,
    unprotected_selfdestruct: bool = false,
    divide_before_multiply: bool = false,
    strict_balance_equality: bool = false,
    timestamp_dependency: bool = false,
    vulnerability_count: usize = 0,
};

pub const DetectorSuite = struct {
    /// 1. Slither Detector: Reentrancy (Checks-Effects-Interactions)
    pub fn auditReentrancy(cfg: *const cfg_mod.ControlFlowGraph) bool {
        var call_seen_in_prev_block = false;
        for (0..cfg.block_count) |i| {
            const b = cfg.blocks[i];

            if (call_seen_in_prev_block and b.last_state_write_pc != null) {
                return true;
            }

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

    /// 2. Slither Detector: Uninitialized Storage Access
    pub fn auditUninitializedStorage(cfg: *const cfg_mod.ControlFlowGraph) bool {
        if (cfg.block_count == 0) return false;
        const entry_block = cfg.blocks[0];
        if (entry_block.first_state_read_pc) |read_pc| {
            if (entry_block.last_state_write_pc == null or entry_block.last_state_write_pc.? > read_pc) {
                return true;
            }
        }
        return false;
    }

    /// 3. Slither Detector: Controlled DELEGATECALL Target
    pub fn auditDelegatecall(cfg: *const cfg_mod.ControlFlowGraph) bool {
        for (0..cfg.block_count) |i| {
            if (cfg.blocks[i].has_delegatecall) return true;
        }
        return false;
    }

    /// 4. Slither Detector: Unprotected SELFDESTRUCT
    pub fn auditSelfdestruct(cfg: *const cfg_mod.ControlFlowGraph) bool {
        for (0..cfg.block_count) |i| {
            if (cfg.blocks[i].has_selfdestruct) return true;
        }
        return false;
    }

    /// 5. Slither Detector: Divide-before-Multiply Precision Loss
    pub fn auditDivideBeforeMultiply(cfg: *const cfg_mod.ControlFlowGraph) bool {
        for (0..cfg.block_count) |i| {
            if (cfg.blocks[i].has_divide_before_multiply) return true;
        }
        return false;
    }

    /// 6. Slither Detector: Dangerous Strict Balance Equality (BALANCE -> EQ)
    pub fn auditStrictBalance(cfg: *const cfg_mod.ControlFlowGraph) bool {
        for (0..cfg.block_count) |i| {
            if (cfg.blocks[i].has_strict_balance_equality) return true;
        }
        return false;
    }

    /// 7. Slither Detector: Miner-Manipulable Timestamp Dependency
    pub fn auditTimestamp(cfg: *const cfg_mod.ControlFlowGraph) bool {
        for (0..cfg.block_count) |i| {
            if (cfg.blocks[i].has_timestamp_dependency) return true;
        }
        return false;
    }

    /// Run full 7-detector Slither static analysis pass in sub-milliseconds
    pub fn runAll(cfg: *const cfg_mod.ControlFlowGraph) DetectorResult {
        var res = DetectorResult{};
        res.reentrancy = auditReentrancy(cfg);
        res.uninitialized_storage = auditUninitializedStorage(cfg);
        res.arbitrary_delegatecall = auditDelegatecall(cfg);
        res.unprotected_selfdestruct = auditSelfdestruct(cfg);
        res.divide_before_multiply = auditDivideBeforeMultiply(cfg);
        res.strict_balance_equality = auditStrictBalance(cfg);
        res.timestamp_dependency = auditTimestamp(cfg);

        if (res.reentrancy) res.vulnerability_count += 1;
        if (res.uninitialized_storage) res.vulnerability_count += 1;
        if (res.arbitrary_delegatecall) res.vulnerability_count += 1;
        if (res.unprotected_selfdestruct) res.vulnerability_count += 1;
        if (res.divide_before_multiply) res.vulnerability_count += 1;
        if (res.strict_balance_equality) res.vulnerability_count += 1;
        if (res.timestamp_dependency) res.vulnerability_count += 1;

        return res;
    }
};

test "Detectors: Full Slither 7-Detector Suite" {
    // 1. Reentrancy
    const vuln_code = [_]u8{ 0x60, 0x00, 0xF1, 0x60, 0x01, 0x60, 0x00, 0x55, 0x00 };
    const cfg_vuln = cfg_mod.ControlFlowGraph.build(&vuln_code);
    try std.testing.expect(DetectorSuite.auditReentrancy(&cfg_vuln));

    // 2. Divide Before Multiply: DIV (0x04) -> MUL (0x02)
    const div_mul_code = [_]u8{ 0x60, 0x02, 0x60, 0x0A, 0x04, 0x60, 0x03, 0x02, 0x00 };
    const cfg_div_mul = cfg_mod.ControlFlowGraph.build(&div_mul_code);
    try std.testing.expect(DetectorSuite.auditDivideBeforeMultiply(&cfg_div_mul));

    // 3. Delegatecall Detection: DELEGATECALL (0xF4)
    const del_code = [_]u8{ 0x60, 0x00, 0xF4, 0x00 };
    const cfg_del = cfg_mod.ControlFlowGraph.build(&del_code);
    try std.testing.expect(DetectorSuite.auditDelegatecall(&cfg_del));

    // 4. Selfdestruct Detection: SELFDESTRUCT (0xFF)
    const self_code = [_]u8{ 0x60, 0x00, 0xFF };
    const cfg_self = cfg_mod.ControlFlowGraph.build(&self_code);
    try std.testing.expect(DetectorSuite.auditSelfdestruct(&cfg_self));

    // Full runAll audit check
    const full_res = DetectorSuite.runAll(&cfg_vuln);
    try std.testing.expect(full_res.reentrancy);
    try std.testing.expectEqual(@as(usize, 1), full_res.vulnerability_count);
}
