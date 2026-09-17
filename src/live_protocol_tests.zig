//! live_protocol_tests.zig: Comprehensive Real-World Protocol Attack Suite for Volta
//! Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const types = @import("types.zig");
const storage = @import("storage.zig");
const fuzzer = @import("fuzzer.zig");
const cfg = @import("cfg.zig");
const detectors = @import("detectors.zig");
const invariants = @import("invariants.zig");
const vm = @import("vm.zig");
const arena = @import("arena.zig");
const main_mod = @import("main.zig");

// =================================================================================================
// 1. EULER V2 PROTOCOL: Vault Donation & Exchange Rate Inflation Vector
// Bytecode Simulates: Deposit -> Direct Balance Transfer/Donation -> Inflated Share Calculation
// =================================================================================================
pub const EULER_VAULT_DONATION_BYTECODE = [_]u8{
    // Block 0: Initialize Assets = 1000, Shares = 1000
    0x61, 0x03, 0xE8, 0x60, 0x00, 0x55, // SSTORE 1000 to Slot 0 (total_assets)
    0x61, 0x03, 0xE8, 0x60, 0x01, 0x55, // SSTORE 1000 to Slot 1 (total_shares)
    // Block 1: External CALL (Attacker donation callback)
    0x60, 0x00, 0xF1,                   // CALL (External invocation)
    // Block 2: Mutate total_assets = 100,000 without minting shares
    0x62, 0x01, 0x86, 0xA0, 0x60, 0x00, 0x55, // SSTORE 100,000 to Slot 0 (donation inflation)
    0x00,                               // STOP
};

// =================================================================================================
// 2. UNISWAP V4 HOOK KERNEL: Malicious Hook Draining Pool Liquidity (k violation)
// Bytecode Simulates: Swap Reserve Mutator violating Constant Product Invariant
// =================================================================================================
pub const UNISWAP_V4_MALICIOUS_HOOK_BYTECODE = [_]u8{
    // Initialize Reserves: Reserve0 = 2,000,000, Reserve1 = 5,000,000 (k = 10,000,000,000,000)
    0x62, 0x1E, 0x84, 0x80, 0x60, 0x00, 0x55, // SSTORE 2,000,000 to Slot 0
    0x62, 0x4C, 0x4B, 0x40, 0x60, 0x01, 0x55, // SSTORE 5,000,000 to Slot 1
    // Malicious Hook: Decreases Reserve0 to 1,000,000 without adjusting Reserve1
    0x62, 0x0F, 0x42, 0x40, 0x60, 0x00, 0x55, // SSTORE 1,000,000 to Slot 0 (Drained)
    0x00,
};

// =================================================================================================
// 3. ETHENA sUSDe PSM: ERC-4626 First-Deposit Inflation (Zero-Share Drain)
// Bytecode Simulates: Assets deposited (1,000,000) when Total Shares = 0
// =================================================================================================
pub const ETHENA_PSM_SHARE_INFLATION_BYTECODE = [_]u8{
    // Set total_assets = 1,000,000, total_shares = 0
    0x62, 0x0F, 0x42, 0x40, 0x60, 0x00, 0x55, // SSTORE 1,000,000 to Slot 0 (total_assets)
    0x60, 0x00, 0x60, 0x01, 0x55,             // SSTORE 0 to Slot 1 (total_shares)
    0x00,
};

// =================================================================================================
// 4. FLASH LOAN LENDING POOL: Reentrancy & Deficit Flash Loan Repayment
// Bytecode Simulates: Unchecked Flash Loan with Reentrancy & Unrepaid Fee
// =================================================================================================
pub const FLASH_LOAN_REENTRANCY_BYTECODE = [_]u8{
    // External Flash Loan Receiver Callback
    0x60, 0x00, 0xF1,                         // CALL (External execution)
    // SLOAD Vault Balance
    0x60, 0x00, 0x54,                         // SLOAD Slot 0 (balance)
    // SSTORE Deficit Balance
    0x61, 0x01, 0xF4, 0x60, 0x00, 0x55,       // SSTORE 500 to Slot 0 (State update after call)
    0x00,
};

// =================================================================================================
// 5. COMPOUND / AAVE / MORPHO PROTOCOL: Insolvency & Bad-Debt Liquidation Cascade Suite
// Bytecode Simulates: Collateral Price Crash ($2000 -> $800) triggering underwater insolvency deficit
// =================================================================================================
pub const LENDING_INSOLVENCY_CRASH_BYTECODE = [_]u8{
    // Initialize Lending Vault: Slot 0 (Cash Reserve) = 1,000,000, Slot 1 (Total Borrows) = 4,000,000
    0x62, 0x0F, 0x42, 0x40, 0x60, 0x00, 0x55, // SSTORE 1,000,000 to Slot 0
    0x62, 0x3D, 0x09, 0x00, 0x60, 0x01, 0x55, // SSTORE 4,000,000 to Slot 1
    // Total Depositor Claims in Slot 2 = 5,000,000 (Solvent: 1M + 4M = 5M)
    0x62, 0x4C, 0x4B, 0x40, 0x60, 0x02, 0x55, // SSTORE 5,000,000 to Slot 2
    // Bad Debt Event: Unrecoverable Default reduces Total Borrows by 2,000,000 without cash recovery
    0x62, 0x1E, 0x84, 0x80, 0x60, 0x01, 0x55, // SSTORE 2,000,000 to Slot 1 (Defaulted / Written off)
    0x00,
};

// =================================================================================================
// 6. CURVE LP: Precision Truncation & Virtual Price Manipulation Attack
// Bytecode Simulates: Integer division before multiplication in D calculation
// =================================================================================================
pub const CURVE_PRECISION_TRUNCATION_BYTECODE = [_]u8{
    // PUSH 1000, PUSH 7, DIV, PUSH 7, MUL -> Truncation precision loss
    0x60, 0x07, 0x61, 0x03, 0xE8, 0x04, 0x60, 0x07, 0x02, 0x60, 0x00, 0x55,
    0x00,
};

// =================================================================================================
// 7. BALANCER VAULT: Read-Only Reentrancy State Manipulation
// Bytecode Simulates: Query Pool State during external callback
// =================================================================================================
pub const BALANCER_READ_ONLY_REENTRANCY_BYTECODE = [_]u8{
    0x60, 0x00, 0xF1, // CALL external hook
    0x60, 0x00, 0x54, // SLOAD (Read-only view during hook execution)
    0x00,
};

// =================================================================================================
// 8. HYPERLIQUID / GMX: Perp Margin Insolvency & Liquidator Deficit
// Bytecode Simulates: Collateral deficit where Margin + Unrealized PnL > Vault Backing
// =================================================================================================
pub const PERP_MARGIN_DEFICIT_BYTECODE = [_]u8{
    // Slot 0 (Vault Backing) = 7,000,000
    0x62, 0x6A, 0xCF, 0xC0, 0x60, 0x00, 0x55,
    // Slot 1 (Required Margin) = 5,000,000
    0x62, 0x4C, 0x4B, 0x40, 0x60, 0x01, 0x55,
    // Slot 2 (Unrealized Loss) = 3,000,000 (Total required = 8M > 7M backing)
    0x62, 0x2D, 0xC6, 0xC0, 0x60, 0x02, 0x55,
    0x00,
};

// =================================================================================================
// 9. MULTICHAIN / LAYERZERO: Cross-Chain Token Bridge Conservation Breach
// Bytecode Simulates: L2 Minting exceeds L1 locked reserves
// =================================================================================================
pub const BRIDGE_CONSERVATION_BREACH_BYTECODE = [_]u8{
    // Slot 0 (L1 Locked) = 1,000,000
    0x62, 0x0F, 0x42, 0x40, 0x60, 0x00, 0x55,
    // Slot 1 (L2 Minted) = 1,500,000 (Unbacked inflation!)
    0x62, 0x16, 0xE3, 0x60, 0x60, 0x01, 0x55,
    0x00,
};

// =================================================================================================
// 10. LIDO / ROCKETPOOL: Liquid Staking Derivative (LSD) Depeg & Exchange Rate Inflation
// Bytecode Simulates: stETH rate inflated beyond mathematical boundary
// =================================================================================================
pub const LSD_EXCHANGE_RATE_DEPEG_BYTECODE = [_]u8{
    // Slot 0 (stToken Supply) = 1,200,000
    0x62, 0x12, 0x4F, 0x80, 0x60, 0x00, 0x55,
    // Slot 1 (Locked ETH) = 1,000,000 (Rate = 1.20 > 1.005 max bound)
    0x62, 0x0F, 0x42, 0x40, 0x60, 0x01, 0x55,
    0x00,
};

// =================================================================================================
// 11. UNISWAP V3/V4: Concentrated Liquidity Tick Bounds Out-of-Range Violation
// Bytecode Simulates: Current SqrtPrice pushed outside [lower, upper] active tick range
// =================================================================================================
pub const CONCENTRATED_LIQUIDITY_TICK_BREACH_BYTECODE = [_]u8{
    // Slot 0 (Lower SqrtPrice) = 1000
    0x61, 0x03, 0xE8, 0x60, 0x00, 0x55,
    // Slot 1 (Upper SqrtPrice) = 2000
    0x61, 0x07, 0xD0, 0x60, 0x01, 0x55,
    // Slot 2 (Current SqrtPrice) = 2500 (Out of bounds!)
    0x61, 0x09, 0xC4, 0x60, 0x02, 0x55,
    0x00,
};

test "Live Target 1: Euler V2 Vault Donation & Reentrancy Vulnerability Detection" {
    var engine = main_mod.VoltaEngine.init();

    // 1. Static CFG & Slither-Style Taint Audit
    const audit = engine.audit(&EULER_VAULT_DONATION_BYTECODE);
    try std.testing.expect(audit.reentrancy);

    // 2. Execution & State Check
    const status = engine.execute(&EULER_VAULT_DONATION_BYTECODE);
    try std.testing.expectEqual(types.ExecutionStatus.SUCCESS, status);

    // 3. Verify Reserve/Asset Delta
    const assets = engine.vm_core.storage.select(0);
    const shares = engine.vm_core.storage.select(1);
    try std.testing.expectEqual(@as(u256, 100_000), assets);
    try std.testing.expectEqual(@as(u256, 1_000), shares);
}

test "Live Target 2: Uniswap V4 Hook Pool Liquidity Drain (k invariant violation)" {
    var engine = main_mod.VoltaEngine.init();
    _ = engine.execute(&UNISWAP_V4_MALICIOUS_HOOK_BYTECODE);

    // Initial Expected k: 2,000,000 * 5,000,000 = 10,000,000,000,000
    const initial_min_k: u256 = 10_000_000_000_000;
    const invariant_holds = engine.verifyAmm(initial_min_k);

    // Invariant MUST FAIL because Reserve0 was drained to 1,000,000 (Current k = 5,000,000,000,000)
    try std.testing.expect(!invariant_holds);
}

test "Live Target 3: Ethena PSM ERC-4626 First-Deposit Share Inflation Barrier" {
    var engine = main_mod.VoltaEngine.init();
    _ = engine.execute(&ETHENA_PSM_SHARE_INFLATION_BYTECODE);

    // Invariant: Assets > 0 while Shares == 0 must trigger violation
    const erc4626_safe = invariants.InvariantEngine.verifyErc4626Inflation(&engine.vm_core.storage);
    try std.testing.expect(!erc4626_safe);
}

test "Live Target 4: Flash Loan Arbitrage Callback Reentrancy & Deficit" {
    var engine = main_mod.VoltaEngine.init();

    // Static Audit catches state write after external callback
    const audit = engine.audit(&FLASH_LOAN_REENTRANCY_BYTECODE);
    try std.testing.expect(audit.reentrancy);

    // Mathematical SMT Invariant: Flash loan repayment
    const repaid = invariants.InvariantEngine.verifyFlashLoanRepayment(1000, 500, 9);
    try std.testing.expect(!repaid);
}

test "Live Target 5: 10,000-Run Live Gauntlet on Real Protocol Attack Suite" {
    var arena_inst = arena.ArenaHarness.init(0x9999AAAA1111);

    const target_suite = [_][]const u8{
        &EULER_VAULT_DONATION_BYTECODE,
        &UNISWAP_V4_MALICIOUS_HOOK_BYTECODE,
        &ETHENA_PSM_SHARE_INFLATION_BYTECODE,
        &FLASH_LOAN_REENTRANCY_BYTECODE,
        &LENDING_INSOLVENCY_CRASH_BYTECODE,
        &CURVE_PRECISION_TRUNCATION_BYTECODE,
        &BALANCER_READ_ONLY_REENTRANCY_BYTECODE,
        &PERP_MARGIN_DEFICIT_BYTECODE,
        &BRIDGE_CONSERVATION_BREACH_BYTECODE,
        &LSD_EXCHANGE_RATE_DEPEG_BYTECODE,
        &CONCENTRATED_LIQUIDITY_TICK_BREACH_BYTECODE,
    };

    const summary = arena_inst.runTenThousandGauntlet(&target_suite);
    try std.testing.expectEqual(@as(u32, 10000), summary.total_runs);
    try std.testing.expect(summary.passed_runs > 0);
    try std.testing.expect(summary.total_edges_discovered > 0);
}

test "Live Target 6: Master Protocol Insolvency & Bad-Debt Cascade Trap" {
    var engine = main_mod.VoltaEngine.init();
    _ = engine.execute(&LENDING_INSOLVENCY_CRASH_BYTECODE);

    const cash_reserve = engine.vm_core.storage.select(0);   // 1,000,000
    const total_borrows = engine.vm_core.storage.select(1);  // 2,000,000 (Deficit)
    const depositor_claims = engine.vm_core.storage.select(2); // 5,000,000

    // Master Solvency Invariant: Cash (1M) + Borrows (2M) = 3M < 5M Claims -> PROTOCOL IS INSOLVENT!
    const is_solvent = invariants.InvariantEngine.verifyProtocolSolvency(cash_reserve, total_borrows, depositor_claims);
    try std.testing.expect(!is_solvent);

    // Position-Level Underwater Bad-Debt Invariant Check:
    const position_solvent = invariants.InvariantEngine.verifyBadDebtDeficit(1600, 2000);
    try std.testing.expect(!position_solvent);
}

test "Live Target 7: Curve LP Precision Truncation & Division Detection" {
    var engine = main_mod.VoltaEngine.init();
    const audit = engine.audit(&CURVE_PRECISION_TRUNCATION_BYTECODE);
    try std.testing.expect(audit.divide_before_multiply);

    _ = engine.execute(&CURVE_PRECISION_TRUNCATION_BYTECODE);
    // Integer division 1000 / 7 * 7 = 142 * 7 = 994 (lost 6 units of precision)
    const result_slot0 = engine.vm_core.storage.select(0);
    try std.testing.expectEqual(@as(u256, 994), result_slot0);
}

test "Live Target 8: Balancer Vault Read-Only Reentrancy Guard Trap" {
    var engine = main_mod.VoltaEngine.init();
    const audit = engine.audit(&BALANCER_READ_ONLY_REENTRANCY_BYTECODE);
    try std.testing.expect(audit.read_only_reentrancy);

    // Formal Reentrancy Lock Invariant: hook running with unlocked vault is a breach
    try std.testing.expect(!invariants.InvariantEngine.verifyBalancerVaultReentrancyGuard(false, true));
    try std.testing.expect(invariants.InvariantEngine.verifyBalancerVaultReentrancyGuard(true, true));
}

test "Live Target 9: Perpetual Futures Margin Solvency Deficit Trap" {
    var engine = main_mod.VoltaEngine.init();
    _ = engine.execute(&PERP_MARGIN_DEFICIT_BYTECODE);

    const vault_backing = engine.vm_core.storage.select(0); // 7M
    const total_margin = engine.vm_core.storage.select(1);  // 5M
    const unrealized_loss = engine.vm_core.storage.select(2); // 3M
    const fee_pool: u256 = 500_000;

    // Invariant: Backing 7M < Required 8.5M -> Solvency breach!
    const is_solvent = invariants.InvariantEngine.verifyPerpMarginSolvency(vault_backing, total_margin, unrealized_loss, fee_pool);
    try std.testing.expect(!is_solvent);
}

test "Live Target 10: Multichain Cross-Chain Bridge Token Conservation Trap" {
    var engine = main_mod.VoltaEngine.init();
    _ = engine.execute(&BRIDGE_CONSERVATION_BREACH_BYTECODE);

    const l1_locked = engine.vm_core.storage.select(0); // 1,000,000
    const l2_minted = engine.vm_core.storage.select(1); // 1,500,000
    const l2_burned: u256 = 0;

    // Bridge Invariant: Minted 1.5M <= Locked 1.0M - Burned 0 -> FAILS!
    const is_conserved = invariants.InvariantEngine.verifyBridgeTokenConservation(l2_minted, l1_locked, l2_burned);
    try std.testing.expect(!is_conserved);
}

test "Live Target 11: Liquid Staking LSD Exchange Rate Depeg Barrier" {
    var engine = main_mod.VoltaEngine.init();
    _ = engine.execute(&LSD_EXCHANGE_RATE_DEPEG_BYTECODE);

    const st_supply = engine.vm_core.storage.select(0); // 1,200,000
    const locked_eth = engine.vm_core.storage.select(1); // 1,000,000

    // LSD Invariant: Rate is 12,000 bps > Max allowed 10,050 bps -> Depeg detected!
    const rate_safe = invariants.InvariantEngine.verifyLiquidStakingExchangeRate(st_supply, locked_eth, 10050);
    try std.testing.expect(!rate_safe);
}

test "Live Target 12: Concentrated Liquidity Tick Bounds Out-of-Range Violation" {
    var engine = main_mod.VoltaEngine.init();
    _ = engine.execute(&CONCENTRATED_LIQUIDITY_TICK_BREACH_BYTECODE);

    const lower_sqrt_p = engine.vm_core.storage.select(0); // 1000
    const upper_sqrt_p = engine.vm_core.storage.select(1); // 2000
    const current_sqrt_p = engine.vm_core.storage.select(2); // 2500

    // Tick Invariant: 2500 is outside [1000, 2000] active range
    const bounds_safe = invariants.InvariantEngine.verifyConcentratedLiquidityBounds(current_sqrt_p, lower_sqrt_p, upper_sqrt_p, 10000);
    try std.testing.expect(!bounds_safe);
}

// =================================================================================================
// 12. ENZYME BLUE PROTOCOL: Single Asset Redemption Queue & GAV Conservation
// Bytecode Simulates: ComptrollerLib GAV Rebalance & Queue Dispersal
// =================================================================================================
pub const ENZYME_BLUE_REDEMPTION_BYTECODE = [_]u8{
    // Slot 0 (GAV Before) = 1,000,000 ether (1e24)
    0x61, 0x03, 0xE8, 0x60, 0x00, 0x55,
    // External CALL to integration adapter
    0x60, 0x00, 0xF1,
    // Slot 1 (GAV After) = 900,000 ether (Unaccounted slippage drain!)
    0x61, 0x03, 0x84, 0x60, 0x01, 0x55,
    0x00,
};

test "Live Target 13: Enzyme Blue Single Asset Redemption Queue & GAV Conservation" {
    var engine = main_mod.VoltaEngine.init();

    // 1. Static Audit: Check CEI on external adapter call
    const audit = engine.audit(&ENZYME_BLUE_REDEMPTION_BYTECODE);
    try std.testing.expect(audit.reentrancy);

    // 2. Execute bytecode
    _ = engine.execute(&ENZYME_BLUE_REDEMPTION_BYTECODE);
    const gav_before = engine.vm_core.storage.select(0);
    const gav_after = engine.vm_core.storage.select(1);

    // 3. Enzyme Invariant: GAV monotonicity during rebalance
    const gav_monotonic = invariants.InvariantEngine.verifyGavMonotonicity(gav_before, gav_after);
    try std.testing.expect(!gav_monotonic);

    // 4. Redemption Queue Conservation: Burn 100 shares @ $1.50 (1.5e18) -> Expect >= 150 units
    const valid_redemption = invariants.InvariantEngine.verifyRedemptionConservation(100, 150, 1_500_000_000_000_000_000);
    try std.testing.expect(valid_redemption);

    const defective_redemption = invariants.InvariantEngine.verifyRedemptionConservation(100, 120, 1_500_000_000_000_000_000);
    try std.testing.expect(!defective_redemption);
}

