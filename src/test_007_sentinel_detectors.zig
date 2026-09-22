//! test_007_sentinel_detectors.zig: Master Invariant Detector Test Contract (CP, SW, CL, FA, VLT, SDT, IRM, RF, TS, CS)
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const testing = std.testing;
const types = @import("types.zig");
const vm_mod = @import("vm.zig");
const detectors = @import("detectors_v2.zig");
const cfg_mod = @import("cfg.zig");

// --- CP-01 ---
test "CP-01-TP: Output too large causing k_post < k_pre" {
    var vm = vm_mod.VM.init();
    vm.shadow_registers.recordSlot(0, 999_900, 1_000_000);
    var cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectCP01(&vm, &cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "CP-01-TN: Valid swap with fee where k_post >= k_pre" {
    var vm = vm_mod.VM.init();
    vm.shadow_registers.recordSlot(0, 1_001_000, 1_000_000);
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_constant_product_pool = true;
    cfg.has_k_invariant_check = true;
    const res = detectors.detectCP01(&vm, &cfg);
    try testing.expect(!res.found);
}

// --- CP-02 ---
test "CP-02-TP: Swap charges fee but fee accumulator does not increase" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_fee_growth_global = true;
    cfg.has_division_before_multiplication = true;
    const res = detectors.detectCP02(null, &cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 7), res.severity);
}

test "CP-02-TN: Fee accumulator increases exactly by computed fee" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_fee_growth_global = true;
    cfg.has_division_before_multiplication = false;
    const res = detectors.detectCP02(null, &cfg);
    try testing.expect(!res.found);
}

// --- SW-03 ---
test "SW-03-TP: Virtual price decreases without loss event" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_stableswap_pool = true;
    cfg.has_invariant_convergence_check = false;
    const res = detectors.detectSW03(null, &cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 9), res.severity);
}

test "SW-03-TN: Virtual price stays same or increases" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_stableswap_pool = true;
    cfg.has_invariant_convergence_check = true;
    const res = detectors.detectSW03(null, &cfg);
    try testing.expect(!res.found);
}

// --- CL-04 ---
test "CL-04-TP: Fee growth inside range is underreported" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_tick_bitmap_ops = true;
    cfg.has_tick_boundary_clamp = false;
    const res = detectors.detectCL04(null, &cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 8), res.severity);
}

test "CL-04-TN: Fee owed matches liquidity times fee growth delta" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_tick_bitmap_ops = true;
    cfg.has_tick_boundary_clamp = true;
    const res = detectors.detectCL04(null, &cfg);
    try testing.expect(!res.found);
}

// --- FA-01 ---
test "FA-01-TP: Flash loan callback ends with reserve deficit" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_flashloan_receiver = true;
    cfg.reads_spot_reserves_for_valuation = true;
    const res = detectors.detectFA01(null, &cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "FA-01-TN: Flash loan repaid with premium" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_flashloan_receiver = true;
    cfg.reads_spot_reserves_for_valuation = false;
    const res = detectors.detectFA01(null, &cfg);
    try testing.expect(!res.found);
}

// --- VLT-01 ---
test "VLT-01-TP: totalSupply == 0 and totalAssets > 0 before first mint" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.is_erc4626_vault = true;
    cfg.has_virtual_shares_offset = false;
    const res = detectors.detectVLT01(null, &cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 9), res.severity);
}

test "VLT-01-TN: First mint occurs with virtual offset protection" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.is_erc4626_vault = true;
    cfg.has_virtual_shares_offset = true;
    const res = detectors.detectVLT01(null, &cfg);
    try testing.expect(!res.found);
}

// --- VLT-02 ---
test "VLT-02-TP: Actual redeem amount is less than preview amount" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_share_to_asset_conversion = true;
    cfg.rounds_shares_down_on_redeem = true;
    const res = detectors.detectVLT02(null, &cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 8), res.severity);
}

test "VLT-02-TN: Actual redeem amount equals preview amount" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_share_to_asset_conversion = true;
    cfg.rounds_shares_down_on_redeem = false;
    const res = detectors.detectVLT02(null, &cfg);
    try testing.expect(!res.found);
}

// --- SDT-04 ---
test "SDT-04-TP: 256-bit capacity exceeds u128 max and stored value wraps" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_borrow_capacity_check = true;
    cfg.handles_borrow_overflow = false;
    const res = detectors.detectSDT04(null, &cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 7), res.severity);
}

test "SDT-04-TN: Capacity fits within u128" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.has_borrow_capacity_check = true;
    cfg.handles_borrow_overflow = true;
    const res = detectors.detectSDT04(null, &cfg);
    try testing.expect(!res.found);
}

// --- IRM-03 ---
test "IRM-03-TP: Actual borrow index drifts beyond allowed rounding tolerance" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.updates_borrow_index = true;
    cfg.allows_zero_utilization_div = true;
    const res = detectors.detectIRM03(null, &cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 7), res.severity);
}

test "IRM-03-TN: Actual index matches ideal index within tolerance" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.updates_borrow_index = true;
    cfg.allows_zero_utilization_div = false;
    const res = detectors.detectIRM03(null, &cfg);
    try testing.expect(!res.found);
}

// --- RF-01 ---
test "RF-01-TP: Protected storage write occurs after successful external call" {
    var vm = vm_mod.VM.init();
    const bytecode = [_]u8{
        0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0xAA, 0x60, 0xFF, 0xF1, // CALL
        0x60, 0x00, 0x60, 0x05, 0x55, // SSTORE
        0x00,
    };
    _ = vm.execute(&bytecode);
    var cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectRF01(&vm, &cfg);
    try testing.expect(res.found);
}

test "RF-01-TN: Protected storage write occurs before external call" {
    var vm = vm_mod.VM.init();
    const bytecode = [_]u8{
        0x60, 0x00, 0x60, 0x05, 0x55, // SSTORE
        0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0xAA, 0x60, 0xFF, 0xF1, // CALL
        0x00,
    };
    _ = vm.execute(&bytecode);
    var cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectRF01(&vm, &cfg);
    try testing.expect(!res.found);
}

// --- TS-02 ---
test "TS-02-TP: Parent sees transient value written by reverted child" {
    var vm = vm_mod.VM.init();
    const cp = vm.transient_journal.checkpoint();
    vm.transient_journal.recordTSTORE(vm.cheatcodes.current_address, [_]u8{0} ** 32, [_]u8{0} ** 32, [_]u8{0xFF} ** 32, 1);
    vm.transient_storage.tstore(0, 0xFF);
    vm.transient_journal.rollback(cp);

    var cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectTS02(&vm, &cfg);
    try testing.expect(res.found);
}

test "TS-02-TN: Reverted child transient write is discarded" {
    var vm = vm_mod.VM.init();
    const cp = vm.transient_journal.checkpoint();
    vm.transient_journal.recordTSTORE(vm.cheatcodes.current_address, [_]u8{0} ** 32, [_]u8{0} ** 32, [_]u8{0xFF} ** 32, 1);
    vm.transient_storage.tstore(0, 0xFF);
    vm.transient_storage.rollbackTo(cp);
    vm.transient_journal.rollback(cp);

    var cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectTS02(&vm, &cfg);
    try testing.expect(!res.found);
}

// --- CS-04 ---
test "CS-04-TP: afterSwap hook writes unauthorized persistent pool slot" {
    var vm = vm_mod.VM.init();
    if (vm.call_stack.current()) |frame| {
        frame.flags |= types.FRAME_IN_AFTER_SWAP;
    }
    vm.reentrancy_mask.persistent_write = true;
    var cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectCS04(&vm, &cfg);
    try testing.expect(res.found);
}

test "CS-04-TN: afterSwap hook does not write persistent state" {
    var vm = vm_mod.VM.init();
    if (vm.call_stack.current()) |frame| {
        frame.flags |= types.FRAME_IN_AFTER_SWAP;
    }
    vm.reentrancy_mask.persistent_write = false;
    var cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectCS04(&vm, &cfg);
    try testing.expect(!res.found);
}
