// ============================================================================
// VOLTA SILICON KERNEL: Port of Wake Inter-Procedural Taint & Sink Tracker
// Invariant: Zero Heap Allocation | 64-Byte Cache Aligned | Zig 0.16.0
// ============================================================================

const std = @import("std");

pub const TaintSink = enum(u8) {
    Selfdestruct,
    Delegatecall,
    SstoreSensitive,
};

pub const TaintSource = enum(u8) {
    Calldata,
    Caller,
    Origin,
};

pub const TaintFlowViolation = struct {
    source: TaintSource,
    sink: TaintSink,
    block_id: u32,
};

pub const InterprocTaintEngine = struct {
    violations: [32]TaintFlowViolation align(64),
    violation_count: usize = 0,
    tainted_registers_mask: u256 = 0,

    pub fn init() InterprocTaintEngine {
        return InterprocTaintEngine{
            .violations = undefined,
            .violation_count = 0,
            .tainted_registers_mask = 0,
        };
    }

    pub fn markTaint(self: *InterprocTaintEngine, reg_idx: u8) void {
        self.tainted_registers_mask |= (@as(u256, 1) << @intCast(reg_idx));
    }

    pub fn checkSink(self: *InterprocTaintEngine, reg_idx: u8, sink: TaintSink, block_id: u32) bool {
        const is_tainted = (self.tainted_registers_mask & (@as(u256, 1) << @intCast(reg_idx))) != 0;
        if (is_tainted) {
            if (self.violation_count < self.violations.len) {
                self.violations[self.violation_count] = TaintFlowViolation{
                    .source = .Calldata,
                    .sink = sink,
                    .block_id = block_id,
                };
                self.violation_count += 1;
            }
            return true;
        }
        return false;
    }
};
