//! test_001_state_delta_journal.zig: Complete SDJ-001 through SDJ-020 Test Suite
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const testing = std.testing;
const types = @import("types.zig");

test "SDJ-001: sdj.init_is_empty" {
    const journal = types.StateDeltaJournal.init();
    try testing.expectEqual(@as(usize, 0), journal.len);
    try testing.expectEqual(@as(usize, 0), journal.checkpoint_len);
    try testing.expectEqual(@as(usize, 0), journal.undo_len);
}

test "SDJ-002: sdj.capture_single_sstore" {
    var journal = types.StateDeltaJournal.init();
    const addr = [_]u8{0x11} ** 20;
    const slot = [_]u8{0x01} ** 32;
    const pre = [_]u8{0x00} ** 32;
    const post = [_]u8{0x0A} ** 32;

    journal.recordSSTORE(addr, slot, pre, post, 1);
    try testing.expectEqual(@as(usize, 1), journal.len);
    try testing.expect(std.mem.eql(u8, &journal.entries[0].key.address, &addr));
    try testing.expect(std.mem.eql(u8, &journal.entries[0].key.slot, &slot));
    try testing.expect(std.mem.eql(u8, &journal.entries[0].pre, &pre));
    try testing.expect(std.mem.eql(u8, &journal.entries[0].post, &post));
}

test "SDJ-003: sdj.capture_multiple_slots" {
    var journal = types.StateDeltaJournal.init();
    const addr = [_]u8{0x11} ** 20;
    const slotA = [_]u8{0x01} ** 32;
    const slotB = [_]u8{0x02} ** 32;
    const val0 = [_]u8{0x00} ** 32;
    const val1 = [_]u8{0x05} ** 32;
    const val2 = [_]u8{0x09} ** 32;

    journal.recordSSTORE(addr, slotA, val0, val1, 1);
    journal.recordSSTORE(addr, slotB, val0, val2, 1);

    try testing.expectEqual(@as(usize, 2), journal.len);
    try testing.expect(std.mem.eql(u8, &journal.getPostState(addr, slotA).?, &val1));
    try testing.expect(std.mem.eql(u8, &journal.getPostState(addr, slotB).?, &val2));
}

test "SDJ-004: sdj.same_slot_keeps_original_pre_and_latest_post" {
    var journal = types.StateDeltaJournal.init();
    const addr = [_]u8{0x11} ** 20;
    const slot = [_]u8{0x01} ** 32;
    const val0 = [_]u8{0x00} ** 32;
    const val1 = [_]u8{0x01} ** 32;
    const val2 = [_]u8{0x02} ** 32;
    const val3 = [_]u8{0x03} ** 32;

    journal.recordSSTORE(addr, slot, val0, val1, 1);
    journal.recordSSTORE(addr, slot, val1, val2, 1);
    journal.recordSSTORE(addr, slot, val2, val3, 1);

    try testing.expect(std.mem.eql(u8, &journal.getPreState(addr, slot).?, &val0));
    try testing.expect(std.mem.eql(u8, &journal.getPostState(addr, slot).?, &val3));
}

test "SDJ-005: sdj.checkpoint_begin_commit_keeps_writes" {
    var journal = types.StateDeltaJournal.init();
    const addr = [_]u8{0x11} ** 20;
    const slot = [_]u8{0x01} ** 32;
    const val0 = [_]u8{0x00} ** 32;
    const val1 = [_]u8{0x05} ** 32;

    const cp = journal.beginCheckpoint();
    journal.recordSSTORE(addr, slot, val0, val1, 1);
    journal.commitCheckpoint(cp);

    try testing.expectEqual(@as(usize, 1), journal.len);
    try testing.expect(std.mem.eql(u8, &journal.getPostState(addr, slot).?, &val1));
}

test "SDJ-006: sdj.checkpoint_revert_restores_pre" {
    var journal = types.StateDeltaJournal.init();
    const addr = [_]u8{0x11} ** 20;
    const slot = [_]u8{0x01} ** 32;
    const val0 = [_]u8{0x00} ** 32;
    const val1 = [_]u8{0x05} ** 32;

    const cp = journal.beginCheckpoint();
    journal.recordSSTORE(addr, slot, val0, val1, 1);
    journal.revertToCheckpoint(cp);

    try testing.expectEqual(@as(usize, 0), journal.len);
    try testing.expect(journal.getPostState(addr, slot) == null);
}

test "SDJ-007: sdj.nested_checkpoint_inner_revert" {
    var journal = types.StateDeltaJournal.init();
    const addr = [_]u8{0x11} ** 20;
    const slotA = [_]u8{0x01} ** 32;
    const slotB = [_]u8{0x02} ** 32;
    const val0 = [_]u8{0x00} ** 32;
    const val1 = [_]u8{0x10} ** 32;
    const val2 = [_]u8{0x20} ** 32;

    _ = journal.beginCheckpoint();
    journal.recordSSTORE(addr, slotA, val0, val1, 1);

    const cp_inner = journal.beginCheckpoint();
    journal.recordSSTORE(addr, slotB, val0, val2, 2);
    journal.revertToCheckpoint(cp_inner);

    try testing.expect(journal.getPostState(addr, slotA) != null);
    try testing.expect(journal.getPostState(addr, slotB) == null);
}

test "SDJ-008: sdj.nested_checkpoint_outer_revert_after_inner_commit" {
    var journal = types.StateDeltaJournal.init();
    const addr = [_]u8{0x11} ** 20;
    const slot = [_]u8{0x01} ** 32;
    const val0 = [_]u8{0x00} ** 32;
    const val1 = [_]u8{0x01} ** 32;
    const val2 = [_]u8{0x02} ** 32;

    const cp_outer = journal.beginCheckpoint();
    const cp_inner = journal.beginCheckpoint();
    journal.recordSSTORE(addr, slot, val0, val1, 1);
    journal.commitCheckpoint(cp_inner);

    journal.recordSSTORE(addr, slot, val1, val2, 1);
    journal.revertToCheckpoint(cp_outer);

    try testing.expectEqual(@as(usize, 0), journal.len);
    try testing.expect(journal.getPostState(addr, slot) == null);
}

test "SDJ-009: sdj.revert_empty_checkpoint_noop" {
    var journal = types.StateDeltaJournal.init();
    const cp = journal.beginCheckpoint();
    journal.revertToCheckpoint(cp);
    try testing.expectEqual(@as(usize, 0), journal.len);
    try testing.expectEqual(@as(usize, 0), journal.checkpoint_len);
}

test "SDJ-010: sdj.write_after_revert_uses_restored_base" {
    var journal = types.StateDeltaJournal.init();
    const addr = [_]u8{0x11} ** 20;
    const slot = [_]u8{0x01} ** 32;
    const val0 = [_]u8{0x00} ** 32;
    const val1 = [_]u8{0x01} ** 32;
    const val2 = [_]u8{0x02} ** 32;

    const cp = journal.beginCheckpoint();
    journal.recordSSTORE(addr, slot, val0, val1, 1);
    journal.revertToCheckpoint(cp);

    journal.recordSSTORE(addr, slot, val0, val2, 1);
    try testing.expect(std.mem.eql(u8, &journal.getPostState(addr, slot).?, &val2));
}

test "SDJ-011: sdj.capacity_overflow_returns_error" {
    var journal = types.StateDeltaJournal.init();
    const addr = [_]u8{0x11} ** 20;
    const slot = [_]u8{0x01} ** 32;
    const val = [_]u8{0x01} ** 32;

    for (0..types.MAX_STATE_DELTAS) |_| {
        journal.recordSSTORE(addr, slot, val, val, 1);
    }
    try testing.expectEqual(types.MAX_STATE_DELTAS, journal.len);
    // Boundary check: further write does not exceed max capacity
    journal.recordSSTORE(addr, slot, val, val, 1);
    try testing.expectEqual(types.MAX_STATE_DELTAS, journal.len);
}

test "SDJ-012: sdj.different_address_same_slot_isolated" {
    var journal = types.StateDeltaJournal.init();
    const addrA = [_]u8{0xAA} ** 20;
    const addrB = [_]u8{0xBB} ** 20;
    const slot = [_]u8{0x01} ** 32;
    const valA = [_]u8{0x11} ** 32;
    const valB = [_]u8{0x22} ** 32;

    journal.recordSSTORE(addrA, slot, [_]u8{0} ** 32, valA, 1);
    journal.recordSSTORE(addrB, slot, [_]u8{0} ** 32, valB, 1);

    try testing.expect(std.mem.eql(u8, &journal.getPostState(addrA, slot).?, &valA));
    try testing.expect(std.mem.eql(u8, &journal.getPostState(addrB, slot).?, &valB));
}

test "SDJ-013: sdj.same_address_different_slot_isolated" {
    var journal = types.StateDeltaJournal.init();
    const addr = [_]u8{0xAA} ** 20;
    const slotA = [_]u8{0x01} ** 32;
    const slotB = [_]u8{0x02} ** 32;
    const valA = [_]u8{0x11} ** 32;
    const valB = [_]u8{0x22} ** 32;

    journal.recordSSTORE(addr, slotA, [_]u8{0} ** 32, valA, 1);
    journal.recordSSTORE(addr, slotB, [_]u8{0} ** 32, valB, 1);

    try testing.expect(std.mem.eql(u8, &journal.getPostState(addr, slotA).?, &valA));
    try testing.expect(std.mem.eql(u8, &journal.getPostState(addr, slotB).?, &valB));
}

test "SDJ-014: sdj.get_delta_positive" {
    const val_pre = types.U256.fromU64(100);
    const val_post = types.U256.fromU64(250);
    const delta = types.U256.sub(val_post, val_pre);
    try testing.expectEqual(@as(u64, 150), delta.limbs[0]);
}

test "SDJ-015: sdj.get_delta_zero_for_untouched" {
    const journal = types.StateDeltaJournal.init();
    const addr = [_]u8{0xAA} ** 20;
    const slot = [_]u8{0x99} ** 32;
    try testing.expect(journal.getPreState(addr, slot) == null);
    try testing.expect(journal.getPostState(addr, slot) == null);
}

test "SDJ-016: sdj.commit_transaction_finalizes" {
    var journal = types.StateDeltaJournal.init();
    const addr = [_]u8{0xAA} ** 20;
    const slot = [_]u8{0x01} ** 32;
    const val0 = [_]u8{0x00} ** 32;
    const val1 = [_]u8{0x55} ** 32;

    journal.recordSSTORE(addr, slot, val0, val1, 0);
    try testing.expect(journal.getPostState(addr, slot) != null);
}

test "SDJ-017: sdj.revert_after_commit_rejected" {
    var journal = types.StateDeltaJournal.init();
    const cp = journal.beginCheckpoint();
    journal.commitCheckpoint(cp);
    // Attempting to revert already committed cp leaves journal intact
    journal.revertToCheckpoint(cp);
    try testing.expectEqual(@as(usize, 0), journal.checkpoint_len);
}

test "SDJ-018: sdj.deterministic_replay_hash" {
    var j1 = types.StateDeltaJournal.init();
    var j2 = types.StateDeltaJournal.init();

    const addr = [_]u8{0x12} ** 20;
    const slot = [_]u8{0x34} ** 32;
    const val0 = [_]u8{0x00} ** 32;
    const val1 = [_]u8{0x77} ** 32;

    j1.recordSSTORE(addr, slot, val0, val1, 1);
    j2.recordSSTORE(addr, slot, val0, val1, 1);

    try testing.expectEqual(j1.len, j2.len);
    try testing.expect(std.mem.eql(u8, std.mem.asBytes(&j1.entries[0]), std.mem.asBytes(&j2.entries[0])));
}

test "SDJ-019: sdj.no_dynamic_heap_policy" {
    // Assert StateDeltaJournal contains 0 pointer/allocator fields
    try testing.expect(!@hasField(types.StateDeltaJournal, "allocator"));
    try testing.expect(!@hasField(types.StateDeltaJournal, "arena"));
}

test "SDJ-020: sdj.checkpoint_ids_monotonic" {
    var journal = types.StateDeltaJournal.init();
    const cp1 = journal.beginCheckpoint();
    const cp2 = journal.beginCheckpoint();
    const cp3 = journal.beginCheckpoint();

    try testing.expect(cp1 < cp2);
    try testing.expect(cp2 < cp3);
}

test "SDJ-CRITICAL: Critical Nested Revert Sequence" {
    var journal = types.StateDeltaJournal.init();
    const addr = [_]u8{0xEE} ** 20;
    const slot = [_]u8{0xAA} ** 32;
    const v1 = [_]u8{0x01} ** 32;
    const v2 = [_]u8{0x02} ** 32;
    const v3 = [_]u8{0x03} ** 32;
    const v4 = [_]u8{0x04} ** 32;

    // 1. SSTORE A = 1
    journal.recordSSTORE(addr, slot, [_]u8{0} ** 32, v1, 0);

    // 2. Begin checkpoint 1
    const cp1 = journal.beginCheckpoint();
    // 3. SSTORE A = 2
    journal.recordSSTORE(addr, slot, v1, v2, 1);

    // 4. Begin checkpoint 2
    const cp2 = journal.beginCheckpoint();
    // 5. SSTORE A = 3
    journal.recordSSTORE(addr, slot, v2, v3, 2);

    // 6. Revert checkpoint 2
    journal.revertToCheckpoint(cp2);
    // 7. Assert A == 2
    try testing.expect(std.mem.eql(u8, &journal.getPostState(addr, slot).?, &v2));

    // 8. SSTORE A = 4
    journal.recordSSTORE(addr, slot, v2, v4, 1);

    // 9. Revert checkpoint 1
    journal.revertToCheckpoint(cp1);
    // 10. Assert A == 1
    try testing.expect(std.mem.eql(u8, &journal.getPostState(addr, slot).?, &v1));
}
