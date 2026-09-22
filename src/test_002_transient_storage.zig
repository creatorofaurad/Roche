//! test_002_transient_storage.zig: Complete TSJ-001 through TSJ-015 Test Suite
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const testing = std.testing;
const types = @import("types.zig");

test "TSJ-001: tsj.init_empty" {
    const tsj = types.TransientStorageJournal.init();
    try testing.expectEqual(@as(usize, 0), tsj.len);
    try testing.expectEqual(@as(usize, 0), tsj.total_recorded);
    try testing.expectEqual(@as(usize, 0), tsj.checkpoint_len);
}

test "TSJ-002: tsj.tstore_visible_same_frame" {
    var tsj = types.TransientStorageJournal.init();
    const addr = [_]u8{0xAA} ** 20;
    const slot = [_]u8{0x01} ** 32;
    const v0 = [_]u8{0x00} ** 32;
    const v1 = [_]u8{0x64} ** 32; // 100

    tsj.recordTSTORE(addr, slot, v0, v1, 1);
    try testing.expectEqual(@as(usize, 1), tsj.len);
    try testing.expect(std.mem.eql(u8, &tsj.entries[0].new_val, &v1));
}

test "TSJ-003: tsj.tload_missing_returns_zero" {
    var storage = @import("storage.zig").TransientStorage.init();
    try testing.expectEqual(@as(u256, 0), storage.tload(999));
}

test "TSJ-004: tsj.tstore_overwrite_latest" {
    var storage = @import("storage.zig").TransientStorage.init();
    storage.tstore(1, 100);
    storage.tstore(1, 200);
    try testing.expectEqual(@as(u256, 200), storage.tload(1));
}

test "TSJ-005: tsj.checkpoint_revert_restores_old_transient" {
    var storage = @import("storage.zig").TransientStorage.init();
    storage.tstore(1, 100);
    const cp = storage.checkpoint();
    storage.tstore(1, 200);
    storage.rollbackTo(cp);
    try testing.expectEqual(@as(u256, 100), storage.tload(1));
}

test "TSJ-006: tsj.nested_transient_revert" {
    var storage = @import("storage.zig").TransientStorage.init();
    storage.tstore(1, 10);
    const cp1 = storage.checkpoint();
    storage.tstore(2, 20);
    const cp2 = storage.checkpoint();
    storage.tstore(3, 30);
    storage.rollbackTo(cp2);

    try testing.expectEqual(@as(u256, 10), storage.tload(1));
    try testing.expectEqual(@as(u256, 20), storage.tload(2));
    try testing.expectEqual(@as(u256, 0), storage.tload(3));

    storage.rollbackTo(cp1);
    try testing.expectEqual(@as(u256, 10), storage.tload(1));
    try testing.expectEqual(@as(u256, 0), storage.tload(2));
}

test "TSJ-007: tsj.committed_child_transient_visible_parent" {
    var storage = @import("storage.zig").TransientStorage.init();
    storage.tstore(1, 100);
    _ = storage.checkpoint();
    storage.tstore(1, 200);
    // Commit does nothing to discard the value in storage
    try testing.expectEqual(@as(u256, 200), storage.tload(1));
}

test "TSJ-008: tsj.reverted_child_transient_not_visible_parent" {
    var storage = @import("storage.zig").TransientStorage.init();
    storage.tstore(1, 100);
    const cp = storage.checkpoint();
    storage.tstore(1, 200);
    storage.rollbackTo(cp);
    try testing.expectEqual(@as(u256, 100), storage.tload(1));
}

test "TSJ-009: tsj.end_transaction_clears_transient" {
    var storage = @import("storage.zig").TransientStorage.init();
    storage.tstore(1, 500);
    storage.tstore(2, 600);
    storage.clearBoundary();
    try testing.expect(storage.verifyCleanBoundary());
}

test "TSJ-010: tsj.persistent_and_transient_isolated" {
    var p_storage = @import("storage.zig").StorageState.init();
    var t_storage = @import("storage.zig").TransientStorage.init();

    p_storage.store(5, 111);
    t_storage.tstore(5, 222);

    try testing.expectEqual(@as(u256, 111), p_storage.select(5));
    try testing.expectEqual(@as(u256, 222), t_storage.tload(5));
}

test "TSJ-011: tsj.same_key_different_address_isolated" {
    var world = @import("storage.zig").WorldState.init();
    const addrA = [_]u8{0xAA} ** 20;
    const addrB = [_]u8{0xBB} ** 20;

    const accA = world.getOrCreateAccount(addrA);
    accA.transient_storage.tstore(1, 123);

    const accB = world.getOrCreateAccount(addrB);
    accB.transient_storage.tstore(1, 456);

    try testing.expectEqual(@as(u256, 123), world.getAccount(addrA).?.transient_storage.tload(1));
    try testing.expectEqual(@as(u256, 456), world.getAccount(addrB).?.transient_storage.tload(1));
}

test "TSJ-012: tsj.capacity_overflow_error" {
    var tsj = types.TransientStorageJournal.init();
    const addr = [_]u8{0xAA} ** 20;
    const slot = [_]u8{0x01} ** 32;
    const v = [_]u8{0x01} ** 32;

    for (0..types.MAX_TRANSIENT_DELTAS) |_| {
        tsj.recordTSTORE(addr, slot, v, v, 1);
    }
    try testing.expectEqual(types.MAX_TRANSIENT_DELTAS, tsj.len);
    // Boundary check
    tsj.recordTSTORE(addr, slot, v, v, 1);
    try testing.expectEqual(types.MAX_TRANSIENT_DELTAS, tsj.len);
}

test "TSJ-013: tsj.deterministic" {
    var tsj1 = types.TransientStorageJournal.init();
    var tsj2 = types.TransientStorageJournal.init();

    const addr = [_]u8{0xAA} ** 20;
    const slot = [_]u8{0x01} ** 32;
    const v0 = [_]u8{0x00} ** 32;
    const v1 = [_]u8{0x01} ** 32;

    tsj1.recordTSTORE(addr, slot, v0, v1, 1);
    tsj2.recordTSTORE(addr, slot, v0, v1, 1);

    try testing.expect(std.mem.eql(u8, std.mem.asBytes(&tsj1.entries[0]), std.mem.asBytes(&tsj2.entries[0])));
}

test "TSJ-014: tsj.no_tx_to_tx_leak" {
    var tsj = types.TransientStorageJournal.init();
    const addr = [_]u8{0xAA} ** 20;
    const slot = [_]u8{0x01} ** 32;
    const v = [_]u8{0x01} ** 32;

    tsj.recordTSTORE(addr, slot, v, v, 1);
    tsj.clearTransactionTransient();

    try testing.expectEqual(@as(usize, 0), tsj.len);
    try testing.expectEqual(@as(usize, 0), tsj.total_recorded);
}

test "TSJ-015: tsj.revert_does_not_touch_persistent" {
    var p_storage = @import("storage.zig").StorageState.init();
    var t_storage = @import("storage.zig").TransientStorage.init();

    p_storage.store(1, 1000);
    const cp = t_storage.checkpoint();
    t_storage.tstore(1, 2000);
    t_storage.rollbackTo(cp);

    try testing.expectEqual(@as(u256, 1000), p_storage.select(1));
    try testing.expectEqual(@as(u256, 0), t_storage.tload(1));
}

test "TSJ-CRITICAL: Critical EIP-1153 Revert Sequence" {
    var t_storage = @import("storage.zig").TransientStorage.init();

    // 1. TSTORE K = 100
    t_storage.tstore(1, 100);

    // 2. Begin child checkpoint
    const cp = t_storage.checkpoint();

    // 3. TSTORE K = 200
    t_storage.tstore(1, 200);

    // 4. Revert child checkpoint
    t_storage.rollbackTo(cp);

    // 5. TLOAD K == 100
    try testing.expectEqual(@as(u256, 100), t_storage.tload(1));

    // 6. End transaction
    t_storage.clearBoundary();

    // 7. TLOAD K == 0
    try testing.expectEqual(@as(u256, 0), t_storage.tload(1));
}
