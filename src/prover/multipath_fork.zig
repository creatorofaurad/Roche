// ============================================================================
// ROCHE SILICON KERNEL: Port of Manticore Depth-First Branch Explorer
// Invariant: Zero Heap Allocation | 64-Byte Cache Aligned | Zig 0.16.0
// ============================================================================

const std = @import("std");

pub const MAX_BRANCH_DEPTH = 32;

pub const BranchState = struct {
    pc: u32,
    checkpoint_id: u32,
    path_constraint_hash: u64,
    is_explored: bool = false,
};

pub const DepthFirstBranchExplorer = struct {
    branch_stack: [MAX_BRANCH_DEPTH]BranchState align(64),
    stack_ptr: usize = 0,
    total_paths_explored: usize = 0,

    pub fn init() DepthFirstBranchExplorer {
        return DepthFirstBranchExplorer{
            .branch_stack = undefined,
            .stack_ptr = 0,
            .total_paths_explored = 0,
        };
    }

    pub fn pushBranch(self: *DepthFirstBranchExplorer, pc: u32, cp: u32, constraint_hash: u64) bool {
        if (self.stack_ptr >= MAX_BRANCH_DEPTH) return false;
        self.branch_stack[self.stack_ptr] = BranchState{
            .pc = pc,
            .checkpoint_id = cp,
            .path_constraint_hash = constraint_hash,
            .is_explored = false,
        };
        self.stack_ptr += 1;
        return true;
    }

    pub fn popBranch(self: *DepthFirstBranchExplorer) ?BranchState {
        if (self.stack_ptr == 0) return null;
        self.stack_ptr -= 1;
        self.total_paths_explored += 1;
        return self.branch_stack[self.stack_ptr];
    }
};

