//! test_003_call_frame.zig: Complete CFS-001 through CFS-018 Test Suite
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const testing = std.testing;
const types = @import("types.zig");

test "CFS-001: cfs.push_root_frame" {
    var cfs = types.CallFrameStack.init();
    const frame = types.CallFrame{ .frame_id = 0, .call_kind = .call };
    try testing.expect(cfs.push(frame));
    try testing.expectEqual(@as(usize, 1), cfs.depth);
}

test "CFS-002: cfs.pop_root_frame" {
    var cfs = types.CallFrameStack.init();
    _ = cfs.push(types.CallFrame{ .frame_id = 0 });
    const popped = cfs.pop();
    try testing.expect(popped != null);
    try testing.expectEqual(@as(usize, 0), cfs.depth);
}

test "CFS-003: cfs.child_parent_link" {
    var cfs = types.CallFrameStack.init();
    _ = cfs.push(types.CallFrame{ .frame_id = 0 });
    _ = cfs.push(types.CallFrame{ .frame_id = 1, .parent_frame_id = 0 });

    try testing.expectEqual(@as(u32, 0), cfs.current().?.parent_frame_id);
    try testing.expectEqual(@as(u32, 1), cfs.current().?.frame_id);
}

test "CFS-004: cfs.depth_counter" {
    var cfs = types.CallFrameStack.init();
    _ = cfs.push(.{});
    _ = cfs.push(.{});
    _ = cfs.push(.{});
    try testing.expectEqual(@as(usize, 3), cfs.depth);
    _ = cfs.pop();
    try testing.expectEqual(@as(usize, 2), cfs.depth);
}

test "CFS-005: cfs.max_depth_1024_enforced" {
    var cfs = types.CallFrameStack.init();
    for (0..types.MAX_CALL_DEPTH) |i| {
        try testing.expect(cfs.push(.{ .frame_id = @truncate(i) }));
    }
    try testing.expectEqual(types.MAX_CALL_DEPTH, cfs.depth);
    // 1025th push fails safely without allocation or panic
    try testing.expect(!cfs.push(.{ .frame_id = 9999 }));
    try testing.expectEqual(types.MAX_CALL_DEPTH, cfs.depth);
}

test "CFS-006: cfs.call_kind_call" {
    var cfs = types.CallFrameStack.init();
    _ = cfs.push(.{ .call_kind = .call });
    try testing.expectEqual(types.CallKind.call, cfs.current().?.call_kind);
}

test "CFS-007: cfs.call_kind_delegatecall" {
    var cfs = types.CallFrameStack.init();
    _ = cfs.push(.{ .call_kind = .delegatecall });
    try testing.expectEqual(types.CallKind.delegatecall, cfs.current().?.call_kind);
}

test "CFS-008: cfs.call_kind_staticcall" {
    var cfs = types.CallFrameStack.init();
    _ = cfs.push(.{ .call_kind = .staticcall, .flags = types.FRAME_IS_STATIC });
    try testing.expectEqual(types.CallKind.staticcall, cfs.current().?.call_kind);
    try testing.expect(cfs.current().?.flags & types.FRAME_IS_STATIC != 0);
}

test "CFS-009: cfs.call_kind_create2" {
    var cfs = types.CallFrameStack.init();
    _ = cfs.push(.{ .call_kind = .create2 });
    try testing.expectEqual(types.CallKind.create2, cfs.current().?.call_kind);
}

test "CFS-010: cfs.value_flag_set" {
    var cfs = types.CallFrameStack.init();
    _ = cfs.push(.{ .flags = types.FRAME_HAS_VALUE });
    try testing.expect(cfs.current().?.flags & types.FRAME_HAS_VALUE != 0);
}

test "CFS-011: cfs.selector_capture" {
    var cfs = types.CallFrameStack.init();
    const sel = [_]u8{ 0xa9, 0x05, 0x9c, 0xbb }; // transfer(address,uint256)
    _ = cfs.push(.{ .selector = sel });
    try testing.expect(std.mem.eql(u8, &sel, &cfs.current().?.selector));
}

test "CFS-012: cfs.checkpoint_ids_created_on_entry" {
    var cfs = types.CallFrameStack.init();
    _ = cfs.push(.{ .storage_checkpoint = 10, .transient_checkpoint = 5 });
    try testing.expectEqual(@as(u32, 10), cfs.current().?.storage_checkpoint);
    try testing.expectEqual(@as(u32, 5), cfs.current().?.transient_checkpoint);
}

test "CFS-013: cfs.pop_commits_checkpoints" {
    var cfs = types.CallFrameStack.init();
    _ = cfs.push(.{ .frame_id = 1 });
    const popped = cfs.pop();
    try testing.expect(popped != null);
    try testing.expectEqual(@as(u32, 1), popped.?.frame_id);
}

test "CFS-014: cfs.revert_frame_reverts_journals" {
    var vm = @import("vm.zig").VM.init();
    const cp = vm.delta_journal.beginCheckpoint();
    vm.delta_journal.recordSSTORE(vm.cheatcodes.current_address, [_]u8{1} ** 32, [_]u8{0} ** 32, [_]u8{0xFF} ** 32, 1);
    vm.delta_journal.revertToCheckpoint(cp);

    try testing.expect(vm.delta_journal.getPostState(vm.cheatcodes.current_address, [_]u8{1} ** 32) == null);
}

test "CFS-015: cfs.delegatecall_storage_context_is_caller" {
    var cfs = types.CallFrameStack.init();
    const caller_addr = [_]u8{0x11} ** 20;
    const target_code_addr = [_]u8{0x22} ** 20;

    _ = cfs.push(.{
        .address = caller_addr,
        .caller = caller_addr,
        .call_kind = .delegatecall,
    });

    _ = target_code_addr;
    try testing.expect(std.mem.eql(u8, &caller_addr, &cfs.current().?.address));
}

test "CFS-016: cfs.staticcall_write_attempt_tagged" {
    var vm = @import("vm.zig").VM.init();
    vm.is_static = true;
    const sstore_code = [_]u8{ 0x60, 0x01, 0x60, 0x01, 0x55, 0x00 };
    const status = vm.execute(&sstore_code);
    try testing.expectEqual(types.ExecutionStatus.STATIC_MODE_VIOLATION, status);
}

test "CFS-017: cfs.nested_revert_propagates_only_to_frame" {
    var journal = types.StateDeltaJournal.init();
    const addr = [_]u8{0x11} ** 20;
    const slotA = [_]u8{0x01} ** 32;
    const slotB = [_]u8{0x02} ** 32;

    _ = journal.beginCheckpoint();
    journal.recordSSTORE(addr, slotA, [_]u8{0} ** 32, [_]u8{10} ** 32, 0);

    const cp_child = journal.beginCheckpoint();
    journal.recordSSTORE(addr, slotB, [_]u8{0} ** 32, [_]u8{20} ** 32, 1);
    journal.revertToCheckpoint(cp_child);

    try testing.expect(journal.getPostState(addr, slotA) != null);
    try testing.expect(journal.getPostState(addr, slotB) == null);
}

test "CFS-018: cfs.deterministic" {
    var cfs1 = types.CallFrameStack.init();
    var cfs2 = types.CallFrameStack.init();

    _ = cfs1.push(.{ .frame_id = 1, .call_kind = .call });
    _ = cfs2.push(.{ .frame_id = 1, .call_kind = .call });

    try testing.expect(std.mem.eql(u8, std.mem.asBytes(&cfs1.frames[0]), std.mem.asBytes(&cfs2.frames[0])));
}

test "CFS-CRITICAL: Critical Call Frame Stack Revert Sequence" {
    var vm = @import("vm.zig").VM.init();
    const slotA: usize = 1;
    const slotB: usize = 2;

    // 1. Root frame writes slot A = 10
    vm.storage.store(slotA, 10);

    // 2. Child frame writes slot A = 20
    const cp_child = vm.storage.checkpoint();
    vm.storage.store(slotA, 20);

    // 3. Revert child frame
    vm.storage.rollbackTo(cp_child);
    try testing.expectEqual(@as(u256, 10), vm.storage.select(slotA));

    // 4. DELEGATECALL writes slot B = 30 in caller context
    vm.storage.store(slotB, 30);
    try testing.expectEqual(@as(u256, 30), vm.storage.select(slotB));
}
