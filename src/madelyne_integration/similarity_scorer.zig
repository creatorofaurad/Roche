// ============================================================================
// FILE: src/madelyne_integration/similarity_scorer.zig
// DESCRIPTION: Graph Edit Distance (GED) similarity scorer for EVM trace graphs
// ARCHITECTURE: Bare-Silicon Zig 0.16.0 / Bounded GED / Zero Heap Allocation
// INVARIANTS: 0 Dynamic Allocations on Scorer Path.
// ============================================================================

const std = @import("std");

pub const CompactInvariantGraph = extern struct {
    node_opcodes: u64 = 0, // 8 packed opcodes
    edge_nibbles: u32 = 0, // 8 packed 4-bit edges
    slot_hash: u32 = 0,
    node_count: u8 = 0,
    edge_count: u8 = 0,
    padding: [14]u8 = [_]u8{0} ** 14,
};

/// Graph Edit Distance (GED) similarity scorer for bytecode traces
pub fn scoreGED(traceA: []const u8, traceB: []const u8) f64 {
    if (traceA.len == 0 and traceB.len == 0) return 1.0;
    if (traceA.len == 0 or traceB.len == 0) return 0.0;

    var popcnt_a: [256]u32 = [_]u32{0} ** 256;
    var popcnt_b: [256]u32 = [_]u32{0} ** 256;

    for (traceA) |b| popcnt_a[b] += 1;
    for (traceB) |b| popcnt_b[b] += 1;

    var diff_sum: u32 = 0;
    var i: usize = 0;
    while (i < 256) : (i += 1) {
        const count_a = popcnt_a[i];
        const count_b = popcnt_b[i];
        if (count_a > count_b) {
            diff_sum += (count_a - count_b);
        } else {
            diff_sum += (count_b - count_a);
        }
    }

    const total_len = traceA.len + traceB.len;
    const distance_ratio = @as(f64, @floatFromInt(diff_sum)) / @as(f64, @floatFromInt(total_len));
    const similarity = 1.0 - distance_ratio;
    return if (similarity < 0.0) 0.0 else if (similarity > 1.0) 1.0 else similarity;
}

/// Bounded Graph Edit Distance scorer between CompactInvariantGraph structures
pub fn scoreGraphGED(graphA: CompactInvariantGraph, graphB: CompactInvariantGraph) f64 {
    var cost: f64 = 0.0;

    // Node count mismatch cost
    const count_diff: f64 = @abs(@as(f64, @floatFromInt(graphA.node_count)) - @as(f64, @floatFromInt(graphB.node_count)));
    cost += count_diff * 1.5;

    // Node opcodes XOR diff (bit Hamming distance)
    const op_xor = graphA.node_opcodes ^ graphB.node_opcodes;
    const op_diff_bits: f64 = @floatFromInt(@popCount(op_xor));
    cost += op_diff_bits * 0.1;

    // Edge nibbles XOR diff
    const edge_xor = graphA.edge_nibbles ^ graphB.edge_nibbles;
    const edge_diff_bits: f64 = @floatFromInt(@popCount(edge_xor));
    cost += edge_diff_bits * 0.15;

    // Storage slot hash mismatch cost
    if (graphA.slot_hash != graphB.slot_hash) {
        cost += 2.0;
    }

    // Convert GED cost into normalized similarity [0.0, 1.0]
    const normalized = 1.0 / (1.0 + (cost * 0.1));
    return if (normalized < 0.0) 0.0 else if (normalized > 1.0) 1.0 else normalized;
}

// ============================================================================
// UNIT TESTS
// ============================================================================
test "SimilarityScorer: Exact Bytecode Match GED" {
    const codeA = [_]u8{ 0x60, 0x80, 0x60, 0x40, 0x52, 0x34, 0x80, 0x15 };
    const codeB = [_]u8{ 0x60, 0x80, 0x60, 0x40, 0x52, 0x34, 0x80, 0x15 };

    const score = scoreGED(&codeA, &codeB);
    try std.testing.expectApproxEqAbs(1.0, score, 0.0001);
}

test "SimilarityScorer: Divergent Trace GED & Graph Similarity" {
    const codeA = [_]u8{ 0x60, 0x80, 0x60, 0x40, 0x52 };
    const codeB = [_]u8{ 0x55, 0x54, 0x55, 0x54, 0x00 };

    const score = scoreGED(&codeA, &codeB);
    try std.testing.expect(score < 0.5);

    const g1 = CompactInvariantGraph{ .node_opcodes = 0x5B5B5B5B, .node_count = 4, .slot_hash = 0x1234 };
    var g2 = CompactInvariantGraph{ .node_opcodes = 0x5B5B5B5B, .node_count = 4, .slot_hash = 0x1234 };

    const g_score_identical = scoreGraphGED(g1, g2);
    try std.testing.expectApproxEqAbs(1.0, g_score_identical, 0.0001);

    g2.slot_hash = 0x9999;
    const g_score_diff = scoreGraphGED(g1, g2);
    try std.testing.expect(g_score_diff < g_score_identical);
}
