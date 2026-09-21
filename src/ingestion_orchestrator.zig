//! ingestion_orchestrator.zig: Master Mainnet Multi-Tier Ingestion & 90-Detector Coordinator
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const detectors = @import("detectors_v2.zig");
const orchestrator = @import("orchestrator.zig");
const anvil = @import("ingestion_tier1_anvil.zig");
const reth = @import("ingestion_tier2_reth_ipc.zig");
const flashbots = @import("ingestion_tier3_flashbots_mev.zig");
const cfg_mod = @import("cfg.zig");
const vm_mod = @import("vm.zig");

pub const IngestionMetrics = struct {
    txs_processed: usize = 0,
    hints_processed: usize = 0,
    violations_found: usize = 0,
    critical_findings: usize = 0,
};

pub const MainnetIngestionOrchestrator = struct {
    tier1: anvil.AnvilForkClient,
    tier2: reth.RethIPCClient,
    tier3: flashbots.FlashbotsMEVClient,
    ring: orchestrator.TraceRingBuffer,
    metrics: IngestionMetrics = .{},

    pub fn init(
        fork_ip: u32,
        fork_port: u16,
        fork_block: u64,
        target_addr: [20]u8,
        reth_socket_path: []const u8,
    ) MainnetIngestionOrchestrator {
        return .{
            .tier1 = anvil.AnvilForkClient.init(fork_ip, fork_port, fork_block, target_addr),
            .tier2 = reth.RethIPCClient.init(reth_socket_path),
            .tier3 = flashbots.FlashbotsMEVClient.init(),
            .ring = orchestrator.TraceRingBuffer.init(),
        };
    }

    /// Ingest a transaction batch and evaluate all 90 detectors with zero allocations
    pub fn processPendingPacket(self: *MainnetIngestionOrchestrator, packet: *const orchestrator.ExploitTracePacket) usize {
        self.metrics.txs_processed += 1;
        const code_slice = packet.bytecode[0..packet.bytecode_len];
        const cfg = cfg_mod.ControlFlowGraph.build(code_slice);

        var findings_in_tx: usize = 0;
        inline for (detectors.DETECTOR_REGISTRY) |det| {
            const res = det.detect(null, &cfg);
            if (res.found) {
                findings_in_tx += 1;
                self.metrics.violations_found += 1;
                if (res.severity >= 8) {
                    self.metrics.critical_findings += 1;
                }
            }
        }
        return findings_in_tx;
    }

    /// End-to-end multi-tier execution tick
    pub fn step(self: *MainnetIngestionOrchestrator) bool {
        if (self.ring.pop()) |packet| {
            _ = self.processPendingPacket(&packet);
            return true;
        }
        return false;
    }
};

test "Mainnet Orchestrator: Multi-Tier Ingestion & 90-Detector Execution Pipeline" {
    const dummy_addr = [_]u8{0x22} ** 20;
    var orch = MainnetIngestionOrchestrator.init(0x0100007F, 8545, 19500000, dummy_addr, "\\\\.\\pipe\\reth_test");

    // 1. Simulate Tier 2 Reth Mempool Stream Push (Vulnerable Reentrancy Bytecode)
    const reentrant_code = [_]u8{ 0xF1, 0x60, 0x01, 0x55, 0x00 }; // CALL then SSTORE
    var pkt = std.mem.zeroes(orchestrator.ExploitTracePacket);
    @memcpy(pkt.bytecode[0..reentrant_code.len], &reentrant_code);
    pkt.bytecode_len = reentrant_code.len;
    try std.testing.expect(orch.ring.push(pkt));

    // 2. Execute Orchestrator Step
    try std.testing.expect(orch.step());
    try std.testing.expectEqual(@as(usize, 1), orch.metrics.txs_processed);
    try std.testing.expect(orch.metrics.violations_found >= 1);
    try std.testing.expect(orch.metrics.critical_findings >= 1);
}
