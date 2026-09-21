//! roche_v2_integration_tests.zig: Master End-to-End Test & Verification Suite
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const detectors = @import("detectors_v2.zig");
const orchestrator = @import("ingestion_orchestrator.zig");
const anvil = @import("ingestion_tier1_anvil.zig");
const reth = @import("ingestion_tier2_reth_ipc.zig");
const flashbots = @import("ingestion_tier3_flashbots_mev.zig");
const cli_v2 = @import("cli_v2.zig");
const pier_format = @import("pier_format_engine.zig");

test "ROCHE v2 INTEGRATION SUITE [1/5]: 90-Detector Zero-Allocation Library" {
    var passed: usize = 0;
    inline for (detectors.DETECTOR_REGISTRY) |det| {
        try det.test_case();
        passed += 1;
    }
    try std.testing.expectEqual(@as(usize, 90), passed);
}

test "ROCHE v2 INTEGRATION SUITE [2/5]: Tier 1 Anvil Fork Ingestion" {
    const dummy_addr = [_]u8{0x77} ** 20;
    const fork = anvil.AnvilForkClient.init(0x0100007F, 8545, 19500000, dummy_addr);
    try std.testing.expectEqual(@as(u64, 19500000), fork.fork_block);
}

test "ROCHE v2 INTEGRATION SUITE [3/5]: Tier 2 Reth IPC Mempool Ring Streaming" {
    var reth_client = reth.RethIPCClient.init("\\\\.\\pipe\\reth_test");
    var ring = @import("orchestrator.zig").TraceRingBuffer.init();
    const mock_tx = "0xa9059cbb0000000000000000000000001111111111111111111111111111111111111111";
    try std.testing.expect(reth_client.ingestTransactionPacket(mock_tx, &ring));

    const popped = ring.pop();
    try std.testing.expect(popped != null);
    try std.testing.expectEqual(@as(u16, @intCast(mock_tx.len)), popped.?.bytecode_len);
}

test "ROCHE v2 INTEGRATION SUITE [4/5]: Tier 3 Flashbots MEV-Share SSE Stream" {
    var fb = flashbots.FlashbotsMEVClient.init();
    var ring = @import("orchestrator.zig").TraceRingBuffer.init();
    const mock_sse = "data: {\"hash\":\"0xdef\",\"hook\":true}";
    var hint: flashbots.BackrunHint = undefined;

    try std.testing.expect(fb.parseSseEvent(mock_sse, &hint));
    try std.testing.expect(hint.is_v4_hook);
    try std.testing.expect(fb.streamHintToRing(&hint, &ring));
}

test "ROCHE v2 INTEGRATION SUITE [5/5]: Multi-Tier Orchestrator & .PIER Chunked Engine" {
    const dummy_addr = [_]u8{0x99} ** 20;
    var orch = orchestrator.MainnetIngestionOrchestrator.init(0x0100007F, 8545, 19500000, dummy_addr, "\\\\.\\pipe\\reth_test");

    // Push reentrant exploit bytecode into ring
    const reentrant_code = [_]u8{ 0xF1, 0x60, 0x01, 0x55, 0x00 };
    var pkt = std.mem.zeroes(@import("orchestrator.zig").ExploitTracePacket);
    @memcpy(pkt.bytecode[0..reentrant_code.len], &reentrant_code);
    pkt.bytecode_len = reentrant_code.len;
    try std.testing.expect(orch.ring.push(pkt));

    try std.testing.expect(orch.step());
    try std.testing.expectEqual(@as(usize, 1), orch.metrics.txs_processed);
    try std.testing.expect(orch.metrics.violations_found >= 1);
    try std.testing.expect(orch.metrics.critical_findings >= 1);
}
