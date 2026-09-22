//! test_009_paxos_compositional.zig: Concrete State-Delta Test Suite for Paxos Compositional Detectors
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const testing = std.testing;
const types = @import("types.zig");
const vm_mod = @import("vm.zig");
const cfg_mod = @import("cfg.zig");
const px = @import("detectors_paxos_compositional.zig");

// ============================================================================
// PX-DIAMOND-01: EIP-2535 Facet Selector Collision Tests
// ============================================================================

test "PX-DIAMOND-01-TP: StateDelta: Duplicate selector across distinct facets triggers collision finding" {
    var vm = vm_mod.VM.init();
    
    // Selector: 0xa9059cbb (transfer(address,uint256))
    const selector: u256 = 0xa9059cbb;
    const facet_a: u256 = 0x1111111111111111111111111111111111111111;
    const facet_b: u256 = 0x2222222222222222222222222222222222222222;

    // Record both facets claiming the identical selector
    vm.shadow_registers.recordSlot(0, selector, facet_a);
    vm.shadow_registers.recordSlot(1, selector, facet_b);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = px.detectPXDiamond01(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "PX-DIAMOND-01-TN: StateDelta: Distinct disjoint selectors across facets pass cleanly" {
    var vm = vm_mod.VM.init();
    
    const sel_transfer: u256 = 0xa9059cbb;
    const sel_approve: u256 = 0x095ea7b3;
    const facet_ext: u256 = 0x1111111111111111111111111111111111111111;
    const facet_admin: u256 = 0x2222222222222222222222222222222222222222;

    vm.shadow_registers.recordSlot(0, sel_transfer, facet_ext);
    vm.shadow_registers.recordSlot(1, sel_approve, facet_admin);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = px.detectPXDiamond01(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// ============================================================================
// PX-RATE-01: Token Bucket Rate Limiter Truncation & Exhaustion Tests
// ============================================================================

test "PX-RATE-01-TP: StateDelta: Rate limit bucket drained with zero refill rate triggers DoS finding" {
    var vm = vm_mod.VM.init();
    const dummy_addr = vm.cheatcodes.current_address;
    const slot_bucket: [32]u8 = [_]u8{0} ** 32;

    const pre_val = types.U256.fromNative(1_000_000_000_000).toBytes(); // 1M tokens
    const post_val = types.U256.fromNative(0).toBytes(); // 0 tokens (drained)

    vm.delta_journal.recordSSTORE(dummy_addr, slot_bucket, pre_val, post_val, 1);

    // Shadow registers: Slot 0 = refillPerSecond (0), Slot 1 = limitCapacity (1M)
    vm.shadow_registers.recordSlot(0, 0, 0);
    vm.shadow_registers.recordSlot(1, 1_000_000_000_000, 1_000_000_000_000);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = px.detectPXRate01(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 8), res.severity);
}

test "PX-RATE-01-TN: StateDelta: Healthy rate limiter refills with normal capacity" {
    var vm = vm_mod.VM.init();
    const dummy_addr = vm.cheatcodes.current_address;
    const slot_bucket: [32]u8 = [_]u8{0} ** 32;

    const pre_val = types.U256.fromNative(1_000_000_000_000).toBytes();
    const post_val = types.U256.fromNative(500_000_000_000).toBytes();

    vm.delta_journal.recordSSTORE(dummy_addr, slot_bucket, pre_val, post_val, 1);

    // Shadow registers: Slot 0 = refillPerSecond (10,000/s), Slot 1 = limitCapacity (1M)
    vm.shadow_registers.recordSlot(0, 10_000_000_000, 10_000_000_000);
    vm.shadow_registers.recordSlot(1, 1_000_000_000_000, 1_000_000_000_000);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = px.detectPXRate01(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// ============================================================================
// PX-FREEZE-01: Legacy Frozen Mapping Reentrancy Tests
// ============================================================================

test "PX-FREEZE-01-TP: CallFrame: External call occurs prior to Slot 7 freeze check" {
    var vm = vm_mod.VM.init();
    const dummy_target = vm.cheatcodes.current_address;

    // Push external call frame BEFORE checking slot 7
    _ = vm.call_stack.push(.{
        .frame_id = 1,
        .parent_frame_id = 0,
        .address = dummy_target,
        .caller = vm.cheatcodes.current_address,
        .call_kind = .call,
        .flags = 0,
    });

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = px.detectPXFreeze01(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 9), res.severity);
}

test "PX-FREEZE-01-TN: CallFrame: Slot 7 freeze verification strictly precedes external call" {
    var vm = vm_mod.VM.init();
    const dummy_target = vm.cheatcodes.current_address;

    // Push frame where Slot 7 was verified (flags & 0x04)
    _ = vm.call_stack.push(.{
        .frame_id = 1,
        .parent_frame_id = 0,
        .address = dummy_target,
        .caller = vm.cheatcodes.current_address,
        .call_kind = .call,
        .flags = 0x04,
    });

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = px.detectPXFreeze01(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}
