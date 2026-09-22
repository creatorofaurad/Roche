//! vm_solana.zig: Roche v2 Solana Execution Adapter & Account State-Delta Engine
//! Maps Solana SVM Execution Semantics, Borsh Account Layouts, CPI Callframes,
//! Sysvars, and PDA Derivation Checks directly to the Roche Bare-Silicon Kernel APIs.
//! Pure Zig 0.16.0 with ZERO Dynamic Heap Allocation (0 Bytes malloc/free).

const std = @import("std");
const types = @import("types.zig");
const vm_mod = @import("vm.zig");

pub const Pubkey = [32]u8;

pub const MAX_CPI_DEPTH: usize = 8;
pub const MAX_ACCOUNTS: usize = 32;
pub const MAX_ACCOUNT_DATA_BYTES: usize = 1024;

/// Solana CPI Call Frame representation mapped into Roche kernel invariants
pub const CpiFrame = struct {
    frame_id: u32 = 0,
    parent_frame_id: u32 = 0,
    program_id: Pubkey = [_]u8{0} ** 32,
    caller_program_id: Pubkey = [_]u8{0} ** 32,
    is_signer: bool = false,
    is_writable: bool = false,
    seeds: [4][32]u8 = [_][32]u8{[_]u8{0} ** 32} ** 4,
    seed_lengths: [4]u8 = [_]u8{0} ** 4,
    seed_count: u8 = 0,
    bump: u8 = 0,
    is_pda: bool = false,
};

/// Solana Account Mirror Structure for State-Delta Tracking
pub const SolanaAccount = struct {
    pubkey: Pubkey = [_]u8{0} ** 32,
    owner: Pubkey = [_]u8{0} ** 32,
    lamports: u64 = 0,
    data: [MAX_ACCOUNT_DATA_BYTES]u8 = [_]u8{0} ** MAX_ACCOUNT_DATA_BYTES,
    data_len: usize = 0,
    executable: bool = false,
    rent_epoch: u64 = 0,
    is_signer: bool = false,
    is_writable: bool = false,

    pub fn readU64(self: *const SolanaAccount, offset: usize) u64 {
        if (offset + 8 > self.data_len) return 0;
        return std.mem.readInt(u64, self.data[offset..][0..8], .little);
    }

    pub fn writeU64(self: *SolanaAccount, offset: usize, val: u64) void {
        if (offset + 8 <= MAX_ACCOUNT_DATA_BYTES) {
            std.mem.writeInt(u64, self.data[offset..][0..8], val, .little);
            if (offset + 8 > self.data_len) self.data_len = offset + 8;
        }
    }

    pub fn readPubkey(self: *const SolanaAccount, offset: usize) Pubkey {
        var pk: Pubkey = [_]u8{0} ** 32;
        if (offset + 32 <= self.data_len) {
            @memcpy(&pk, self.data[offset..][0..32]);
        }
        return pk;
    }

    pub fn writePubkey(self: *SolanaAccount, offset: usize, pk: Pubkey) void {
        if (offset + 32 <= MAX_ACCOUNT_DATA_BYTES) {
            @memcpy(self.data[offset..][0..32], &pk);
            if (offset + 32 > self.data_len) self.data_len = offset + 32;
        }
    }

    pub fn readBool(self: *const SolanaAccount, offset: usize) bool {
        if (offset >= self.data_len) return false;
        return self.data[offset] != 0;
    }

    pub fn writeBool(self: *SolanaAccount, offset: usize, val: bool) void {
        if (offset < MAX_ACCOUNT_DATA_BYTES) {
            self.data[offset] = if (val) 1 else 0;
            if (offset + 1 > self.data_len) self.data_len = offset + 1;
        }
    }
};

/// Solana Sysvars
pub const ClockSysvar = struct {
    slot: u64 = 0,
    epoch_start_timestamp: i64 = 0,
    epoch: u64 = 0,
    leader_schedule_epoch: u64 = 0,
    unix_timestamp: i64 = 0,
};

pub const RentSysvar = struct {
    lamports_per_byte_year: u64 = 3480,
    exemption_threshold: f64 = 2.0,
    burn_percent: u8 = 50,
};

/// Roche Solana VM Adapter Engine
pub const SolanaVMAdapter = struct {
    accounts: [MAX_ACCOUNTS]SolanaAccount = [_]SolanaAccount{.{}} ** MAX_ACCOUNTS,
    account_count: usize = 0,

    cpi_stack: [MAX_CPI_DEPTH]CpiFrame = [_]CpiFrame{.{}} ** MAX_CPI_DEPTH,
    cpi_depth: usize = 0,

    clock: ClockSysvar = .{},
    rent: RentSysvar = .{},

    current_program: Pubkey = [_]u8{0} ** 32,

    pub fn init() SolanaVMAdapter {
        return .{};
    }

    pub fn addAccount(self: *SolanaVMAdapter, acc: SolanaAccount) usize {
        if (self.account_count < MAX_ACCOUNTS) {
            const idx = self.account_count;
            self.accounts[idx] = acc;
            self.account_count += 1;
            return idx;
        }
        return 0;
    }

    pub fn getAccount(self: *SolanaVMAdapter, pubkey: Pubkey) ?*SolanaAccount {
        for (0..self.account_count) |i| {
            if (std.mem.eql(u8, &self.accounts[i].pubkey, &pubkey)) {
                return &self.accounts[i];
            }
        }
        return null;
    }

    /// Record account modification to Roche StateDeltaJournal
    pub fn recordAccountDelta(
        self: *SolanaVMAdapter,
        vm: *vm_mod.VM,
        account_idx: usize,
        pre_data: []const u8,
        post_data: []const u8,
    ) void {
        if (account_idx >= MAX_ACCOUNTS) return;
        
        var addr20: [20]u8 = [_]u8{0} ** 20;
        @memcpy(addr20[0..20], self.accounts[account_idx].pubkey[0..20]);

        var pre32: [32]u8 = [_]u8{0} ** 32;
        var post32: [32]u8 = [_]u8{0} ** 32;

        const copy_pre = @min(pre_data.len, 32);
        const copy_post = @min(post_data.len, 32);

        @memcpy(pre32[0..copy_pre], pre_data[0..copy_pre]);
        @memcpy(post32[0..copy_post], post_data[0..copy_post]);

        var slot: [32]u8 = [_]u8{0} ** 32;
        slot[31] = @truncate(account_idx);

        vm.delta_journal.recordSSTORE(addr20, slot, pre32, post32, @truncate(self.cpi_depth));
    }

    /// Push CPI frame
    pub fn pushCpi(
        self: *SolanaVMAdapter,
        program_id: Pubkey,
        caller_program_id: Pubkey,
        seeds: ?[]const []const u8,
        bump: ?u8,
    ) bool {
        if (self.cpi_depth >= MAX_CPI_DEPTH) return false;
        var frame = CpiFrame{
            .frame_id = @truncate(self.cpi_depth),
            .parent_frame_id = if (self.cpi_depth > 0) @as(u32, @truncate(self.cpi_depth - 1)) else 0,
            .program_id = program_id,
            .caller_program_id = caller_program_id,
            .is_signer = (seeds != null),
            .is_writable = true,
            .is_pda = (seeds != null),
            .bump = bump orelse 0,
        };

        if (seeds) |s_list| {
            frame.seed_count = @min(@as(u8, @truncate(s_list.len)), 4);
            for (0..frame.seed_count) |i| {
                const s = s_list[i];
                const l = @min(s.len, 32);
                @memcpy(frame.seeds[i][0..l], s[0..l]);
                frame.seed_lengths[i] = @truncate(l);
            }
        }

        self.cpi_stack[self.cpi_depth] = frame;
        self.cpi_depth += 1;
        return true;
    }

    /// Pop CPI frame
    pub fn popCpi(self: *SolanaVMAdapter) void {
        if (self.cpi_depth > 0) {
            self.cpi_depth -= 1;
        }
    }

    /// Validate PDA derivation pattern
    pub fn validatePda(program_id: Pubkey, seeds: []const []const u8, bump: u8, expected_pda: Pubkey) bool {
        var hasher = std.crypto.hash.sha2.Sha256.init(.{});
        for (seeds) |seed| {
            hasher.update(seed);
        }
        const b = [_]u8{bump};
        hasher.update(&b);
        hasher.update(&program_id);
        const marker = "ProgramDerivedAddress";
        hasher.update(marker);

        var derived: [32]u8 = undefined;
        hasher.final(&derived);

        return std.mem.eql(u8, &derived, &expected_pda);
    }
};
