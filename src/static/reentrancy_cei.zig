// ============================================================================
// VOLTA SILICON KERNEL: Port of Aderyn Reentrancy State Change Detector
// Invariant: Zero Heap Allocation | 64-Byte Cache Aligned | Zig 0.16.0
// ============================================================================

const std = @import("std");
const cfg_mod = @import("cfg_dominator.zig");

pub const ReentrancyViolation = struct {
    call_node_id: u32,
    call_pc: u32,
    sstore_node_id: u32,
    sstore_pc: u32,
    slot_mask: u256,
};

pub const CEIScanner = struct {
    violations: [64]ReentrancyViolation align(64),
    violation_count: usize = 0,

    pub fn init() CEIScanner {
        return CEIScanner{
            .violations = undefined,
            .violation_count = 0,
        };
    }

    pub fn scan(self: *CEIScanner, cfg: *const cfg_mod.CFGDominatorEngine) []const ReentrancyViolation {
        self.violation_count = 0;
        var i: u32 = 0;
        while (i < cfg.node_count) : (i += 1) {
            const node_a = &cfg.nodes[i];
            if (!node_a.flags.has_external_call and !node_a.flags.has_delegatecall) continue;

            var j: u32 = 0;
            while (j < cfg.node_count) : (j += 1) {
                if (i == j) continue;
                const node_b = &cfg.nodes[j];
                if (!node_b.flags.has_sstore and !node_b.flags.has_tstore) continue;

                if (cfg.dominates(i, j)) {
                    if (self.violation_count < self.violations.len) {
                        self.violations[self.violation_count] = ReentrancyViolation{
                            .call_node_id = i,
                            .call_pc = node_a.start_pc,
                            .sstore_node_id = j,
                            .sstore_pc = node_b.start_pc,
                            .slot_mask = node_b.state_write_mask,
                        };
                        self.violation_count += 1;
                    }
                }
            }
        }
        return self.violations[0..self.violation_count];
    }
};
