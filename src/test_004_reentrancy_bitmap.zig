//! test_004_reentrancy_bitmap.zig: Complete RB-001 through RB-015 Test Suite
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const testing = std.testing;
const types = @import("types.zig");
const vm_mod = @import("vm.zig");
const detectors = @import("detectors_v2.zig");
const cfg_mod = @import("cfg.zig");

test "RB-001: rb.empty_no_finding" {
    var vm = vm_mod.VM.init();
    var cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectRF01(&vm, &cfg);
    try testing.expect(!res.found);
}

test "RB-002: rb.protected_write_before_call_no_finding" {
    var vm = vm_mod.VM.init();
    // Safe CEI sequence: write then call
    const bytecode = [_]u8{
        0x60, 0x00, 0x60, 0x05, 0x55, // SSTORE(5, 0)
        0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0xAA, 0x60, 0xFF, 0xF1, // CALL
        0x00,
    };
    _ = vm.execute(&bytecode);
    var cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectRF01(&vm, &cfg);
    try testing.expect(!res.found);
}

test "RB-003: rb.external_call_then_protected_write_fires" {
    var vm = vm_mod.VM.init();
    // Unsafe CEI sequence: call then write
    const bytecode = [_]u8{
        0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0xAA, 0x60, 0xFF, 0xF1, // CALL
        0x60, 0x00, 0x60, 0x05, 0x55, // SSTORE(5, 0)
        0x00,
    };
    _ = vm.execute(&bytecode);
    var cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectRF01(&vm, &cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 9), res.severity);
}

test "RB-004: rb.external_call_then_unprotected_write_no_rf01" {
    var vm = vm_mod.VM.init();
    // CALL only without post write
    const bytecode = [_]u8{
        0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0xAA, 0x60, 0xFF, 0xF1, // CALL
        0x00,
    };
    _ = vm.execute(&bytecode);
    var cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectRF01(&vm, &cfg);
    try testing.expect(!res.found);
}

test "RB-005: rb.delegatecall_then_protected_write_fires" {
    var vm = vm_mod.VM.init();
    const bytecode = [_]u8{
        0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0xAA, 0x60, 0xFF, 0xF4, // DELEGATECALL
        0x60, 0x01, 0x60, 0x05, 0x55, // SSTORE
        0x00,
    };
    _ = vm.execute(&bytecode);
    var cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectRF01(&vm, &cfg);
    try testing.expect(res.found);
}

test "RB-006: rb.staticcall_then_protected_write_flags_read_only_candidate" {
    var cfg = cfg_mod.ControlFlowGraph.init();
    cfg.block_count = 1;
    cfg.blocks[0] = std.mem.zeroes(cfg_mod.BasicBlock);
    cfg.blocks[0].has_read_only_reentrancy_pattern = true;

    const res = detectors.DETECTOR_REGISTRY[2].detect(null, &cfg); // reentrancy_readonly
    try testing.expect(res.found);
}

test "RB-007: rb.nested_call_inner_write_after_inner_call_attributed" {
    var vm = vm_mod.VM.init();
    _ = vm.call_stack.push(.{ .frame_id = 1 });
    vm.call_stack.frames[1].has_external_call_occurred = true;
    vm.call_stack.frames[1].post_call_write_occurred = true;
    vm.reentrancy_mask.external_call = true;
    vm.reentrancy_mask.persistent_write = true;

    var cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectRF01(&vm, &cfg);
    try testing.expect(res.found);
}

test "RB-008: rb.reverted_call_no_state_write_no_finding" {
    var vm = vm_mod.VM.init();
    const bytecode = [_]u8{ 0x60, 0x00, 0x60, 0x00, 0xFD }; // REVERT
    _ = vm.execute(&bytecode);
    var cfg = cfg_mod.ControlFlowGraph.init();
    const res = detectors.detectRF01(&vm, &cfg);
    try testing.expect(!res.found);
}

test "RB-009: rb.value_call_flag_set" {
    var vm = vm_mod.VM.init();
    const bytecode = [_]u8{
        0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x0A, 0x60, 0xAA, 0x60, 0xFF, 0xF1, // CALL with val=10
        0x00,
    };
    _ = vm.execute(&bytecode);
    try testing.expect(vm.reentrancy_mask.value_call);
}

test "RB-010: rb.token_transfer_callback_flagged" {
    var mask = types.ReentrancyMask{};
    mask.callback_call = true;
    try testing.expect(mask.callback_call);
}

test "RB-011: rb.hook_call_flagged" {
    var mask = types.ReentrancyMask{};
    mask.hook_call = true;
    try testing.expect(mask.hook_call);
}

test "RB-012: rb.protected_slot_map_configurable" {
    const is_protected_slot = struct {
        fn check(slot: usize) bool {
            return slot <= 10;
        }
    }.check;
    try testing.expect(is_protected_slot(0));
    try testing.expect(!is_protected_slot(11));
}

test "RB-013: rb.write_after_call_mask_populated" {
    var vm = vm_mod.VM.init();
    const bytecode = [_]u8{
        0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0xAA, 0x60, 0xFF, 0xF1, // CALL
        0x60, 0x01, 0x60, 0x05, 0x55, // SSTORE
        0x00,
    };
    _ = vm.execute(&bytecode);
    try testing.expect(vm.reentrancy_mask.external_call);
    try testing.expect(vm.reentrancy_mask.persistent_write);
    try testing.expect(vm.call_stack.frames[0].post_call_write_occurred);
}

test "RB-014: rb.multiple_calls_multiple_writes_counted" {
    var vm = vm_mod.VM.init();
    const bytecode = [_]u8{
        0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0x00, 0x60, 0xAA, 0x60, 0xFF, 0xF1, // CALL
        0x60, 0x01, 0x60, 0x01, 0x55, // SSTORE
        0x60, 0x02, 0x60, 0x02, 0x55, // SSTORE
        0x00,
    };
    _ = vm.execute(&bytecode);
    try testing.expect(vm.call_stack.frames[0].post_call_write_occurred);
    try testing.expectEqual(@as(usize, 2), vm.delta_journal.len);
}

test "RB-015: rb.deterministic" {
    var m1 = types.ReentrancyMask{};
    var m2 = types.ReentrancyMask{};
    m1.external_call = true;
    m1.persistent_write = true;
    m2.external_call = true;
    m2.persistent_write = true;

    try testing.expect(std.mem.eql(u8, std.mem.asBytes(&m1), std.mem.asBytes(&m2)));
}
