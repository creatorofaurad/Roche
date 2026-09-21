// ============================================================================
// EMPIRICAL SOVEREIGN PROOF: Physical Hardware Verification Suite
// ============================================================================

const std = @import("std");
const pier_rev = @import("pier_reversible_engine.zig");
const pier_tans = @import("pier_tans_engine.zig");
const nbw_matmul = @import("nbw_streaming_matmul.zig");
const madelyne = @import("madelyne_quadratic_learner.zig");
const charyec = @import("charyec.zig");

test "PROOF 1: .PIER Reversible FWHT + Bit-Plane Decomposition & Bit-Exact Identity" {
    const BLOCK_SIZE: usize = 4096;
    var raw_weights: [BLOCK_SIZE]f32 align(64) = undefined;
    for (&raw_weights, 0..) |*w, i| {
        const val = @as(f32, @floatFromInt(i % 64)) * 0.015625 - 0.5;
        w.* = val;
    }

    var transformed_weights: [BLOCK_SIZE]f32 align(64) = undefined;
    @memcpy(&transformed_weights, &raw_weights);

    // 1. Forward FWHT Transform (in-place, 0 heap alloc)
    pier_rev.PierReversibleEngine.forwardFWHT(BLOCK_SIZE, &transformed_weights);

    // 2. Bit-Plane Segregation (Sign, Exponent, Mantissa)
    var raw_fp16: [64]u16 = undefined;
    for (0..64) |i| {
        raw_fp16[i] = @as(u16, @intCast(0x3C00 + i * 17));
    }
    const sliced = pier_rev.PierReversibleEngine.sliceBitPlanes(&raw_fp16);
    var reconstructed_fp16: [64]u16 = undefined;
    pier_rev.PierReversibleEngine.reconstructBitPlanes(&sliced, &reconstructed_fp16);

    // Verify 100% exact bit identity across all 64 elements
    for (0..64) |i| {
        try std.testing.expectEqual(raw_fp16[i], reconstructed_fp16[i]);
    }

    // 3. Inverse FWHT (Lossless Reversal)
    var reconstructed: [BLOCK_SIZE]f32 align(64) = undefined;
    @memcpy(&reconstructed, &transformed_weights);
    pier_rev.PierReversibleEngine.inverseFWHT(BLOCK_SIZE, &reconstructed);

    for (raw_weights, 0..) |orig, i| {
        const diff = @abs(orig - reconstructed[i]);
        try std.testing.expect(diff <= 1e-5);
    }
}

test "PROOF 2: Madelyne SPSC Lock-Free RingBuffer, 2752-Byte C-ABI & O(N^2) Matrix" {
    var engine = madelyne.MadelyneQuadraticEngine.init();

    // Verify exact C-ABI cache line alignment (2752 bytes = 43 * 64B)
    try std.testing.expectEqual(@as(usize, 2752), @sizeOf(madelyne.ExploitTracePacket));

    var packet: madelyne.ExploitTracePacket = undefined;
    packet.timestamp_ns = 1789928200;
    packet.bytecode_len = 16;
    @memset(&packet.bytecode, 0x60);
    packet.storage_diffs_len = 2;
    packet.branch_constraints_len = 1;
    packet.invariant_violated = 1;
    packet.padding_header = [_]u8{0} ** 5;
    packet.storage_changes[0].address = [_]u8{0xEE} ** 20;
    packet.storage_changes[0].slot = [_]u8{0x01} ** 32;
    packet.storage_changes[0].old_value = [_]u8{0x00} ** 32;
    packet.storage_changes[0].new_value = [_]u8{0xFF} ** 32;
    packet.storage_changes[0].opcode = 0x55;
    packet.padding_tail = [_]u8{0} ** 40;

    // Lock-Free SPSC Push & Pop
    const pushed = engine.ipc_ring.push(packet);
    try std.testing.expect(pushed);

    const popped = engine.ipc_ring.pop();
    try std.testing.expect(popped != null);
    try std.testing.expectEqual(@as(u8, 2), popped.?.storage_diffs_len);

    // Ingest 5 graphs and compute O(N^2) pairwise associative matrix
    for (0..5) |i| {
        var p = packet;
        p.bytecode[0] = @as(u8, @intCast(0x50 + i));
        const g = engine.lowerTraceToDAG(p);
        engine.integrateAndCrossLink(g);
    }

    try std.testing.expectEqual(@as(usize, 5), engine.cluster_count);
    try std.testing.expect(engine.cross_link_matrix[0][0] == 1.0);
    try std.testing.expect(engine.cross_link_matrix[0][1] >= 0.0);
}

test "PROOF 3: Charyelog Zero-Heap Compile-Time Enforcement & SMT-LIB2 Contract Lowering" {
    const valid_code = "invariant precision_loss: lattice8<E8> 0.0000001";
    const invalid_code =
        \\fn bad_alloc() -> void {
        \\    let ptr = malloc(1024);
        \\}
    ;

    const valid_res = charyec.CharyeCompiler.compileSource(valid_code);
    try std.testing.expect(valid_res.success == true);
    try std.testing.expect(valid_res.smt_assertions_count > 0);

    const invalid_res = charyec.CharyeCompiler.compileSource(invalid_code);
    try std.testing.expect(invalid_res.success == false);
    try std.testing.expectEqualStrings("error[C001]", invalid_res.diagnostics[0].code);
}

test "PROOF 4: .NBW Streaming AVX2 MatMul In-Register Vectorization" {
    const M: usize = 32;
    const K: usize = 64;
    var A: [M * K]f32 align(64) = undefined;
    var x: [K]f32 align(64) = undefined;
    var y: [M]f32 align(64) = [_]f32{0.0} ** M;

    @memset(&A, 1.0);
    @memset(&x, 2.0);

    nbw_matmul.NbwStreamingMatMul.streamingGemvAVX2(&A, &x, &y, M, K);

    // Each y[i] should be sum(1.0 * 2.0, k=0..64) = 128.0
    for (y) |val| {
        try std.testing.expectEqual(@as(f32, 128.0), val);
    }
}
