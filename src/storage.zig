//! volta: McCarthy Array Storage, Multi-Account World State & Foundry Cheatcodes
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

/// Foundry/revm-Style Account State
pub const Account = struct {
    address: [20]u8 = [_]u8{0} ** 20,
    balance: u256 = 0,
    nonce: u64 = 0,
    storage: StorageState = StorageState.init(),
    is_active: bool = false,
};

/// Multi-Account World State Model (Fixed Pool, 0 Heap Allocations)
pub const WorldState = struct {
    accounts: [types.MAX_ACCOUNTS]Account = [_]Account{.{}} ** types.MAX_ACCOUNTS,
    account_count: usize = 0,

    pub fn init() WorldState {
        return .{};
    }

    pub fn getOrCreateAccount(self: *WorldState, address: [20]u8) *Account {
        for (0..self.account_count) |i| {
            if (std.mem.eql(u8, &self.accounts[i].address, &address)) {
                return &self.accounts[i];
            }
        }
        if (self.account_count < types.MAX_ACCOUNTS) {
            const idx = self.account_count;
            self.accounts[idx].address = address;
            self.accounts[idx].balance = 0;
            self.accounts[idx].nonce = 0;
            self.accounts[idx].storage = StorageState.init();
            self.accounts[idx].is_active = true;
            self.account_count += 1;
            return &self.accounts[idx];
        }
        return &self.accounts[0]; // Fallback if saturated
    }

    pub inline fn transfer(self: *WorldState, from: [20]u8, to: [20]u8, amount: u256) bool {
        var from_acc = self.getOrCreateAccount(from);
        if (from_acc.balance < amount) return false;
        var to_acc = self.getOrCreateAccount(to);
        from_acc.balance -%= amount;
        to_acc.balance +%= amount;
        return true;
    }
};

/// Foundry Cheatcode Emulation Context (`vm.prank`, `vm.warp`, `vm.roll`, `vm.deal`)
pub const CheatcodeContext = struct {
    current_caller: [20]u8 = [_]u8{0xAA} ** 20,
    current_address: [20]u8 = [_]u8{0xBB} ** 20,
    block_timestamp: u64 = 1700000000,
    block_number: u64 = 19000000,
    chain_id: u64 = 1,

    pub fn init() CheatcodeContext {
        return .{};
    }

    /// `vm.prank(address)`
    pub inline fn prank(self: *CheatcodeContext, caller: [20]u8) void {
        self.current_caller = caller;
    }

    /// `vm.warp(timestamp)`
    pub inline fn warp(self: *CheatcodeContext, new_timestamp: u64) void {
        self.block_timestamp = new_timestamp;
    }

    /// `vm.roll(block_number)`
    pub inline fn roll(self: *CheatcodeContext, new_block_number: u64) void {
        self.block_number = new_block_number;
    }

    /// `vm.deal(address, amount)`
    pub inline fn deal(world: *WorldState, target: [20]u8, amount: u256) void {
        var acc = world.getOrCreateAccount(target);
        acc.balance = amount;
    }
};

test "Storage: Multi-Account WorldState & Foundry Cheatcodes" {
    var world = WorldState.init();
    var cheatcodes = CheatcodeContext.init();

    const alice = [_]u8{0x01} ** 20;
    const bob = [_]u8{0x02} ** 20;

    // vm.deal(alice, 1000)
    CheatcodeContext.deal(&world, alice, 1000);
    try std.testing.expectEqual(@as(u256, 1000), world.getOrCreateAccount(alice).balance);

    // Transfer from Alice to Bob
    try std.testing.expect(world.transfer(alice, bob, 400));
    try std.testing.expectEqual(@as(u256, 600), world.getOrCreateAccount(alice).balance);
    try std.testing.expectEqual(@as(u256, 400), world.getOrCreateAccount(bob).balance);

    // vm.warp(1700005000) & vm.prank(bob)
    cheatcodes.warp(1700005000);
    cheatcodes.prank(bob);
    try std.testing.expectEqual(@as(u64, 1700005000), cheatcodes.block_timestamp);
    try std.testing.expect(std.mem.eql(u8, &cheatcodes.current_caller, &bob));
}
