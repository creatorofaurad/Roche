// ============================================================================
// FILE: src/madelyne_integration/pattern_cache.zig
// DESCRIPTION: O(N^2) cross-link matrix pattern cache for Madelyne
// ARCHITECTURE: Bare-Silicon Zig 0.16.0 / Cache-Line Aligned Matrix / Zero Heap Alloc
// INVARIANTS: 64-Byte Cache Line Aligned. 0 Dynamic Allocation.
// ============================================================================

const std = @import("std");

pub const MatrixDimension: usize = 64;

pub const PatternMatchResult = struct {
    pattern_id: usize = 0,
    cross_link_score: f32 = 0.0,
};

pub const PatternMatrix = struct {
    // Pre-allocated O(N^2) cross-link matrix for V2.1 Madelyne
    data: [MatrixDimension][MatrixDimension]f32 align(64) = [_][MatrixDimension]f32{[_]f32{0.0} ** MatrixDimension} ** MatrixDimension,
    node_count: usize = 0,
    update_counter: u64 = 0,

    pub fn init() PatternMatrix {
        return .{
            .data = [_][MatrixDimension]f32{[_]f32{0.0} ** MatrixDimension} ** MatrixDimension,
            .node_count = 0,
            .update_counter = 0,
        };
    }

    pub fn setWeight(self: *PatternMatrix, i: usize, j: usize, weight: f32) bool {
        if (i >= MatrixDimension or j >= MatrixDimension) return false;
        self.data[i][j] = weight;
        self.data[j][i] = weight; // Symmetric matrix cross-link
        self.update_counter += 1;
        if (i >= self.node_count) self.node_count = i + 1;
        if (j >= self.node_count) self.node_count = j + 1;
        return true;
    }

    pub fn getWeight(self: *const PatternMatrix, i: usize, j: usize) f32 {
        if (i >= MatrixDimension or j >= MatrixDimension) return 0.0;
        return self.data[i][j];
    }

    pub fn updatePairwiseDistance(self: *PatternMatrix, i: usize, j: usize, dist: f32) void {
        const current = self.getWeight(i, j);
        const new_weight = (current * 0.8) + (dist * 0.2); // Exponential moving average cross-link decay
        _ = self.setWeight(i, j, new_weight);
    }

    pub fn getMatrixDensity(self: *const PatternMatrix) f32 {
        if (self.node_count <= 1) return 0.0;
        var non_zero: usize = 0;
        var r: usize = 0;
        while (r < self.node_count) : (r += 1) {
            var c: usize = 0;
            while (c < self.node_count) : (c += 1) {
                if (r != c and self.data[r][c] > 0.001) {
                    non_zero += 1;
                }
            }
        }
        const total_possible = self.node_count * (self.node_count - 1);
        return @as(f32, @floatFromInt(non_zero)) / @as(f32, @floatFromInt(total_possible));
    }

    pub fn findTopPatterns(self: *const PatternMatrix, node_id: usize, out_matches: []PatternMatchResult) usize {
        if (node_id >= MatrixDimension or out_matches.len == 0) return 0;
        var count: usize = 0;

        var j: usize = 0;
        while (j < self.node_count) : (j += 1) {
            if (j == node_id) continue;
            const w = self.data[node_id][j];
            if (w > 0.0) {
                if (count < out_matches.len) {
                    out_matches[count] = .{ .pattern_id = j, .cross_link_score = w };
                    count += 1;
                }
            }
        }

        // Sort descending by score (insertion sort)
        var a: usize = 1;
        while (a < count) : (a += 1) {
            const key = out_matches[a];
            var b: isize = @intCast(a - 1);
            while (b >= 0 and out_matches[@intCast(b)].cross_link_score < key.cross_link_score) : (b -= 1) {
                out_matches[@intCast(b + 1)] = out_matches[@intCast(b)];
            }
            out_matches[@intCast(b + 1)] = key;
        }

        return count;
    }
};

// ============================================================================
// UNIT TESTS
// ============================================================================
test "PatternCache: Symmetric O(N^2) Matrix Cross-Linking" {
    var matrix = PatternMatrix.init();
    try std.testing.expectEqual(@as(f32, 0.0), matrix.getMatrixDensity());

    try std.testing.expect(matrix.setWeight(2, 5, 0.85));
    try std.testing.expectEqual(@as(f32, 0.85), matrix.getWeight(2, 5));
    try std.testing.expectEqual(@as(f32, 0.85), matrix.getWeight(5, 2));

    var matches: [5]PatternMatchResult = undefined;
    const match_cnt = matrix.findTopPatterns(2, &matches);
    try std.testing.expectEqual(@as(usize, 1), match_cnt);
    try std.testing.expectEqual(@as(usize, 5), matches[0].pattern_id);
    try std.testing.expectApproxEqAbs(@as(f32, 0.85), matches[0].cross_link_score, 0.001);
}

test "PatternCache: Pairwise Distance Decay & Matrix Density" {
    var matrix = PatternMatrix.init();
    _ = matrix.setWeight(0, 1, 1.0);
    _ = matrix.setWeight(0, 2, 0.5);

    matrix.updatePairwiseDistance(0, 1, 0.5);
    // 1.0 * 0.8 + 0.5 * 0.2 = 0.90
    try std.testing.expectApproxEqAbs(@as(f32, 0.90), matrix.getWeight(0, 1), 0.001);

    const density = matrix.getMatrixDensity();
    try std.testing.expect(density > 0.0);
}
