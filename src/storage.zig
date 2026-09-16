//! volta: McCarthy Array Storage, Multi-Account World State & EIP-1153 Transient Storage
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.
//! 64-Byte Hardware Cache-Line Aligned.

const std = @import("std");
const types = @import("types.zig");

/// 64-Byte Cache-Aligned Rollback Journal Entry
pub const JournalEntry = struct {
    slot: usize, // 8 bytes (x86_64 / arm64)
    old_value: u256, // 32 bytes
    flags: u64 = 0, // 8 bytes (metadata/is_transient)
    _padding: [16]u8 = [_]u8{0} ** 16, // 16 bytes -> Total: exactly 64 bytes
};

comptime {
    std.debug.assert(@sizeOf(JournalEntry) == 64);
}

pub const StorageState = struct {
    slots: [types.MAX_STORAGE_SLOTS]u256 align(64) = [_]u256{0} ** types.MAX_STORAGE_SLOTS,
    journal: [types.MAX_ROLLBACK_LOGS]JournalEntry align(64) = undefined,
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
                    .flags = 0,
                    ._padding = [_]u8{0} ** 16,
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

/// EIP-1153 Transient Storage Model (Cancun / Uniswap v4 Hook Isolation)
pub const TransientStorage = struct {
    slots: [types.MAX_STORAGE_SLOTS]u256 align(64) = [_]u256{0} ** types.MAX_STORAGE_SLOTS,
    journal: [types.MAX_ROLLBACK_LOGS]JournalEntry align(64) = undefined,
    journal_len: usize = 0,

    pub fn init() TransientStorage {
        return .{};
    }

    pub inline fn tstore(self: *TransientStorage, slot: usize, val: u256) void {
        if (slot < types.MAX_STORAGE_SLOTS) {
            if (self.journal_len < types.MAX_ROLLBACK_LOGS) {
                self.journal[self.journal_len] = .{
                    .slot = slot,
                    .old_value = self.slots[slot],
                    .flags = 1, // is_transient = true
                    ._padding = [_]u8{0} ** 16,
                };
                self.journal_len += 1;
            }
            self.slots[slot] = val;
        }
    }

    pub inline fn tload(self: *const TransientStorage, slot: usize) u256 {
        if (slot < types.MAX_STORAGE_SLOTS) {
            return self.slots[slot];
        }
        return 0;
    }

    /// Clears all transient storage at transaction boundary (EIP-1153 invariant)
    pub inline fn clearBoundary(self: *TransientStorage) void {
        @memset(&self.slots, 0);
        self.journal_len = 0;
    }

    /// Formally verifies Transient Storage Isolation Invariant: ∀ k, Select(S_transient, k) == 0
    pub inline fn verifyCleanBoundary(self: *const TransientStorage) bool {
        for (self.slots) |s| {
            if (s != 0) return false;
        }
        return true;
    }
};

/// Foundry/revm-Style Account State
pub const Account = struct {
    address: [20]u8 = [_]u8{0} ** 20,
    balance: u256 = 0,
    nonce: u64 = 0,
    storage: StorageState = StorageState.init(),
    transient_storage: TransientStorage = TransientStorage.init(),
    is_active: bool = false,
};

/// Multi-Account World State Model (Fixed Pool, 0 Heap Allocations)
pub const WorldState = struct {
    accounts: [types.MAX_ACCOUNTS]Account = [_]Account{.{}} ** types.MAX_ACCOUNTS,

    pub fn init() WorldState {
        return .{};
    }

    pub fn getAccount(self: *WorldState, address: [20]u8) ?*Account {
        for (&self.accounts) |*acc| {
            if (acc.is_active and std.mem.eql(u8, &acc.address, &address)) {
                return acc;
            }
        }
        // Activate first empty slot
        for (&self.accounts) |*acc| {
            if (!acc.is_active) {
                acc.address = address;
                acc.is_active = true;
                return acc;
            }
        }
        return null;
    }

    pub fn getOrCreateAccount(self: *WorldState, address: [20]u8) *Account {
        if (self.getAccount(address)) |acc| {
            return acc;
        }
        self.accounts[0].address = address;
        self.accounts[0].is_active = true;
        return &self.accounts[0];
    }
};

/// Foundry-Style Cheatcode Context (`warp`, `roll`, `prank`, `deal`)
pub const CheatcodeContext = struct {
    current_address: [20]u8 = [_]u8{0xAA} ** 20,
    current_caller: [20]u8 = [_]u8{0xBB} ** 20,
    origin: [20]u8 = [_]u8{0xBB} ** 20,
    block_number: u64 = 1,
    block_timestamp: u64 = 1_000_000,
    chain_id: u64 = 1,
    is_prank_active: bool = false,

    pub fn init() CheatcodeContext {
        return .{};
    }

    pub inline fn warp(self: *CheatcodeContext, new_timestamp: u64) void {
        self.block_timestamp = new_timestamp;
    }

    pub inline fn roll(self: *CheatcodeContext, new_block: u64) void {
        self.block_number = new_block;
    }

    pub inline fn prank(self: *CheatcodeContext, new_caller: [20]u8) void {
        self.current_caller = new_caller;
        self.is_prank_active = true;
    }

    pub inline fn stopPrank(self: *CheatcodeContext) void {
        self.is_prank_active = false;
    }

    pub inline fn deal(world: *WorldState, target: [20]u8, amount: u256) bool {
        if (world.getAccount(target)) |acc| {
            acc.balance = amount;
            return true;
        }
        return false;
    }
};
