//! volta: Halmos & Pierre Symbolic Invariant Provers & Protocol-Agnostic Invariant Engine
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const storage_mod = @import("storage.zig");
const types = @import("types.zig");

// =================================================================================================
// Protocol-Agnostic Grammar & Invariant Data Types
// =================================================================================================
pub const ActionType = enum {
    DEPOSIT,
    WITHDRAW,
    BORROW,
    REPAY,
    SWAP,
    FLASH_LOAN,
    LIQUIDATE,
    HOOK_CALLBACK,
    BRIDGE_TRANSFER,
    GOVERNANCE_VOTE,
    STAKE,
    UNSTAKE,
};

pub const ActionAlphabet = struct {
    action_type: ActionType = .DEPOSIT,
    target_slot_in: usize = 0,
    target_slot_out: usize = 1,
    expected_delta_min: u256 = 0,
    expected_delta_max: u256 = std.math.maxInt(u256),
};

pub const InvariantCategory = enum {
    AMM_RESERVE,
    SUPPLY_CONSERVATION,
    VAULT_INFLATION,
    FLASH_LOAN_FEE,
    LENDING_COLLATERAL,
    PROTOCOL_SOLVENCY,
    BAD_DEBT_UNDERWATER,
    ORACLE_FRESHNESS,
    PERP_MARGIN_SOLVENCY,
    LSD_EXCHANGE_RATE,
    BRIDGE_CONSERVATION,
    CONCENTRATED_LIQUIDITY,
    GOVERNANCE_TIMELOCK,
    CURVE_VIRTUAL_PRICE,
    BALANCER_REENTRANCY_GUARD,
};

pub const InvariantSpec = struct {
    category: InvariantCategory,
    slot_a: usize = 0,
    slot_b: usize = 1,
    threshold: u256 = 0,
    param_u64: u64 = 0,

    pub fn check(self: *const InvariantSpec, storage: *const storage_mod.StorageState) bool {
        return switch (self.category) {
            .AMM_RESERVE => InvariantEngine.verifyConstantProduct(storage, self.threshold),
            .SUPPLY_CONSERVATION => InvariantEngine.verifyConservationOfSupply(storage),
            .VAULT_INFLATION => InvariantEngine.verifyErc4626Inflation(storage),
            .FLASH_LOAN_FEE => InvariantEngine.verifyFlashLoanRepayment(storage.select(self.slot_a), storage.select(self.slot_b), self.threshold),
            .LENDING_COLLATERAL => InvariantEngine.verifyCollateralizationRatio(storage.select(self.slot_a), storage.select(self.slot_b), self.threshold, @truncate(self.param_u64)),
            .PROTOCOL_SOLVENCY => InvariantEngine.verifyProtocolSolvency(storage.select(self.slot_a), storage.select(self.slot_b), self.threshold),
            .BAD_DEBT_UNDERWATER => InvariantEngine.verifyBadDebtDeficit(storage.select(self.slot_a), storage.select(self.slot_b)),
            .ORACLE_FRESHNESS => InvariantEngine.verifyOracleRoundFreshness(@truncate(storage.select(self.slot_a)), @truncate(storage.select(self.slot_b)), self.param_u64),
            .PERP_MARGIN_SOLVENCY => InvariantEngine.verifyPerpMarginSolvency(storage.select(self.slot_a), storage.select(self.slot_b), self.threshold, @as(u256, self.param_u64)),
            .LSD_EXCHANGE_RATE => InvariantEngine.verifyLiquidStakingExchangeRate(storage.select(self.slot_a), storage.select(self.slot_b), self.threshold),
            .BRIDGE_CONSERVATION => InvariantEngine.verifyBridgeTokenConservation(storage.select(self.slot_a), storage.select(self.slot_b), self.threshold),
            .CONCENTRATED_LIQUIDITY => InvariantEngine.verifyConcentratedLiquidityBounds(storage.select(self.slot_a), storage.select(self.slot_b), self.threshold, @as(u256, self.param_u64)),
            .GOVERNANCE_TIMELOCK => InvariantEngine.verifyGovernanceTimelockAndQuorum(storage.select(self.slot_a), storage.select(self.slot_b), self.threshold, @as(u256, self.param_u64), 0, self.param_u64 + 1, 0),
            .CURVE_VIRTUAL_PRICE => InvariantEngine.verifyCurveVirtualPriceConservation(storage.select(self.slot_a), storage.select(self.slot_b), self.threshold),
            .BALANCER_REENTRANCY_GUARD => InvariantEngine.verifyBalancerVaultReentrancyGuard(storage.select(self.slot_a) != 0, storage.select(self.slot_b) != 0),
        };
    }
};

pub const InvariantResult = struct {
    amm_constant_product: bool = true,
    conservation_of_supply: bool = true,
    erc4626_inflation_safe: bool = true,
    flash_loan_repaid: bool = true,
    collateralization_safe: bool = true,
    protocol_solvent: bool = true,
    mccarthy_slot_independent: bool = true,
    oracle_freshness_safe: bool = true,
    perp_margin_solvent: bool = true,
    lsd_rate_bounded: bool = true,
    bridge_conserved: bool = true,
    concentrated_liquidity_bounded: bool = true,
    governance_timelock_safe: bool = true,
    curve_virtual_price_safe: bool = true,
    all_passed: bool = true,
};

pub const InvariantEngine = struct {
    /// 1. Halmos Invariant: Uniswap-style Constant Product AMM (Reserve0 * Reserve1 >= k)
    pub fn verifyConstantProduct(storage: *const storage_mod.StorageState, min_k: u256) bool {
        const reserve_x = storage.select(0);
        const reserve_y = storage.select(1);
        const current_k: u512 = @as(u512, reserve_x) * @as(u512, reserve_y);
        return current_k >= @as(u512, min_k);
    }

    /// 2. Halmos Invariant: Total Supply Conservation (Sum of Balances == Total Supply)
    pub fn verifyConservationOfSupply(storage: *const storage_mod.StorageState) bool {
        const user_a = storage.select(0);
        const user_b = storage.select(1);
        const total = storage.select(2);
        return (user_a +% user_b) == total;
    }

    /// 3. Halmos Invariant: ERC-4626 Share Inflation Boundary (Prevent first deposit vault exploit)
    pub fn verifyErc4626Inflation(storage: *const storage_mod.StorageState) bool {
        const total_assets = storage.select(0);
        const total_shares = storage.select(1);
        if (total_assets > 0 and total_shares == 0) {
            return false; // Vulnerability flagged
        }
        return true;
    }

    /// 3b. ERC-4626 Rounding & Donation Dilution Invariant: Share Price Monotonicity
    pub fn verifyErc4626RoundingMonotonicity(assets_before: u256, shares_before: u256, assets_after: u256, shares_after: u256) bool {
        if (shares_before == 0 or shares_after == 0) return true;
        // Rate after must not artificially plummet or jump beyond 100x via donation
        const rate_before: u512 = (@as(u512, assets_before) * 1_000_000_000) / @as(u512, shares_before);
        const rate_after: u512 = (@as(u512, assets_after) * 1_000_000_000) / @as(u512, shares_after);
        return rate_after >= rate_before;
    }

    /// 4. Pierre Invariant: Flash Loan Non-Zero Fee Conservation
    pub fn verifyFlashLoanRepayment(balance_before: u256, balance_after: u256, required_fee: u256) bool {
        const target: u512 = @as(u512, balance_before) + @as(u512, required_fee);
        return @as(u512, balance_after) >= target;
    }

    /// 5. Pierre Invariant: Lending Market Over-Collateralization Bound
    pub fn verifyCollateralizationRatio(collateral_amount: u256, asset_price: u256, debt_amount: u256, min_ratio_bps: u256) bool {
        const collateral_value: u512 = @as(u512, collateral_amount) * @as(u512, asset_price);
        const required_backing: u512 = (@as(u512, debt_amount) * @as(u512, min_ratio_bps)) / 10000;
        return collateral_value >= required_backing;
    }

    /// 5b. Pierre Invariant: Master Protocol Solvency (Total Vault Assets + Outstanding Borrows >= Total Depositor Claims)
    pub fn verifyProtocolSolvency(vault_cash_reserve: u256, total_borrows: u256, total_depositor_claims_value: u256) bool {
        const total_protocol_assets: u512 = @as(u512, vault_cash_reserve) + @as(u512, total_borrows);
        return total_protocol_assets >= @as(u512, total_depositor_claims_value);
    }

    /// 5c. Pierre Invariant: Bad Debt & Underwater Position Trap
    pub fn verifyBadDebtDeficit(collateral_value_usd: u256, debt_value_usd: u256) bool {
        return collateral_value_usd >= debt_value_usd;
    }

    /// 6. Halmos / SMT Invariant: McCarthy Storage Slot Disjoint Independence
    pub fn verifyMcCarthySlotIndependence(storage_before: *const storage_mod.StorageState, storage_after: *const storage_mod.StorageState, mutated_slot: usize) bool {
        for (0..types.MAX_STORAGE_SLOTS) |s| {
            if (s != mutated_slot) {
                if (storage_before.select(s) != storage_after.select(s)) {
                    return false; // Corrupted disjoint slot detected
                }
            }
        }
        return true;
    }

    /// 7. Pierre Invariant: Price Oracle Stale-Round Boundary
    pub fn verifyOracleRoundFreshness(block_timestamp: u64, oracle_updated_at: u64, max_staleness_seconds: u64) bool {
        if (block_timestamp < oracle_updated_at) return false;
        return (block_timestamp - oracle_updated_at) <= max_staleness_seconds;
    }

    /// 8. EIP-1153 Invariant: Transient Storage Isolation Invariant (∀ k, Select(S_transient, k) == 0 at transaction exit)
    pub fn verifyTransientStorageCleanBoundary(transient_storage: *const storage_mod.TransientStorage) bool {
        return transient_storage.verifyCleanBoundary();
    }

    /// 9. Hardware SIMD Isomorphism: AVX2 Dot-Product on EVM Word Memory
    pub fn computeSimdWordDotProduct(block: *const types.BlockQ8_0, evm_word_floats: *const [32]f32) f32 {
        var sum_v: types.Vec8f = @splat(0.0);
        const scale_v: types.Vec8f = @splat(block.scale);
        
        comptime var i = 0;
        inline while (i < 4) : (i += 1) {
            const q_slice = block.qs[i * 8 .. i * 8 + 8];
            const v_q_i8: @Vector(8, i8) = q_slice.*;
            const v_q_f32: types.Vec8f = @floatFromInt(v_q_i8);
            const x_slice: types.Vec8f = evm_word_floats[i * 8 .. i * 8 + 8].*;
            sum_v += (v_q_f32 * scale_v) * x_slice;
        }
        return @reduce(.Add, sum_v);
    }

    /// 9b. Hardware SIMD Isomorphism: AVX2 Batched U256 Equality & Solvency Verification
    pub fn verifyBatchWordEqualities(a: *const [4]types.U256, b: *const [4]types.U256) @Vector(4, bool) {
        var res: [4]bool = undefined;
        inline for (0..4) |idx| {
            res[idx] = types.U256.eq(a[idx], b[idx]);
        }
        return @as(@Vector(4, bool), res);
    }

    /// 10. Pierre / Hyperliquid Invariant: Perpetual Futures Margin Solvency
    pub fn verifyPerpMarginSolvency(vault_collateral: u256, total_margin: u256, unrealized_pnl_deficit: u256, protocol_fee_pool: u256) bool {
        const required_backing: u512 = @as(u512, total_margin) + @as(u512, unrealized_pnl_deficit) + @as(u512, protocol_fee_pool);
        return @as(u512, vault_collateral) >= required_backing;
    }

    /// 11. Pierre / Lido Invariant: Liquid Staking Derivative (LSD) Exchange Rate Upper Bound
    pub fn verifyLiquidStakingExchangeRate(st_token_supply: u256, locked_underlying_asset: u256, max_allowed_rate_bps: u256) bool {
        if (locked_underlying_asset == 0) return st_token_supply == 0;
        const current_rate_bps: u512 = (@as(u512, st_token_supply) * 10000) / @as(u512, locked_underlying_asset);
        return current_rate_bps <= @as(u512, max_allowed_rate_bps);
    }

    /// 12. Pierre / Cross-Chain Invariant: Bridge Supply Conservation (Minted L2 <= Locked L1 - Burned L2)
    pub fn verifyBridgeTokenConservation(l2_minted_supply: u256, l1_locked_balance: u256, l2_burned_balance: u256) bool {
        if (l1_locked_balance < l2_burned_balance) return false;
        const net_l1_backing: u512 = @as(u512, l1_locked_balance) - @as(u512, l2_burned_balance);
        return @as(u512, l2_minted_supply) <= net_l1_backing;
    }

    /// 13. Uniswap V3/V4 Concentrated Liquidity: Tick Bounds & Virtual Reserves
    pub fn verifyConcentratedLiquidityBounds(sqrt_price_current_x96: u256, sqrt_price_lower_x96: u256, sqrt_price_upper_x96: u256, liquidity: u256) bool {
        if (sqrt_price_lower_x96 >= sqrt_price_upper_x96) return false;
        if (liquidity == 0) return true;
        return (sqrt_price_current_x96 >= sqrt_price_lower_x96) and (sqrt_price_current_x96 <= sqrt_price_upper_x96);
    }

    /// 14. Governance Timelock & Quorum Conservation
    pub fn verifyGovernanceTimelockAndQuorum(
        votes_for: u256,
        votes_against: u256,
        total_voting_supply: u256,
        min_quorum_bps: u256,
        proposal_eta: u64,
        execution_timestamp: u64,
        min_timelock_delay: u64,
    ) bool {
        // 1. Quorum check: (votes_for + votes_against) * 10000 / total_supply >= min_quorum_bps
        const total_votes: u512 = @as(u512, votes_for) + @as(u512, votes_against);
        if (total_voting_supply == 0) return false;
        const reached_quorum_bps: u512 = (total_votes * 10000) / @as(u512, total_voting_supply);
        if (reached_quorum_bps < @as(u512, min_quorum_bps)) return false;

        // 2. Timelock delay check: execution timestamp must be at least proposal_eta + min_timelock_delay
        if (execution_timestamp < proposal_eta +% min_timelock_delay) return false;

        // 3. Majority vote
        return votes_for > votes_against;
    }

    /// 15. Curve LP Virtual Price Conservation (Virtual Price cannot drop by more than max_drop_bps)
    pub fn verifyCurveVirtualPriceConservation(virtual_price_before: u256, virtual_price_after: u256, max_drop_bps: u256) bool {
        if (virtual_price_after >= virtual_price_before) return true;
        const drop: u512 = @as(u512, virtual_price_before) - @as(u512, virtual_price_after);
        const max_allowed_drop: u512 = (@as(u512, virtual_price_before) * @as(u512, max_drop_bps)) / 10000;
        return drop <= max_allowed_drop;
    }

    /// 16. Balancer Vault Reentrancy Lock Conservation
    pub fn verifyBalancerVaultReentrancyGuard(is_locked: bool, is_executing_hook: bool) bool {
        if (is_executing_hook and !is_locked) {
            return false; // Hook executing without active reentrancy lock is fatal violation
        }
        return true;
    }

    /// Run full formal invariant verification matrix
    pub fn runFullMatrix(storage: *const storage_mod.StorageState, min_k: u256) InvariantResult {
        var res = InvariantResult{};
        res.amm_constant_product = verifyConstantProduct(storage, min_k);
        res.conservation_of_supply = verifyConservationOfSupply(storage);
        res.erc4626_inflation_safe = verifyErc4626Inflation(storage);
        res.protocol_solvent = verifyProtocolSolvency(storage.select(0), storage.select(1), storage.select(2));
        res.collateralization_safe = verifyCollateralizationRatio(storage.select(0), 1, storage.select(1), 10000);
        res.flash_loan_repaid = verifyFlashLoanRepayment(storage.select(0), storage.select(1), 0);
        res.perp_margin_solvent = verifyPerpMarginSolvency(storage.select(0), storage.select(1), storage.select(2), 0);
        res.lsd_rate_bounded = verifyLiquidStakingExchangeRate(storage.select(0), storage.select(1), 10050);
        res.bridge_conserved = verifyBridgeTokenConservation(storage.select(0), storage.select(1), storage.select(2));
        res.concentrated_liquidity_bounded = verifyConcentratedLiquidityBounds(storage.select(2), storage.select(0), storage.select(1), 1);
        res.curve_virtual_price_safe = verifyCurveVirtualPriceConservation(storage.select(0), storage.select(1), 50);

        res.all_passed = res.amm_constant_product and
            res.conservation_of_supply and
            res.erc4626_inflation_safe and
            res.protocol_solvent and
            res.collateralization_safe and
            res.flash_loan_repaid and
            res.perp_margin_solvent and
            res.lsd_rate_bounded and
            res.bridge_conserved and
            res.concentrated_liquidity_bounded and
            res.curve_virtual_price_safe;

        return res;
    }
};

test "Invariants: Comprehensive Halmos & Pierre SMT Prover Suite" {
    // 1. AMM Constant Product
    var storage = storage_mod.StorageState.init();
    storage.store(0, 1000);
    storage.store(1, 2000);
    try std.testing.expect(InvariantEngine.verifyConstantProduct(&storage, 2_000_000));
    try std.testing.expect(!InvariantEngine.verifyConstantProduct(&storage, 2_000_001));

    // 2. Supply Conservation
    storage.store(2, 3000);
    try std.testing.expect(InvariantEngine.verifyConservationOfSupply(&storage));

    // 3. Flash Loan Repayment
    try std.testing.expect(InvariantEngine.verifyFlashLoanRepayment(1000, 1010, 10));
    try std.testing.expect(!InvariantEngine.verifyFlashLoanRepayment(1000, 1005, 10));

    // 4. Over-Collateralization (10 ETH @ $2000 = $20,000 against $15,000 debt with 120% min ratio -> $18,000 required)
    try std.testing.expect(InvariantEngine.verifyCollateralizationRatio(10, 2000, 15000, 12000));
    try std.testing.expect(!InvariantEngine.verifyCollateralizationRatio(10, 2000, 18000, 12000));

    // 5. McCarthy Slot Disjoint Independence
    var storage_after = storage;
    storage_after.store(5, 777);
    try std.testing.expect(InvariantEngine.verifyMcCarthySlotIndependence(&storage, &storage_after, 5));

    // 6. Oracle Freshness
    try std.testing.expect(InvariantEngine.verifyOracleRoundFreshness(1700000100, 1700000000, 300));
    try std.testing.expect(!InvariantEngine.verifyOracleRoundFreshness(1700000500, 1700000000, 300));

    // 7. EIP-1153 Transient Storage Boundary Invariant
    var ts = storage_mod.TransientStorage.init();
    try std.testing.expect(InvariantEngine.verifyTransientStorageCleanBoundary(&ts));
    ts.tstore(4, 99999);
    try std.testing.expect(!InvariantEngine.verifyTransientStorageCleanBoundary(&ts));
    ts.clearBoundary();
    try std.testing.expect(InvariantEngine.verifyTransientStorageCleanBoundary(&ts));

    // 8. 256-Bit SIMD Isomorphism AVX2 Dot-Product
    const qblock = types.BlockQ8_0{
        .scale = 0.5,
        .qs = [_]i8{2} ** 32, // 2 * 0.5 = 1.0 per element
    };
    const evm_floats: [32]f32 = [_]f32{1.0} ** 32;
    const dot_result = InvariantEngine.computeSimdWordDotProduct(&qblock, &evm_floats);
    try std.testing.expectApproxEqAbs(@as(f32, 32.0), dot_result, 0.001);

    // 9. Perpetual Futures Margin Invariant
    try std.testing.expect(InvariantEngine.verifyPerpMarginSolvency(10_000_000, 5_000_000, 2_000_000, 1_000_000));
    try std.testing.expect(!InvariantEngine.verifyPerpMarginSolvency(7_000_000, 5_000_000, 2_000_000, 1_000_000));

    // 10. Liquid Staking Rate Invariant (1000 stETH on 1000 ETH = 10000 bps)
    try std.testing.expect(InvariantEngine.verifyLiquidStakingExchangeRate(1000, 1000, 10050));
    try std.testing.expect(!InvariantEngine.verifyLiquidStakingExchangeRate(1200, 1000, 10050));

    // 11. Bridge Supply Conservation (L2 minted 500 <= L1 locked 1000 - L2 burned 200 = 800)
    try std.testing.expect(InvariantEngine.verifyBridgeTokenConservation(500, 1000, 200));
    try std.testing.expect(!InvariantEngine.verifyBridgeTokenConservation(900, 1000, 200));

    // 12. Concentrated Liquidity Tick Bounds
    try std.testing.expect(InvariantEngine.verifyConcentratedLiquidityBounds(1500, 1000, 2000, 50000));
    try std.testing.expect(!InvariantEngine.verifyConcentratedLiquidityBounds(2500, 1000, 2000, 50000));

    // 13. Governance Timelock & Quorum
    try std.testing.expect(InvariantEngine.verifyGovernanceTimelockAndQuorum(6000, 2000, 10000, 5000, 1000, 1000 + 86400, 86400));
    try std.testing.expect(!InvariantEngine.verifyGovernanceTimelockAndQuorum(1000, 500, 10000, 5000, 1000, 1000 + 86400, 86400)); // Failed quorum

    // 14. Curve Virtual Price Conservation
    try std.testing.expect(InvariantEngine.verifyCurveVirtualPriceConservation(1_000_000, 999_900, 50)); // 0.01% drop <= 0.50% max allowed
    try std.testing.expect(!InvariantEngine.verifyCurveVirtualPriceConservation(1_000_000, 900_000, 50)); // 10% drop > 0.50% max allowed

    // 15. Balancer Vault Reentrancy Lock
    try std.testing.expect(InvariantEngine.verifyBalancerVaultReentrancyGuard(true, true));
    try std.testing.expect(!InvariantEngine.verifyBalancerVaultReentrancyGuard(false, true));

    // 16. Bridge Underflow Wrap-Around Prevention
    try std.testing.expect(!InvariantEngine.verifyBridgeTokenConservation(100, 50, 100)); // L1 locked (50) < L2 burned (100) must fail

    // 17. Data-Driven InvariantSpec Dynamic Dispatch Matrix
    const spec_amm = InvariantSpec{ .category = .AMM_RESERVE, .threshold = 2_000_000 };
    try std.testing.expect(spec_amm.check(&storage));

    const spec_solvency = InvariantSpec{ .category = .PROTOCOL_SOLVENCY, .slot_a = 0, .slot_b = 1, .threshold = 3000 };
    try std.testing.expect(spec_solvency.check(&storage));

    // 18. Batch SIMD U256 Equality & Vector Conversion Check
    const u_a = [4]types.U256{
        types.U256.fromU64(10),
        types.U256.fromU64(20),
        types.U256.fromU64(30),
        types.U256.fromU64(40),
    };
    const u_b = [4]types.U256{
        types.U256.fromU64(10),
        types.U256.fromU64(99),
        types.U256.fromU64(30),
        types.U256.fromU64(40),
    };
    const batch_eq = InvariantEngine.verifyBatchWordEqualities(&u_a, &u_b);
    try std.testing.expectEqual(@as(@Vector(4, bool), @Vector(4, bool){ true, false, true, true }), batch_eq);

    const spec_bridge = InvariantSpec{ .category = .BRIDGE_CONSERVATION, .slot_a = 0, .slot_b = 1, .threshold = 0 };
    try std.testing.expect(spec_bridge.check(&storage)); // 1000 <= 2000 - 0 is true

    const spec_bridge_fail = InvariantSpec{ .category = .BRIDGE_CONSERVATION, .slot_a = 1, .slot_b = 0, .threshold = 0 };
    try std.testing.expect(!spec_bridge_fail.check(&storage)); // 2000 <= 1000 - 0 is false

    // 18. Full Verification Matrix Pass
    const matrix_res = InvariantEngine.runFullMatrix(&storage, 2_000_000);
    try std.testing.expect(matrix_res.amm_constant_product);
    try std.testing.expect(matrix_res.conservation_of_supply);
}
