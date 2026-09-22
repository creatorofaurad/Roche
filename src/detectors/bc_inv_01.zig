//! bc_inv_01.zig: Deterministic Zero-Heap Bonding Curve Invariant Verification Engine
//! Part of ROCHE Silicon EVM/SVM Formal Security Engine.
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");

// ============================================================================
// CONSTANTS & 256-BIT FIXED-POINT ARITHMETIC CONSTANTS
// ============================================================================

pub const SCALE_DECIMALS: usize = 18;
pub const SCALE_FACTOR: u256 = 1_000_000_000_000_000_000; // 1e18
pub const MAX_TRANSITIONS: usize = 256;
pub const MAX_FINDINGS: usize = 8;

// ============================================================================
// FINDINGS DATA STRUCTURES (0 HEAP ALLOCATIONS)
// ============================================================================

pub const Severity = enum(u8) {
    Info = 1,
    Low = 3,
    Medium = 5,
    High = 8,
    Critical = 10,
};

pub const Finding = struct {
    severity: Severity = .Info,
    title: [64]u8 = [_]u8{0} ** 64,
    title_len: usize = 0,
    description: [256]u8 = [_]u8{0} ** 256,
    description_len: usize = 0,

    pub fn init(severity: Severity, title_str: []const u8, desc_str: []const u8) Finding {
        var f = Finding{ .severity = severity };
        const t_len = @min(title_str.len, 64);
        @memcpy(f.title[0..t_len], title_str[0..t_len]);
        f.title_len = t_len;

        const d_len = @min(desc_str.len, 256);
        @memcpy(f.description[0..d_len], desc_str[0..d_len]);
        f.description_len = d_len;
        return f;
    }

    pub fn getTitle(self: *const Finding) []const u8 {
        return self.title[0..self.title_len];
    }

    pub fn getDescription(self: *const Finding) []const u8 {
        return self.description[0..self.description_len];
    }
};

pub const Findings = struct {
    items: [MAX_FINDINGS]Finding = [_]Finding{.{}} ** MAX_FINDINGS,
    count: usize = 0,

    pub fn add(self: *Findings, finding: Finding) void {
        if (self.count < MAX_FINDINGS) {
            self.items[self.count] = finding;
            self.count += 1;
        }
    }

    pub fn hasFindings(self: *const Findings) bool {
        return self.count > 0;
    }
};

// ============================================================================
// STATE MACHINE TRANSITIONS & TRACE BUFFERS
// ============================================================================

pub const TransitionType = enum(u8) {
    Buy = 0,
    Sell = 1,
    Migration = 2,
};

pub const StateTransition = struct {
    transition_type: TransitionType = .Buy,
    virtual_sol_reserves: u256 = 0,
    virtual_token_reserves: u256 = 0,
    marginal_fee: u256 = 0,
    price_wad: u256 = 0,
};

pub const State = struct {
    transitions: [MAX_TRANSITIONS]StateTransition = [_]StateTransition{.{}} ** MAX_TRANSITIONS,
    transition_count: usize = 0,
    protocol_fee_pool_balance: u256 = 0,
    is_migrated: bool = false,
    migration_virtual_reserves: u256 = 0,
    migrated_target_liquidity: u256 = 0,

    pub fn init() State {
        return .{};
    }

    pub fn recordTransition(
        self: *State,
        t_type: TransitionType,
        v_sol: u256,
        v_token: u256,
        fee: u256,
    ) void {
        if (self.transition_count >= MAX_TRANSITIONS) return;
        const price = if (v_token > 0)
            (v_sol * SCALE_FACTOR) / v_token
        else
            0;

        self.transitions[self.transition_count] = .{
            .transition_type = t_type,
            .virtual_sol_reserves = v_sol,
            .virtual_token_reserves = v_token,
            .marginal_fee = fee,
            .price_wad = price,
        };
        self.transition_count += 1;
    }

    pub fn setMigrationState(self: *State, virtual_reserves: u256, target_liquidity: u256) void {
        self.is_migrated = true;
        self.migration_virtual_reserves = virtual_reserves;
        self.migrated_target_liquidity = target_liquidity;
    }
};

// ============================================================================
// INVARIANT DETECTOR IMPLEMENTATION (UPGRADED v2 - Directional Consistency)
// ============================================================================

pub const BondingCurveInvariantDetector = struct {
    pub fn evaluate(state: *const State) Findings {
        var findings = Findings{};

        // --------------------------------------------------------------------
        // Invariant A (Fee Monotonicity):
        // Sum(fee_i) == pool_balance
        // --------------------------------------------------------------------
        var accumulated_fees: u256 = 0;
        var overflow_detected = false;

        for (0..state.transition_count) |i| {
            const fee = state.transitions[i].marginal_fee;
            const res = @addWithOverflow(accumulated_fees, fee);
            if (res[1] != 0) {
                overflow_detected = true;
                break;
            }
            accumulated_fees = res[0];
        }

        if (overflow_detected) {
            findings.add(Finding.init(
                .Critical,
                "BC-INV-01: Fee Accumulator Overflow",
                "Arithmetic overflow occurred while accumulating marginal fees across transitions.",
            ));
        } else if (accumulated_fees != state.protocol_fee_pool_balance) {
            findings.add(Finding.init(
                .High,
                "BC-INV-01: Fee Conservation Violation",
                "Sum of marginal fees does not equal protocol fee pool balance.",
            ));
        }

        // --------------------------------------------------------------------
        // Invariant B (Directional Consistency):
        // Price should increase on Buys where SOL reserves increase.
        // We ignore price drops if SOL reserves also decreased (likely a fee/withdrawal event).
        // --------------------------------------------------------------------
        var last_buy_price: ?u256 = null;
        var last_buy_sol_reserves: ?u256 = null;

        for (0..state.transition_count) |i| {
            const tr = state.transitions[i];

            if (tr.transition_type == .Sell) {
                // Reset baseline on Sell
                last_buy_price = null;
                last_buy_sol_reserves = null;
            } else if (tr.transition_type == .Buy) {
                if (last_buy_price) |prev_price| {
                    if (last_buy_sol_reserves) |prev_sol| {
                        // Only flag if price dropped BUT sol reserves increased (True Curve Violation)
                        if (tr.price_wad < prev_price and tr.virtual_sol_reserves > prev_sol) {
                            findings.add(Finding.init(
                                .Critical,
                                "BC-INV-02: True Curve Monotonicity Violation",
                                "Price decreased despite SOL reserves increasing during consecutive buys.",
                            ));
                            break;
                        }
                    }
                }
                last_buy_price = tr.price_wad;
                last_buy_sol_reserves = tr.virtual_sol_reserves;
            }
        }

        // --------------------------------------------------------------------
        // Invariant C (Migration Conservation):
        // Virtual_Reserves == Migrated_Liquidity
        // --------------------------------------------------------------------
        if (state.is_migrated) {
            if (state.migration_virtual_reserves != state.migrated_target_liquidity) {
                findings.add(Finding.init(
                    .Critical,
                    "BC-INV-03: Migration Conservation Violation",
                    "Virtual reserves at migration threshold do not equal deposited target liquidity.",
                ));
            }
        }

        return findings;
    }
};

// Interface wrapper conforming to standard Detector signature
pub const Detector = struct {
    pub fn evaluate(state: *State) Findings {
        return BondingCurveInvariantDetector.evaluate(state);
    }
};
