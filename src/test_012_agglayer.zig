//! test_012_agglayer.zig: Formal Invariant Acceptance Test Suite for Agglayer & Vault Bridge
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const testing = std.testing;
const types = @import("types.zig");
const vm_mod = @import("vm.zig");
const cfg_mod = @import("cfg.zig");
const ag = @import("detectors_agglayer.zig");

// ============================================================================
// 1. AG-CONS-01: Pessimistic Consensus Balance Invariant & Root Settlement
// ============================================================================

test "AG-CONS-01-TP: StateDelta: Imported exits exceed available mesh balance during verifyBatches" {
    var vm = vm_mod.VM.init();
    // Shadow Registers:
    // Slot 0: importedExits (5,000 WETH)
    // Slot 1: exportedDeposits (10,000 WETH)
    // Slot 2: localClaims (7,000 WETH) -> Available mesh liquidity = 3,000 WETH
    // Slot 3: newLocalExitRootSettled (1 = true)
    // 5,000 > 3,000 -> Insolvency breach!
    vm.shadow_registers.recordSlot(0, 5000_000000000000000000, 5000_000000000000000000);
    vm.shadow_registers.recordSlot(1, 10000_000000000000000000, 10000_000000000000000000);
    vm.shadow_registers.recordSlot(2, 7000_000000000000000000, 7000_000000000000000000);
    vm.shadow_registers.recordSlot(3, 1, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGCONS01(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "AG-CONS-01-TN: StateDelta: Imported exits within available mesh deposits satisfies solvency" {
    var vm = vm_mod.VM.init();
    // Shadow Registers:
    // Slot 0: importedExits (2,000 WETH)
    // Slot 1: exportedDeposits (10,000 WETH)
    // Slot 2: localClaims (7,000 WETH) -> Available mesh liquidity = 3,000 WETH
    // Slot 3: newLocalExitRootSettled (1 = true)
    // 2,000 <= 3,000 -> Fully solvent
    vm.shadow_registers.recordSlot(0, 2000_000000000000000000, 2000_000000000000000000);
    vm.shadow_registers.recordSlot(1, 10000_000000000000000000, 10000_000000000000000000);
    vm.shadow_registers.recordSlot(2, 7000_000000000000000000, 7000_000000000000000000);
    vm.shadow_registers.recordSlot(3, 1, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGCONS01(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// ============================================================================
// 2. AG-FA-01: Nullifier Bit Atomic Setting & Conservation
// ============================================================================

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
    vm.shadow_registers.recordSlot(0, 100, 100);
    vm.shadow_registers.recordSlot(1, 0, 0);
    vm.shadow_registers.recordSlot(2, 1, 1);
    vm.shadow_registers.recordSlot(3, 1000_000000000000000000, 1000_000000000000000000);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGFA01(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// ============================================================================
// 3. AG-FA-02: claimedBitMap Word-Boundary Aliasing & Dirty Index Overflow
// ============================================================================

test "AG-FA-02-TP: Certora Blindspot: Index exceeds 32-bit boundary but executed claim" {
    var vm = vm_mod.VM.init();
    // Raw leaf index: 2^32 + 5 (0x1_0000_0005)
    // Word key: 0x1000000 (dirty high-order bits)
    // Bit pos: 5
    // Claim executed = 1
    vm.shadow_registers.recordSlot(0, 0x1_0000_0005, 0x1_0000_0005);
    vm.shadow_registers.recordSlot(1, 0x100_0000, 0x100_0000);
    vm.shadow_registers.recordSlot(2, 5, 5);
    vm.shadow_registers.recordSlot(3, 1, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGFA02(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "AG-FA-02-TN: Bit alignment strictly matches 32-bit leaf index" {
    var vm = vm_mod.VM.init();
    // Valid 32-bit index: 517 -> word key: 2, bit pos: 5 (2 * 256 + 5 = 517)
    vm.shadow_registers.recordSlot(0, 517, 517);
    vm.shadow_registers.recordSlot(1, 2, 2);
    vm.shadow_registers.recordSlot(2, 5, 5);
    vm.shadow_registers.recordSlot(3, 1, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGFA02(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// ============================================================================
// 4. AG-CB-02: Cross-Chain Domain Isolation & Replay Protection
// ============================================================================

test "AG-CB-02-TP: StateDelta: Message intended for Chain 1 claimed on Chain 2" {
    var vm = vm_mod.VM.init();
    // destinationNetwork in leaf = 1 (Ethereum Mainnet)
    // networkID of executing bridge = 2 (Polygon zkEVM)
    // execution allowed = 1 -> FAIL!
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
    vm.shadow_registers.recordSlot(0, 2, 2);
    vm.shadow_registers.recordSlot(1, 2, 2);
    vm.shadow_registers.recordSlot(2, 1, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGCB02(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// ============================================================================
// 5. AG-VLT-01: Vault Bridge Share Decoupling & Certora Blindspot (Line 121)
// ============================================================================

test "AG-VLT-01-TP: Certora Blindspot Line 121: Direct donation to reservedAssets causes zero shares minted on deposit" {
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

// ============================================================================
// 6. AG-CB-04: Rollup State Root Freshness & Emergency State
// ============================================================================

test "AG-CB-04-TP: StateDelta: Pessimistic proof accepted against zero L1 info root" {
    var vm = vm_mod.VM.init();
    // l1InfoTreeRoot = 0 (unregistered)
    // emergencyState = 0
    // stateTransitionExecuted = 1
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
    vm.shadow_registers.recordSlot(0, 0x1234_5678_9ABC_DEF0, 0x1234_5678_9ABC_DEF0);
    vm.shadow_registers.recordSlot(1, 0, 0);
    vm.shadow_registers.recordSlot(2, 1, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGCB04(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// ============================================================================
// 7. AG-BLIND-01: Yield Recipient Rotation Siphoning (Certora Lines 34-44)
// ============================================================================

test "AG-BLIND-01-TP: Certora Blindspot: Yield recipient address rotated while unharvested yield unaccounted" {
    var vm = vm_mod.VM.init();
    // Slot 0: unharvestedYield (500 WETH)
    // Slot 1: recipientBalanceBefore (500 WETH)
    // Slot 2: recipientBalanceAfter (0 WETH - rotated to new unbacked recipient)
    // Slot 3: recipientAddressChanged (1 = true)
    vm.shadow_registers.recordSlot(0, 500_000000000000000000, 500_000000000000000000);
    vm.shadow_registers.recordSlot(1, 500_000000000000000000, 500_000000000000000000);
    vm.shadow_registers.recordSlot(2, 0, 0);
    vm.shadow_registers.recordSlot(3, 1, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGBLIND01(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 9), res.severity);
}

test "AG-BLIND-01-TN: Yield recipient address invariant holds when balance covers yield" {
    var vm = vm_mod.VM.init();
    vm.shadow_registers.recordSlot(0, 500_000000000000000000, 500_000000000000000000);
    vm.shadow_registers.recordSlot(1, 500_000000000000000000, 500_000000000000000000);
    vm.shadow_registers.recordSlot(2, 500_000000000000000000, 500_000000000000000000);
    vm.shadow_registers.recordSlot(3, 0, 0);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGBLIND01(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// ============================================================================
// 8. AG-BLIND-02: Non-Migratable Backing Overflow (Certora Lines 48-57)
// ============================================================================

test "AG-BLIND-02-TP: Certora Blindspot: Backing on LayerY drops below non-migratable threshold during migration" {
    var vm = vm_mod.VM.init();
    // Slot 0: backingOnLayerY (400 WETH)
    // Slot 1: customTokenTotalSupply (1,000 WETH)
    // Slot 2: nonMigratablePercentage (50% = 5e17) -> Required backing = 500 WETH
    // Slot 3: migrationExecuted (1 = true)
    // 400 < 500 -> Solvency leak!
    vm.shadow_registers.recordSlot(0, 400_000000000000000000, 400_000000000000000000);
    vm.shadow_registers.recordSlot(1, 1000_000000000000000000, 1000_000000000000000000);
    vm.shadow_registers.recordSlot(2, 500_000000000000000, 500_000000000000000);
    vm.shadow_registers.recordSlot(3, 1, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGBLIND02(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "AG-BLIND-02-TN: LayerY backing satisfies non-migratable threshold" {
    var vm = vm_mod.VM.init();
    // Backing = 600 WETH >= 500 WETH required
    vm.shadow_registers.recordSlot(0, 600_000000000000000000, 600_000000000000000000);
    vm.shadow_registers.recordSlot(1, 1000_000000000000000000, 1000_000000000000000000);
    vm.shadow_registers.recordSlot(2, 500_000000000000000, 500_000000000000000);
    vm.shadow_registers.recordSlot(3, 1, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGBLIND02(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// ============================================================================
// 9. AG-BLIND-03: Delegatecall Storage Slot Clobbering (Certora Lines 17-24)
// ============================================================================

test "AG-BLIND-03-TP: Certora Blindspot: Delegatecall to VBTpart2 clobbered critical storage slot 0 or 1" {
    var vm = vm_mod.VM.init();
    // Slot 0: target address
    // Slot 1: is_part2 (1 = true)
    // Slot 2: criticalSlotOverwritten (1 = clobbered)
    // Slot 3: callSuccess (1 = executed)
    vm.shadow_registers.recordSlot(0, 0xBEEF, 0xBEEF);
    vm.shadow_registers.recordSlot(1, 1, 1);
    vm.shadow_registers.recordSlot(2, 1, 1);
    vm.shadow_registers.recordSlot(3, 1, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGBLIND03(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "AG-BLIND-03-TN: Delegatecall preserves critical storage slot boundaries" {
    var vm = vm_mod.VM.init();
    vm.shadow_registers.recordSlot(0, 0xBEEF, 0xBEEF);
    vm.shadow_registers.recordSlot(1, 1, 1);
    vm.shadow_registers.recordSlot(2, 0, 0); // Slot uncorrupted
    vm.shadow_registers.recordSlot(3, 1, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = ag.detectAGBLIND03(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}
