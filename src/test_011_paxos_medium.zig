//! test_011_paxos_medium.zig: Test suite for Paxos Medium-Severity Compliance Detectors (PX-MED-01..03)
//! Pure Zig 0.16.0 with ZERO Dynamic Heap Allocations.

const std = @import("std");
const types = @import("types.zig");
const cfg_mod = @import("cfg.zig");
const vm_mod = @import("vm.zig");
const med = @import("detectors_paxos_medium.zig");

test "PX-MED-01-TP: StateDelta: Balance mutation executed without LOG event" {
    var vm = vm_mod.VM.init();
    const empty_code = [_]u8{0x00};
    var cfg = cfg_mod.ControlFlowGraph.build(&empty_code);

    const addr: [20]u8 = [_]u8{0x11} ** 20;
    const slot: [32]u8 = [_]u8{0x01} ** 32;
    vm.delta_journal.recordSSTORE(addr, slot, [_]u8{0} ** 32, types.U256.fromNative(100).toBytes(), 0);
    // Mark with silent mutation flag (0x40)
    vm.delta_journal.entries[0].flags |= 0x40;

    const res = med.detectPXMed01(&vm, &cfg);
    try std.testing.expect(res.found);
    try std.testing.expectEqual(@as(u8, 6), res.severity);
    try std.testing.expect(std.mem.indexOf(u8, res.evidence[0..res.evidence_len], "PX-MED-01") != null);
}

test "PX-MED-01-TN: StateDelta: Balance mutation with normal event logging passes cleanly" {
    var vm = vm_mod.VM.init();
    const empty_code = [_]u8{0x00};
    var cfg = cfg_mod.ControlFlowGraph.build(&empty_code);

    const addr: [20]u8 = [_]u8{0x11} ** 20;
    const slot: [32]u8 = [_]u8{0x01} ** 32;
    vm.delta_journal.recordSSTORE(addr, slot, [_]u8{0} ** 32, types.U256.fromNative(100).toBytes(), 0);

    const res = med.detectPXMed01(&vm, &cfg);
    try std.testing.expect(!res.found);
}

test "PX-MED-02-TP: Shadow: Cumulative redemption rounding drift exceeds 10,000 wei threshold" {
    var vm = vm_mod.VM.init();
    const empty_code = [_]u8{0x00};
    const cfg = cfg_mod.ControlFlowGraph.build(&empty_code);

    // 10,000 redemptions where ideal = 10,000,000 wei, actual = 9,980,000 wei (20,000 wei drift)
    const ideal_payout: u256 = 10_000_000;
    const actual_payout: u256 = 9_980_000;
    const num_txs: u256 = 10_000;

    vm.shadow_registers.recordSlot(0, ideal_payout, actual_payout);
    vm.shadow_registers.recordSlot(1, 0, 0);
    vm.shadow_registers.recordSlot(2, num_txs, num_txs);

    const res = med.detectPXMed02(&vm, &cfg);
    try std.testing.expect(res.found);
    try std.testing.expectEqual(@as(u8, 5), res.severity);
    try std.testing.expect(std.mem.indexOf(u8, res.evidence[0..res.evidence_len], "PX-MED-02") != null);
}

test "PX-MED-02-TN: Shadow: Bounded redemption rounding drift within 1 wei/tx tolerance" {
    var vm = vm_mod.VM.init();
    const empty_code = [_]u8{0x00};
    const cfg = cfg_mod.ControlFlowGraph.build(&empty_code);

    // 10,000 redemptions with 5,000 wei drift (0.5 wei/tx <= 1 wei/tx tolerance)
    const ideal_payout: u256 = 10_000_000;
    const actual_payout: u256 = 9_995_000;
    const num_txs: u256 = 10_000;

    vm.shadow_registers.recordSlot(0, ideal_payout, actual_payout);
    vm.shadow_registers.recordSlot(1, 0, 0);
    vm.shadow_registers.recordSlot(2, num_txs, num_txs);

    const res = med.detectPXMed02(&vm, &cfg);
    try std.testing.expect(!res.found);
}

test "PX-MED-03-TP: Shadow: Admin batch operation executed with unbounded batch size" {
    var vm = vm_mod.VM.init();
    const empty_code = [_]u8{0x00};
    const cfg = cfg_mod.ControlFlowGraph.build(&empty_code);

    // Admin batch operation with 1,200 addresses (exceeds 500 limit)
    vm.shadow_registers.recordSlot(0, 1200, 1200);
    vm.shadow_registers.recordSlot(1, 1, 1); // is_admin_batch = true

    const res = med.detectPXMed03(&vm, &cfg);
    try std.testing.expect(res.found);
    try std.testing.expectEqual(@as(u8, 6), res.severity);
    try std.testing.expect(std.mem.indexOf(u8, res.evidence[0..res.evidence_len], "PX-MED-03") != null);
}

test "PX-MED-03-TN: Shadow: Admin batch operation with bounded batch size passes" {
    var vm = vm_mod.VM.init();
    const empty_code = [_]u8{0x00};
    const cfg = cfg_mod.ControlFlowGraph.build(&empty_code);

    // Admin batch with 50 addresses (within 500 limit)
    vm.shadow_registers.recordSlot(0, 50, 50);
    vm.shadow_registers.recordSlot(1, 1, 1);

    const res = med.detectPXMed03(&vm, &cfg);
    try std.testing.expect(!res.found);
}
