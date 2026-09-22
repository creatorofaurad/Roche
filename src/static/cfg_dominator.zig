// ============================================================================
// ROCHE SILICON KERNEL: Port of Slither Node.py CFG & Dominator Tree
// Invariant: Zero Heap Allocation | 64-Byte Cache Aligned | Zig 0.16.0
// ============================================================================

const std = @import("std");
const types = @import("../types.zig");

pub const MAX_CFG_NODES = 512;
pub const MAX_EDGES_PER_NODE = 8;

pub const CFGNodeFlags = packed struct {
    has_external_call: bool = false,
    has_delegatecall: bool = false,
    has_selfdestruct: bool = false,
    has_sstore: bool = false,
    has_sload: bool = false,
    has_tstore: bool = false,
    has_tload: bool = false,
    is_reentrant_sink: bool = false,
    _pad: u8 = 0,
};

pub const CFGNode = struct {
    id: u32,
    start_pc: u32,
    end_pc: u32,
    successors: [MAX_EDGES_PER_NODE]u32,
    successor_count: u8,
    predecessors: [MAX_EDGES_PER_NODE]u32,
    predecessor_count: u8,
    idom: u32, // Immediate dominator ID
    state_read_mask: u256,
    state_write_mask: u256,
    flags: CFGNodeFlags,
};

pub const CFGDominatorEngine = struct {
    nodes: [MAX_CFG_NODES]CFGNode align(64),
    node_count: u32,
    // Adjacency bitset: [512][8]u64 for SIMD bitwise reachability
    reachability_matrix: [MAX_CFG_NODES][8]u64,

    pub fn init() CFGDominatorEngine {
        return CFGDominatorEngine{
            .nodes = undefined,
            .node_count = 0,
            .reachability_matrix = [_][8]u64{[_]u64{0} ** 8} ** MAX_CFG_NODES,
        };
    }

    pub fn addNode(self: *CFGDominatorEngine, start_pc: u32, end_pc: u32, flags: CFGNodeFlags) ?u32 {
        if (self.node_count >= MAX_CFG_NODES) return null;
        const id = self.node_count;
        self.nodes[id] = CFGNode{
            .id = id,
            .start_pc = start_pc,
            .end_pc = end_pc,
            .successors = [_]u32{0} ** MAX_EDGES_PER_NODE,
            .successor_count = 0,
            .predecessors = [_]u32{0} ** MAX_EDGES_PER_NODE,
            .predecessor_count = 0,
            .idom = id,
            .state_read_mask = 0,
            .state_write_mask = 0,
            .flags = flags,
        };
        self.node_count += 1;
        return id;
    }

    pub fn addEdge(self: *CFGDominatorEngine, from: u32, to: u32) void {
        if (from >= self.node_count or to >= self.node_count) return;
        if (self.nodes[from].successor_count < MAX_EDGES_PER_NODE) {
            self.nodes[from].successors[self.nodes[from].successor_count] = to;
            self.nodes[from].successor_count += 1;
        }
        if (self.nodes[to].predecessor_count < MAX_EDGES_PER_NODE) {
            self.nodes[to].predecessors[self.nodes[to].predecessor_count] = from;
            self.nodes[to].predecessor_count += 1;
        }
        const word_idx = to / 64;
        const bit_idx: u6 = @intCast(to % 64);
        self.reachability_matrix[from][word_idx] |= (@as(u64, 1) << bit_idx);
    }

    pub fn computeDominators(self: *CFGDominatorEngine) void {
        if (self.node_count == 0) return;
        self.nodes[0].idom = 0;
        var changed = true;
        while (changed) {
            changed = false;
            var i: u32 = 1;
            while (i < self.node_count) : (i += 1) {
                if (self.nodes[i].predecessor_count == 0) continue;
                var new_idom = self.nodes[i].predecessors[0];
                var p_idx: usize = 1;
                while (p_idx < self.nodes[i].predecessor_count) : (p_idx += 1) {
                    const p = self.nodes[i].predecessors[p_idx];
                    if (self.nodes[p].idom != p) {
                        new_idom = self.intersectDominators(p, new_idom);
                    }
                }
                if (self.nodes[i].idom != new_idom) {
                    self.nodes[i].idom = new_idom;
                    changed = true;
                }
            }
        }
    }

    fn intersectDominators(self: *const CFGDominatorEngine, b1_in: u32, b2_in: u32) u32 {
        var finger1 = b1_in;
        var finger2 = b2_in;
        while (finger1 != finger2) {
            while (finger1 > finger2) finger1 = self.nodes[finger1].idom;
            while (finger2 > finger1) finger2 = self.nodes[finger2].idom;
        }
        return finger1;
    }

    pub fn dominates(self: *const CFGDominatorEngine, a: u32, b: u32) bool {
        if (a >= self.node_count or b >= self.node_count) return false;
        var current = b;
        while (current != 0) {
            if (current == a) return true;
            const next = self.nodes[current].idom;
            if (next == current) break;
            current = next;
        }
        return a == 0;
    }
};

