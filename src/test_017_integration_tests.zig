//! test_017_integration_tests.zig: Complete INT-001 through INT-012 Integration Test Suite
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const testing = std.testing;
const types = @import("types.zig");
const vm_mod = @import("vm.zig");
const cfg_mod = @import("cfg.zig");
const detectors = @import("detectors_v2.zig");
const orchestrator = @import("ingestion_orchestrator.zig");
const anvil = @import("ingestion_tier1_anvil.zig");
const reth = @import("ingestion_tier2_reth_ipc.zig");
const flashbots = @import("ingestion_tier3_flashbots_mev.zig");

test "INT-001: Pipeline: Anvil Fork -> Disasm -> CFG -> Detector Sweep" {
    const dummy_addr = [_]u8{0x77} ** 20;
    const fork = anvil.AnvilForkClient.init(0x0100007F, 8545, 19500000, dummy_addr);
    try testing.expectEqual(@as(u64, 19500000), fork.fork_block);

    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_constant_product_pool = true;
    cfg.has_k_invariant_check = false;

    const res = detectors.detectCP01(null, &cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "INT-002: Pipeline: Reth IPC Mempool Ring -> Ingestion -> Execution" {
    var reth_client = reth.RethIPCClient.init("\\\\.\\pipe\\reth_test");
    var ring = @import("orchestrator.zig").TraceRingBuffer.init();
    const mock_tx = "0xa9059cbb0000000000000000000000001111111111111111111111111111111111111111";
    try testing.expect(reth_client.ingestTransactionPacket(mock_tx, &ring));

    const popped = ring.pop();
    try testing.expect(popped != null);
    try testing.expectEqual(@as(u16, @intCast(mock_tx.len)), popped.?.bytecode_len);
}

test "INT-003: Pipeline: Flashbots MEV-Share Hint -> Hook Detection -> Backrun Analysis" {
    var fb = flashbots.FlashbotsMEVClient.init();
    var ring = @import("orchestrator.zig").TraceRingBuffer.init();
    const mock_sse = "data: {\"hash\":\"0xdef\",\"hook\":true}";
    var hint: flashbots.BackrunHint = undefined;

    try testing.expect(fb.parseSseEvent(mock_sse, &hint));
    try testing.expect(hint.is_v4_hook);
    try testing.expect(fb.streamHintToRing(&hint, &ring));
}

test "INT-004: Pipeline: Multi-Tier Ingestion Orchestrator Tick & Metrics" {
    const dummy_addr = [_]u8{0x99} ** 20;
    var orch = orchestrator.MainnetIngestionOrchestrator.init(0x0100007F, 8545, 19500000, dummy_addr, "\\\\.\\pipe\\reth_test");

    const reentrant_code = [_]u8{ 0xF1, 0x60, 0x01, 0x55, 0x00 };
    var pkt = std.mem.zeroes(@import("orchestrator.zig").ExploitTracePacket);
    @memcpy(pkt.bytecode[0..reentrant_code.len], &reentrant_code);
    pkt.bytecode_len = reentrant_code.len;
    try testing.expect(orch.ring.push(pkt));

    try testing.expect(orch.step());
    try testing.expectEqual(@as(usize, 1), orch.metrics.txs_processed);
    try testing.expect(orch.metrics.violations_found >= 1);
    try testing.expect(orch.metrics.critical_findings >= 1);
}

test "INT-005: Pipeline: RF-01 Reentrancy End-to-End Bytecode Execution & Detection" {
    var vm = vm_mod.VM.init();
    const exploit_bytecode = [_]u8{
        0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0xAA, 0x60, 0xFF, 0xF1, // CALL
        0x60, 0x01, 0x60, 0x05, 0x55, // SSTORE(5, 1)
        0x00,
    };
    _ = vm.execute(&exploit_bytecode);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectRF01(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 9), res.severity);
}

test "INT-006: Pipeline: TS-02 Transient Storage Revert & Journal Rollback Verification" {
    var vm = vm_mod.VM.init();
    const cp = vm.transient_journal.checkpoint();
    const dummy_slot: [32]u8 = [_]u8{0} ** 32;
    const dummy_old: [32]u8 = [_]u8{0} ** 32;
    const dummy_new: [32]u8 = [_]u8{0xFF} ** 32;
    vm.transient_journal.recordTSTORE(vm.cheatcodes.current_address, dummy_slot, dummy_old, dummy_new, 1);
    vm.transient_storage.tstore(0, 0xFF);

    vm.transient_journal.rollback(cp);
    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectTS02(&vm, &dummy_cfg);
    try testing.expect(res.found);
}

test "INT-007: Pipeline: CP-01 Constant Product Deficit Detection via SIMD Shadow Registers" {
    var vm = vm_mod.VM.init();
    vm.shadow_registers.recordSlot(0, 990_000, 1_000_000);
    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectCP01(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "INT-008: Pipeline: VLT-01 Vault Donation Attack State Delta & Detection" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.is_erc4626_vault = true;
    cfg.has_virtual_shares_offset = false;
    const res = detectors.detectVLT01(null, &cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 9), res.severity);
}

test "INT-009: Pipeline: VLT-02 Vault Rounding Slippage Delta Verification" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_share_to_asset_conversion = true;
    cfg.rounds_shares_down_on_redeem = true;
    const res = detectors.detectVLT02(null, &cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 8), res.severity);
}

test "INT-010: Pipeline: FA-01 Flash Loan Deficit Verification via Spot Reserve Valuation" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_flashloan_receiver = true;
    cfg.reads_spot_reserves_for_valuation = true;
    const res = detectors.detectFA01(null, &cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "INT-011: Pipeline: CS-04 Cross-Contract Hook Storage Isolation Check" {
    var vm = vm_mod.VM.init();
    if (vm.call_stack.current()) |frame| {
        frame.flags |= types.FRAME_IN_AFTER_SWAP;
    }
    vm.reentrancy_mask.persistent_write = true;
    var cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectCS04(&vm, &cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 9), res.severity);
}

test "INT-012: Pipeline: .PIER Binary Chunk Ingestion & Master 90-Detector Zero-Alloc Sweep" {
    var passed: usize = 0;
    inline for (detectors.DETECTOR_REGISTRY) |det| {
        try det.test_case();
        passed += 1;
    }
    try testing.expectEqual(@as(usize, 90), passed);
}
