// ============================================================================
// VOLTA SILICON KERNEL: Port of Echidna 64KB Coverage Processor & Minimizer
// Invariant: Zero Heap Allocation | 64-Byte Cache Aligned | Zig 0.16.0
// ============================================================================

const std = @import("std");

pub const COVERAGE_MAP_SIZE = 65536;

pub const BitmapProcessor = struct {
    coverage_map: [COVERAGE_MAP_SIZE]u8 align(64),
    virgin_map: [COVERAGE_MAP_SIZE]u8 align(64),
    prev_loc: u16 = 0,
    total_edges: usize = 0,

    pub fn init() BitmapProcessor {
        return BitmapProcessor{
            .coverage_map = [_]u8{0} ** COVERAGE_MAP_SIZE,
            .virgin_map = [_]u8{0xFF} ** COVERAGE_MAP_SIZE,
            .prev_loc = 0,
            .total_edges = 0,
        };
    }

    pub inline fn logBranch(self: *BitmapProcessor, cur_loc: u16) void {
        const edge = (@as(usize, cur_loc) ^ (@as(usize, self.prev_loc) >> 1)) % COVERAGE_MAP_SIZE;
        self.prev_loc = cur_loc;
        if (self.coverage_map[edge] < 255) {
            self.coverage_map[edge] += 1;
        }
    }

    pub fn countNewCoverage(self: *BitmapProcessor) usize {
        var new_edges: usize = 0;
        var i: usize = 0;
        while (i < COVERAGE_MAP_SIZE) : (i += 32) {
            const cov_vec: @Vector(32, u8) = self.coverage_map[i..][0..32].*;
            const vir_vec: @Vector(32, u8) = self.virgin_map[i..][0..32].*;
            const diff = cov_vec & vir_vec;
            const diff_arr: [32]u8 = diff;
            for (diff_arr) |b| {
                if (b > 0) new_edges += 1;
            }
            self.virgin_map[i..][0..32].* = vir_vec & ~cov_vec;
        }
        self.total_edges += new_edges;
        return new_edges;
    }

    pub fn resetTrace(self: *BitmapProcessor) void {
        @memset(&self.coverage_map, 0);
        self.prev_loc = 0;
    }
};
