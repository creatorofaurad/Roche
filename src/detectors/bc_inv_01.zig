//! bc_inv_01.zig: Deterministic Zero-Heap Bonding Curve Invariant Verification Engine
//! Part of ROCHE Silicon EVM/SVM Formal Security Engine.
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.
//! Invariant: Zero Heap Allocation (`malloc=0`) | Fixed-Capacity Ring Buffers | 256-Bit Fixed Point Arithmetic.

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
    price_wad: u256 = 0, // Scaled by 1e18 (virtual_sol_reserves * 1e18 / virtual_token_reserves)
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

        // Prevent division by zero
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
// INVARIANT DETECTOR IMPLEMENTATION
// ============================================================================

pub const BondingCurveInvariantDetector = struct {
    pub fn evaluate(state: *const State) Findings {
        var findings = Findings{};

        // --------------------------------------------------------------------
        // Invariant A (Fee Monotonicity):
        // The sum of all marginal fees extracted across N state transitions
        // must exactly equal the protocol fee pool balance.
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
        // Invariant B (Curve Monotonicity):
        // For any consecutive sequence of buy transactions: P(t+1) >= P(t)
        // (A Sell transaction reduces the price and resets the consecutive buy sequence)
        // --------------------------------------------------------------------
        var last_buy_price: ?u256 = null;

        for (0..state.transition_count) |i| {
            const tr = state.transitions[i];
            if (tr.transition_type == .Buy) {
                if (last_buy_price) |prev_price| {
                    if (tr.price_wad < prev_price) {
                        findings.add(Finding.init(
                            .Critical,
                            "BC-INV-02: Curve Monotonicity Violation",
                            "Marginal price decreased after consecutive buy execution on bonding curve.",
                        ));
                        break;
                    }
                }
                last_buy_price = tr.price_wad;
            } else if (tr.transition_type == .Sell) {
                // A Sell legitimately decreases the curve reserves, resetting consecutive buy sequence
                last_buy_price = null;
            }
        }

        // --------------------------------------------------------------------
        // Invariant C (Migration Conservation):
        // When market cap threshold is reached and liquidity is migrated,
        // the virtual reserves in the bonding curve must exactly equal the
        // liquidity deposited into the target pool.
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

// ============================================================================
// COMPILE-TIME FORMAL CHECKS & UNIT TESTS
// ============================================================================

test "BC-INV: Perfect trace satisfies all invariants" {
    var state = State.init();

    // Consecutive buys with price increasing and fees accumulating
    state.recordTransition(.Buy, 30_000_000_000, 1_000_000_000_000_000, 300_000_000);
    state.recordTransition(.Buy, 35_000_000_000, 950_000_000_000_000, 350_000_000);
    state.recordTransition(.Buy, 40_000_000_000, 900_000_000_000_000, 400_000_000);

    state.protocol_fee_pool_balance = 300_000_000 + 350_000_000 + 400_000_000;
    state.setMigrationState(85_000_000_000, 85_000_000_000);

    const findings = BondingCurveInvariantDetector.evaluate(&state);
    try std.testing.expectEqual(@as(usize, 0), findings.count);
    try std.testing.expect(!findings.hasFindings());
}

test "BC-INV-01: Detects fee mismatch divergence" {
    var state = State.init();
    state.recordTransition(.Buy, 30_000_000_000, 1_000_000_000_000_000, 300_000_000);
    state.protocol_fee_pool_balance = 299_999_999; // 1 unit lost

    const findings = BondingCurveInvariantDetector.evaluate(&state);
    try std.testing.expect(findings.hasFindings());
    try std.testing.expectEqual(Severity.High, findings.items[0].severity);
}

test "BC-INV-02: Detects price decrease during buy sequence" {
    var state = State.init();
    state.recordTransition(.Buy, 40_000_000_000, 900_000_000_000_000, 0);
    // Artificially inverted price
    state.recordTransition(.Buy, 30_000_000_000, 1_000_000_000_000_000, 0);
    state.protocol_fee_pool_balance = 0;

    const findings = BondingCurveInvariantDetector.evaluate(&state);
    try std.testing.expect(findings.hasFindings());
    try std.testing.expectEqual(Severity.Critical, findings.items[0].severity);
}

test "BC-INV-03: Detects liquidity mismatch during migration" {
    var state = State.init();
    state.setMigrationState(85_000_000_000, 84_999_999_000);

    const findings = BondingCurveInvariantDetector.evaluate(&state);
    try std.testing.expect(findings.hasFindings());
    try std.testing.expectEqual(Severity.Critical, findings.items[0].severity);
}

test "BC-INV: Real Mainnet Trace (Extracted from Solana Mainnet BBK Curve)" {
    var state = State.init();

    // Chronological transitions extracted live from pump_trace.json:
    // Transition 0: Sell
    state.recordTransition(.Sell, 1557875627, 803848634255183, 0);
    // Transition 1: Buy
    state.recordTransition(.Buy, 1958692003, 799816794776009, 0);
    // Transition 2: Buy (Price: 2451032420161 >= 2448925823755, Fee: 8002)
    state.recordTransition(.Buy, 1959534268, 799473010590053, 8002);
    // Transition 3: Buy (Price: 2870838936900 >= 2451032420161)
    state.recordTransition(.Buy, 2287464248, 796792957834807, 0);
    // Transition 4: Sell
    state.recordTransition(.Sell, 1932620786, 799277537702711, 0);
    // Transition 5: Buy
    state.recordTransition(.Buy, 2427282615, 795178695242025, 0);
    // Transition 6: Sell
    state.recordTransition(.Sell, 2129025083, 797146741587915, 0);
    // Transition 7: Sell
    state.recordTransition(.Sell, 1214367388, 804028444959143, 0);
    // Transition 8: Buy
    state.recordTransition(.Buy, 1453688967, 800872394069730, 0);

    state.protocol_fee_pool_balance = 8002;
    state.is_migrated = false;

    const findings = BondingCurveInvariantDetector.evaluate(&state);
    try std.testing.expectEqual(@as(usize, 0), findings.count);
    try std.testing.expect(!findings.hasFindings());
}

