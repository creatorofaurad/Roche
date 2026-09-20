//! ROCHE: McCarthy Array Storage, Multi-Account World State & EIP-1153 Transient Storage
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.
//! 40-Byte Compact WAL Journal Layout & Address-Indexed Fast Rollback.

const std = @import("std");
const types = @import("types.zig");

/// 40-Byte Compact Rollback Journal Entry
pub const JournalEntry = struct {
    account_idx: u16 = 0, // 2 bytes
    is_transient: u8 = 0, // 1 byte
    reserved: u8 = 0, // 1 byte
    slot: u32 = 0, // 4 bytes
    old_value: [32]u8 = [_]u8{0} ** 32, // 32 bytes -> Total: exactly 40 bytes

    pub inline fn getOldValue(self: *const JournalEntry) u256 {
        var val: u256 = 0;
        for (self.old_value) |b| {
            val = (val << 8) | @as(u256, b);
        }
        return val;
    }

    pub inline fn setOldValue(self: *mut_Self, val: u256) void {
        var temp = val;
        var i: usize = 32;
        while (i > 0) {
            i -= 1;
            self.old_value[i] = @truncate(temp & 0xFF);
            temp >>= 8;
        }
    }
    const mut_Self = JournalEntry;
};

comptime {
    std.debug.assert(@sizeOf(JournalEntry) == 40);
}

pub const StorageState = struct {
    slots: [types.MAX_STORAGE_SLOTS]u256 align(64) = [_]u256{0} ** types.MAX_STORAGE_SLOTS,
    journal: [types.MAX_ROLLBACK_LOGS]JournalEntry = undefined,
    journal_len: usize = 0,
    account_idx: u16 = 0,

    pub fn init() StorageState {
        return .{};
    }

    pub fn initWithAccount(acc_idx: u16) StorageState {
        return .{
            .account_idx = acc_idx,
        };
    }

    pub inline fn store(self: *StorageState, slot: usize, val: u256) void {
        if (slot < types.MAX_STORAGE_SLOTS) {
            if (self.journal_len < types.MAX_ROLLBACK_LOGS) {
                var entry = JournalEntry{
                    .account_idx = self.account_idx,
                    .is_transient = 0,
                    .reserved = 0,
                    .slot = @truncate(slot),
                };
                entry.setOldValue(self.slots[slot]);
                self.journal[self.journal_len] = entry;
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
            const slot_idx: usize = entry.slot;
            if (slot_idx < types.MAX_STORAGE_SLOTS) {
                self.slots[slot_idx] = entry.getOldValue();
            }
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
    journal: [types.MAX_ROLLBACK_LOGS]JournalEntry = undefined,
    journal_len: usize = 0,
    account_idx: u16 = 0,

    pub fn init() TransientStorage {
        return .{};
    }

    pub fn initWithAccount(acc_idx: u16) TransientStorage {
        return .{
            .account_idx = acc_idx,
        };
    }

    pub inline fn tstore(self: *TransientStorage, slot: usize, val: u256) void {
        if (slot < types.MAX_STORAGE_SLOTS) {
            if (self.journal_len < types.MAX_ROLLBACK_LOGS) {
                var entry = JournalEntry{
                    .account_idx = self.account_idx,
                    .is_transient = 1, // is_transient = true
                    .reserved = 0,
                    .slot = @truncate(slot),
                };
                entry.setOldValue(self.slots[slot]);
                self.journal[self.journal_len] = entry;
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

    pub inline fn checkpoint(self: *const TransientStorage) usize {
        return self.journal_len;
    }

    pub inline fn rollbackTo(self: *TransientStorage, cp: usize) void {
        while (self.journal_len > cp) {
            self.journal_len -= 1;
            const entry = self.journal[self.journal_len];
            const slot_idx: usize = entry.slot;
            if (slot_idx < types.MAX_STORAGE_SLOTS) {
                self.slots[slot_idx] = entry.getOldValue();
            }
        }
    }

    /// Clears all transient storage at transaction boundary (EIP-1153 invariant)
    pub inline fn clearBoundary(self: *TransientStorage) void {
        @memset(&self.slots, 0);
        self.journal_len = 0;
    }

    /// Formally verifies Transient Storage Isolation Invariant: âˆ€ k, Select(S_transient, k) == 0
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
    code_len: usize = 0,
    code: [4096]u8 = [_]u8{0} ** 4096,
    code_hash: [32]u8 = [_]u8{0} ** 32,
    storage: StorageState = StorageState.init(),
    transient_storage: TransientStorage = TransientStorage.init(),
    is_active: bool = false,

    pub fn setCode(self: *Account, bytecode: []const u8) void {
        const copy_len = @min(bytecode.len, 4096);
        @memcpy(self.code[0..copy_len], bytecode[0..copy_len]);
        self.code_len = copy_len;
        if (copy_len > 0) {
            std.crypto.hash.sha3.Keccak256.hash(bytecode[0..copy_len], &self.code_hash, .{});
        } else {
            @memset(&self.code_hash, 0);
        }
    }
};

/// Global Rollback Frame Checkpoint
pub const FrameCheckpoint = struct {
    account_idx: u16,
    storage_cp: usize,
    transient_cp: usize,
};

/// Multi-Account World State Model (Fixed Pool, 0 Heap Allocations)
pub const WorldState = struct {
    accounts: [types.MAX_ACCOUNTS]Account = [_]Account{.{}} ** types.MAX_ACCOUNTS,
    account_count: usize = 0,

    pub fn init() WorldState {
        var ws = WorldState{};
        for (&ws.accounts, 0..) |*acc, idx| {
            acc.storage.account_idx = @truncate(idx);
            acc.transient_storage.account_idx = @truncate(idx);
        }
        return ws;
    }

    pub fn getAccount(self: *WorldState, address: [20]u8) ?*Account {
        for (&self.accounts) |*acc| {
            if (acc.is_active and std.mem.eql(u8, &acc.address, &address)) {
                return acc;
            }
        }
        return null;
    }

    pub fn getAccountIndex(self: *const WorldState, address: [20]u8) ?usize {
        for (self.accounts, 0..) |acc, idx| {
            if (acc.is_active and std.mem.eql(u8, &acc.address, &address)) {
                return idx;
            }
        }
        return null;
    }

    pub fn getOrCreateAccount(self: *WorldState, address: [20]u8) *Account {
        if (self.getAccount(address)) |acc| {
            return acc;
        }
        // Activate first empty slot
        for (&self.accounts, 0..) |*acc, idx| {
            if (!acc.is_active) {
                acc.address = address;
                acc.is_active = true;
                acc.storage.account_idx = @truncate(idx);
                acc.transient_storage.account_idx = @truncate(idx);
                self.account_count += 1;
                return acc;
            }
        }
        self.accounts[0].address = address;
        self.accounts[0].is_active = true;
        return &self.accounts[0];
    }

    pub fn checkpointAccount(self: *const WorldState, acc_idx: usize) FrameCheckpoint {
        if (acc_idx < types.MAX_ACCOUNTS) {
            return .{
                .account_idx = @truncate(acc_idx),
                .storage_cp = self.accounts[acc_idx].storage.checkpoint(),
                .transient_cp = self.accounts[acc_idx].transient_storage.checkpoint(),
            };
        }
        return .{ .account_idx = 0, .storage_cp = 0, .transient_cp = 0 };
    }

    pub fn rollbackAccount(self: *WorldState, cp: FrameCheckpoint) void {
        const idx: usize = cp.account_idx;
        if (idx < types.MAX_ACCOUNTS) {
            self.accounts[idx].storage.rollbackTo(cp.storage_cp);
            self.accounts[idx].transient_storage.rollbackTo(cp.transient_cp);
        }
    }

    pub fn clearAllTransient(self: *WorldState) void {
        for (&self.accounts) |*acc| {
            if (acc.is_active) {
                acc.transient_storage.clearBoundary();
            }
        }
    }
};

/// Foundry-Style Cheatcode Context (`warp`, `roll`, `prank`, `deal`)
pub const CheatcodeContext = struct {
    current_address: [20]u8 = [_]u8{0xAA} ** 20,
    current_caller: [20]u8 = [_]u8{0xBB} ** 20,
    origin: [20]u8 = [_]u8{0xBB} ** 20,
    call_value: u256 = 0,
    block_number: u64 = 1,
    block_timestamp: u64 = 1_000_000,
    chain_id: u64 = 1,
    gas_price: u256 = 20_000_000_000,
    base_fee: u256 = 1_000_000_000,
    blob_base_fee: u256 = 1,
    blob_hashes: [16][32]u8 = [_][32]u8{[_]u8{0} ** 32} ** 16,
    blob_hash_count: usize = 0,
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
        const acc = world.getOrCreateAccount(target);
        acc.balance = amount;
        return true;
    }

    pub inline fn setChainId(self: *CheatcodeContext, cid: u64) void {
        self.chain_id = cid;
    }

    pub inline fn setBaseFee(self: *CheatcodeContext, bf: u256) void {
        self.base_fee = bf;
    }

    pub inline fn setBlobBaseFee(self: *CheatcodeContext, bbf: u256) void {
        self.blob_base_fee = bbf;
    }
};
