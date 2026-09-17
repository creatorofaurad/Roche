// ============================================================================
// VOLTA SILICON KERNEL: Port of 4naly3er Loop Gas & SLOAD Cache Optimizer
// Invariant: Zero Heap Allocation | 64-Byte Cache Aligned | Zig 0.16.0
// ============================================================================

const std = @import("std");
const cfg_mod = @import("cfg_dominator.zig");

pub const GasOptimizationOpportunity = struct {
    loop_header_pc: u32,
    redundant_sload_pc: u32,
    slot_index: u256,
};

pub const GasLoopOptimizer = struct {
    opportunities: [32]GasOptimizationOpportunity align(64),
    opportunity_count: usize = 0,

    pub fn init() GasLoopOptimizer {
        return GasLoopOptimizer{
            .opportunities = undefined,
            .opportunity_count = 0,
        };
    }

    pub fn analyzeLoopSLOAD(self: *GasLoopOptimizer, cfg: *const cfg_mod.CFGDominatorEngine) []const GasOptimizationOpportunity {
        self.opportunity_count = 0;
        var i: u32 = 0;
        while (i < cfg.node_count) : (i += 1) {
            const node = &cfg.nodes[i];
            if (node.flags.has_sload and !node.flags.has_sstore) {
                // Check if loop back-edge dominates this node
                var j: u32 = 0;
                while (j < cfg.node_count) : (j += 1) {
                    if (cfg.dominates(j, i) and cfg.nodes[j].predecessor_count > 1) {
                        if (self.opportunity_count < self.opportunities.len) {
                            self.opportunities[self.opportunity_count] = GasOptimizationOpportunity{
                                .loop_header_pc = cfg.nodes[j].start_pc,
                                .redundant_sload_pc = node.start_pc,
                                .slot_index = node.state_read_mask,
                            };
                            self.opportunity_count += 1;
                        }
                    }
                }
            }
        }
        return self.opportunities[0..self.opportunity_count];
    }
};
