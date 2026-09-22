// ============================================================================
// ROCHE SILICON KERNEL: Port of Halmos Symbolic EVM Interval Domain Solver
// Invariant: Zero Heap Allocation | 64-Byte Cache Aligned | Zig 0.16.0
// ============================================================================

const std = @import("std");

pub const IntervalU256 = struct {
    min: u256,
    max: u256,

    pub fn exact(val: u256) IntervalU256 {
        return IntervalU256{ .min = val, .max = val };
    }

    pub fn full() IntervalU256 {
        return IntervalU256{ .min = 0, .max = std.math.maxInt(u256) };
    }

    pub fn add(a: IntervalU256, b: IntervalU256) IntervalU256 {
        const min_val = a.min +% b.min;
        const max_val = a.max +% b.max;
        return IntervalU256{ .min = min_val, .max = max_val };
    }

    pub fn sub(a: IntervalU256, b: IntervalU256) IntervalU256 {
        const min_val = if (a.min >= b.max) a.min - b.max else 0;
        const max_val = if (a.max >= b.min) a.max - b.min else std.math.maxInt(u256);
        return IntervalU256{ .min = min_val, .max = max_val };
    }

    pub fn mul(a: IntervalU256, b: IntervalU256) IntervalU256 {
        return IntervalU256{ .min = a.min *% b.min, .max = a.max *% b.max };
    }

    pub fn isSatisfiableEq(a: IntervalU256, b: IntervalU256) bool {
        return (a.min <= b.max) and (b.min <= a.max);
    }
};

pub const SymbolicStackFrame = struct {
    stack: [1024]IntervalU256 align(64),
    sp: usize = 0,

    pub fn init() SymbolicStackFrame {
        return SymbolicStackFrame{
            .stack = undefined,
            .sp = 0,
        };
    }

    pub inline fn push(self: *SymbolicStackFrame, val: IntervalU256) bool {
        if (self.sp >= 1024) return false;
        self.stack[self.sp] = val;
        self.sp += 1;
        return true;
    }

    pub inline fn pop(self: *SymbolicStackFrame) ?IntervalU256 {
        if (self.sp == 0) return null;
        self.sp -= 1;
        return self.stack[self.sp];
    }
};

