//! test_010_pumpfun_solana.zig: Concrete State-Delta & CPI Acceptance Tests for pump.fun Detectors
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const testing = std.testing;
const types = @import("types.zig");
const vm_mod = @import("vm.zig");
const vm_solana = @import("vm_solana.zig");
const pf = @import("detectors_pumpfun.zig");

// ============================================================================
// SVM ADAPTER INTEGRATION TESTS
// ============================================================================

test "SVM-001: Solana VM Adapter Account Initialization & Borsh Serialization" {
    var svm = vm_solana.SolanaVMAdapter.init();
    
    var acc = vm_solana.SolanaAccount{};
    acc.pubkey = [_]u8{0xAA} ** 32;
    acc.owner = [_]u8{0x6E} ** 32;
    acc.lamports = 10_000_000_000; // 10 SOL

    // Write bonding curve reserves: virtual_token_reserves (u64), virtual_sol_reserves (u64)
    acc.writeU64(0, 1_073_000_000_000_000);
    acc.writeU64(8, 30_000_000_000);

    const idx = svm.addAccount(acc);
    try testing.expectEqual(@as(usize, 0), idx);

    const fetched = svm.getAccount(acc.pubkey).?;
    try testing.expectEqual(@as(u64, 1_073_000_000_000_000), fetched.readU64(0));
    try testing.expectEqual(@as(u64, 30_000_000_000), fetched.readU64(8));
}

test "SVM-002: Solana CPI Frame Stack Push & Pop" {
    var svm = vm_solana.SolanaVMAdapter.init();

    const program_a = [_]u8{0x11} ** 32;
    const program_b = [_]u8{0x22} ** 32;
    const seeds = [_][]const u8{ "bonding-curve", "mint" };

    try testing.expect(svm.pushCpi(program_b, program_a, &seeds, 254));
    try testing.expectEqual(@as(usize, 1), svm.cpi_depth);
    try testing.expectEqual(@as(u8, 254), svm.cpi_stack[0].bump);
    try testing.expect(svm.cpi_stack[0].is_pda);

    svm.popCpi();
    try testing.expectEqual(@as(usize, 0), svm.cpi_depth);
}

// ============================================================================
// PF-01: Bonding Curve Virtual Reserve Integrity Tests
// ============================================================================

test "PF-01-TP: StateDelta: Constant product k decreases after swap" {
    var vm = vm_mod.VM.init();
    const svm = vm_solana.SolanaVMAdapter.init();

    // Initial k_0 = 30,000 * 1,073,000 = 32,190,000,000
    // Post swap k_post = 30,000,000,000 (k decreased!)
    vm.shadow_registers.recordSlot(0, 32_190_000_000, 32_190_000_000);
    vm.shadow_registers.recordSlot(1, 30_000_000_000, 30_000_000_000);

    const res = pf.detectPF01(&vm, &svm);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "PF-01-TN: StateDelta: Constant product k increases with fee accumulation" {
    var vm = vm_mod.VM.init();
    const svm = vm_solana.SolanaVMAdapter.init();

    // Initial k_0 = 32,190,000,000
    // Post swap k_post = 32,200,000,000 (k increased)
    vm.shadow_registers.recordSlot(0, 32_190_000_000, 32_190_000_000);
    vm.shadow_registers.recordSlot(1, 32_200_000_000, 32_200_000_000);

    const res = pf.detectPF01(&vm, &svm);
    try testing.expect(!res.found);
}

// ============================================================================
// PF-02: Migration LP Burn Atomicity Tests
// ============================================================================

test "PF-02-TP: StateDelta: Bonding curve marked complete without LP token burn" {
    var vm = vm_mod.VM.init();
    const svm = vm_solana.SolanaVMAdapter.init();
    const dummy_addr = vm.cheatcodes.current_address;
    const slot_complete: [32]u8 = [_]u8{0} ** 32;

    const pre_val = types.U256.fromNative(0).toBytes(); // complete = false
    const post_val = types.U256.fromNative(1).toBytes(); // complete = true

    // Flag 0x01 = complete set, but missing flag 0x02 (LP burn)
    vm.delta_journal.recordSSTORE(dummy_addr, slot_complete, pre_val, post_val, 1);
    vm.delta_journal.entries[0].flags |= 0x01;

    const res = pf.detectPF02(&vm, &svm);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "PF-02-TN: StateDelta: Migration executes atomic LP token burn" {
    var vm = vm_mod.VM.init();
    const svm = vm_solana.SolanaVMAdapter.init();
    const dummy_addr = vm.cheatcodes.current_address;
    const slot_complete: [32]u8 = [_]u8{0} ** 32;

    const pre_val = types.U256.fromNative(0).toBytes();
    const post_val = types.U256.fromNative(1).toBytes();

    // Flag 0x01 = complete set, Flag 0x02 = LP burn verified
    vm.delta_journal.recordSSTORE(dummy_addr, slot_complete, pre_val, post_val, 1);
    vm.delta_journal.entries[0].flags |= 0x03;

    const res = pf.detectPF02(&vm, &svm);
    try testing.expect(!res.found);
}

// ============================================================================
// PF-03: Dynamic Fee Tier Boundary Precision Tests
// ============================================================================

test "PF-03-TP: Shadow: Fee tier discrepancy across market cap boundary" {
    var vm = vm_mod.VM.init();
    const svm = vm_solana.SolanaVMAdapter.init();

    // Slot 0: MarketCap (100 SOL), Slot 1: Tier (100 SOL), Slot 2: Charged (50 bps), Slot 3: Expected (100 bps)
    vm.shadow_registers.recordSlot(0, 100_000_000_000, 100_000_000_000);
    vm.shadow_registers.recordSlot(1, 100_000_000_000, 100_000_000_000);
    vm.shadow_registers.recordSlot(2, 50, 50); // Undercharged 50 bps
    vm.shadow_registers.recordSlot(3, 100, 100);

    const res = pf.detectPF03(&vm, &svm);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 8), res.severity);
}

test "PF-03-TN: Shadow: Correct fee tier charged matching market cap schedule" {
    var vm = vm_mod.VM.init();
    const svm = vm_solana.SolanaVMAdapter.init();

    vm.shadow_registers.recordSlot(0, 100_000_000_000, 100_000_000_000);
    vm.shadow_registers.recordSlot(1, 100_000_000_000, 100_000_000_000);
    vm.shadow_registers.recordSlot(2, 100, 100);
    vm.shadow_registers.recordSlot(3, 100, 100);

    const res = pf.detectPF03(&vm, &svm);
    try testing.expect(!res.found);
}

// ============================================================================
// PF-04: Creator Vault PDA Authority Spoofing Tests
// ============================================================================

test "PF-04-TP: CPI: Invalid creator vault bump seed in CPI invocation" {
    var vm = vm_mod.VM.init();
    var svm = vm_solana.SolanaVMAdapter.init();

    const program_id = [_]u8{0x6E} ** 32;
    const seeds = [_][]const u8{ "creator-vault", "creator_pubkey" };

    // Invalid bump 0xFF
    _ = svm.pushCpi(program_id, program_id, &seeds, 0xFF);

    const res = pf.detectPF04(&vm, &svm);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 9), res.severity);
}

test "PF-04-TN: CPI: Valid canonical PDA bump and creator vault signer" {
    var vm = vm_mod.VM.init();
    var svm = vm_solana.SolanaVMAdapter.init();

    const program_id = [_]u8{0x6E} ** 32;
    const seeds = [_][]const u8{ "creator-vault", "creator_pubkey" };

    // Canonical bump 254
    _ = svm.pushCpi(program_id, program_id, &seeds, 254);

    const res = pf.detectPF04(&vm, &svm);
    try testing.expect(!res.found);
}
