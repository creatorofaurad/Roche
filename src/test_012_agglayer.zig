//! test_012_agglayer.zig: Formal Invariant Acceptance Test Suite for Agglayer & Vault Bridge
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const testing = std.testing;
const types = @import("types.zig");
const vm_mod = @import("vm.zig");
const cfg_mod = @import("cfg.zig");
const ag = @import("detectors_agglayer.zig");

// --- AG-VLT-01: Vault Bridge Share Inflation & Parity ---
test "AG-VLT-01-TP: StateDelta: Direct donation to reserved assets causes zero shares minted on deposit" {
    var vm = vm_mod.VM.init();
    const dummy_addr = vm.cheatcodes.current_address;
    const slot_supply: [32]u8 = [_]u8{0} ** 32;
    var slot_reserved: [32]u8 = [_]u8{0} ** 32;
    slot_reserved[31] = 1;

    // Pre-state: totalSupply = 0, reservedAssets = 1000 WETH (donated)
    // Post-state: victim deposits 50 WETH, but totalSupply remains 0 (0 shares minted)
    const s_pre = types.U256.fromNative(0).toBytes();
    const s_post = types.U256.fromNative(0).toBytes();
    const r_pre = types.U256.fromNative(1000_000000000000000000).toBytes();
    const r_post = types.U256.fromNative(1050_000000000000000000).toBytes();

    vm.delta_journal.recordSSTORE(dummy_addr, slot_supply, s_pre, s_post, 1);
    vm.delta_journal.recordSSTORE(dummy_addr, slot_reserved, r_pre, r_post, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGVLT01(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "AG-VLT-01-TN: StateDelta: 1:1 convertToShares mints exact 50 shares for 50 assets" {
    var vm = vm_mod.VM.init();
    // Shadow Register: Slot 0: totalSupply (0), Slot 1: totalAssets (0), Slot 2: deposited (50), Slot 3: minted (50)
    vm.shadow_registers.recordSlot(0, 0, 0);
    vm.shadow_registers.recordSlot(1, 0, 0);
    vm.shadow_registers.recordSlot(2, 50_000000000000000000, 50_000000000000000000);
    vm.shadow_registers.recordSlot(3, 50_000000000000000000, 50_000000000000000000);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    dummy_cfg.is_erc4626_vault = false; // Pure 1:1 wrapper
    const res = ag.detectAGVLT01(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// --- AG-FA-01: Bridge Reserve Conservation & Nullifier Bit Set ---
test "AG-FA-01-TP: StateDelta: Asset claimed without setting nullifier in claimedBitMap" {
    var vm = vm_mod.VM.init();
    // Shadow Registers:
    // Slot 0: globalIndex (100)
    // Slot 1: nullifier_pre (0)
    // Slot 2: nullifier_post (0 - FAIL! not flipped)
    // Slot 3: amount_released (1000 WETH)
    vm.shadow_registers.recordSlot(0, 100, 100);
    vm.shadow_registers.recordSlot(1, 0, 0);
    vm.shadow_registers.recordSlot(2, 0, 0);
    vm.shadow_registers.recordSlot(3, 1000_000000000000000000, 1000_000000000000000000);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGFA01(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "AG-FA-01-TN: StateDelta: Nullifier bit atomically flipped from 0 to 1 during asset claim" {
    var vm = vm_mod.VM.init();
    // Shadow Registers:
    // Slot 0: globalIndex (100)
    // Slot 1: nullifier_pre (0)
    // Slot 2: nullifier_post (1 - SUCCESS! flipped)
    // Slot 3: amount_released (1000 WETH)
    vm.shadow_registers.recordSlot(0, 100, 100);
    vm.shadow_registers.recordSlot(1, 0, 0);
    vm.shadow_registers.recordSlot(2, 1, 1);
    vm.shadow_registers.recordSlot(3, 1000_000000000000000000, 1000_000000000000000000);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGFA01(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// --- AG-CB-02: Cross-Chain Domain Isolation ---
test "AG-CB-02-TP: StateDelta: Message intended for Chain 1 claimed on Chain 2" {
    var vm = vm_mod.VM.init();
    // Shadow Registers:
    // Slot 0: leaf destinationNetwork (1)
    // Slot 1: bridge networkID (2)
    // Slot 2: execution allowed (1)
    vm.shadow_registers.recordSlot(0, 1, 1);
    vm.shadow_registers.recordSlot(1, 2, 2);
    vm.shadow_registers.recordSlot(2, 1, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGCB02(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 9), res.severity);
}

test "AG-CB-02-TN: StateDelta: Bridge strictly enforces destinationNetwork == networkID" {
    var vm = vm_mod.VM.init();
    // Shadow Registers:
    // Slot 0: leaf destinationNetwork (1)
    // Slot 1: bridge networkID (1)
    // Slot 2: execution allowed (1)
    vm.shadow_registers.recordSlot(0, 1, 1);
    vm.shadow_registers.recordSlot(1, 1, 1);
    vm.shadow_registers.recordSlot(2, 1, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGCB02(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// --- AG-CB-04: Rollup State Root Freshness & Emergency State ---
test "AG-CB-04-TP: StateDelta: Pessimistic proof accepted against zero L1 info root" {
    var vm = vm_mod.VM.init();
    // Shadow Registers:
    // Slot 0: l1InfoTreeRoot (0 - invalid)
    // Slot 1: emergencyState (0)
    // Slot 2: stateTransitionExecuted (1 - executed)
    vm.shadow_registers.recordSlot(0, 0, 0);
    vm.shadow_registers.recordSlot(1, 0, 0);
    vm.shadow_registers.recordSlot(2, 1, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGCB04(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 9), res.severity);
}

test "AG-CB-04-TN: StateDelta: State transition verified with valid L1InfoRoot outside emergency state" {
    var vm = vm_mod.VM.init();
    // Shadow Registers:
    // Slot 0: l1InfoTreeRoot (0xABCD1234)
    // Slot 1: emergencyState (0)
    // Slot 2: stateTransitionExecuted (1)
    vm.shadow_registers.recordSlot(0, 0xABCD1234, 0xABCD1234);
    vm.shadow_registers.recordSlot(1, 0, 0);
    vm.shadow_registers.recordSlot(2, 1, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGCB04(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}
