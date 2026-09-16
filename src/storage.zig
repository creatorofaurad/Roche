//! volta: McCarthy Array Storage & Deterministic Rollback Journal
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const types = @import("types.zig");

pub const JournalEntry = struct {
    slot: usize,
    old_value: u256,
};

pub const StorageState = struct {
    slots: [types.MAX_STORAGE_SLOTS]u256 = [_]u256{0} ** types.MAX_STORAGE_SLOTS,
    journal: [types.MAX_ROLLBACK_LOGS]JournalEntry = undefined,
    journal_len: usize = 0,

    pub fn init() StorageState {
        return .{};
    }

    pub inline fn store(self: *StorageState, slot: usize, val: u256) void {
        if (slot < types.MAX_STORAGE_SLOTS) {
            if (self.journal_len < types.MAX_ROLLBACK_LOGS) {
                self.journal[self.journal_len] = .{
                    .slot = slot,
                    .old_value = self.slots[slot],
                };
                self.journal_len += 1;
            }
            self.slots[slot] = val;
        }
    }

    pub inline fn select(self: *const StorageState, slot: usize) u256 {
        if (slot < types.MAX_STORAGE_SLOTS) {
            return self.slots[slot];
        }
        return 0;
    }

    pub inline fn checkpoint(self: *const StorageState) usize {
        return self.journal_len;
    }

    pub inline fn rollbackTo(self: *StorageState, cp: usize) void {
        while (self.journal_len > cp) {
            self.journal_len -= 1;
            const entry = self.journal[self.journal_len];
            self.slots[entry.slot] = entry.old_value;
        }
    }

    pub inline fn reset(self: *StorageState) void {
        @memset(&self.slots, 0);
        self.journal_len = 0;
    }
};

test "Storage: Store, Select and Rollback" {
    var storage = StorageState.init();
    storage.store(1, 100);
    try std.testing.expectEqual(@as(u256, 100), storage.select(1));

    const cp = storage.checkpoint();
    storage.store(1, 500);
    storage.store(2, 999);
    try std.testing.expectEqual(@as(u256, 500), storage.select(1));
    try std.testing.expectEqual(@as(u256, 999), storage.select(2));

    storage.rollbackTo(cp);
    try std.testing.expectEqual(@as(u256, 100), storage.select(1));
    try std.testing.expectEqual(@as(u256, 0), storage.select(2));
}
