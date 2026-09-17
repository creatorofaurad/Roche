// ============================================================================
// VOLTA SILICON KERNEL: Port of Kontrol KCFG Simplification & Invariant Prover
// Invariant: Zero Heap Allocation | 64-Byte Cache Aligned | Zig 0.16.0
// ============================================================================

const std = @import("std");

pub const KCFGNodeType = enum(u8) {
    Initial,
    Step,
    Branch,
    TerminalSuccess,
    TerminalRevert,
};

pub const KCFGNode = struct {
    id: u32,
    node_type: KCFGNodeType,
    rule_id: u16,
    is_subsumed: bool = false,
};

pub const KontrolProver = struct {
    nodes: [128]KCFGNode align(64),
    node_count: usize = 0,

    pub fn init() KontrolProver {
        return KontrolProver{
            .nodes = undefined,
            .node_count = 0,
        };
    }

    pub fn addNode(self: *KontrolProver, node_type: KCFGNodeType, rule: u16) ?u32 {
        if (self.node_count >= self.nodes.len) return null;
        const id: u32 = @intCast(self.node_count);
        self.nodes[id] = KCFGNode{
            .id = id,
            .node_type = node_type,
            .rule_id = rule,
            .is_subsumed = false,
        };
        self.node_count += 1;
        return id;
    }

    pub fn proveNoRevertLeaves(self: *const KontrolProver) bool {
        for (self.nodes[0..self.node_count]) |node| {
            if (node.node_type == .TerminalRevert and !node.is_subsumed) {
                return false;
            }
        }
        return true;
    }
};
