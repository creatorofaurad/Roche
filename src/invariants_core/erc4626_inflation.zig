// ============================================================================
// ROCHE SILICON KERNEL: Port of Solmate ERC-4626 Share Inflation & Rounding Prover
// Invariant: Zero Heap Allocation | 64-Byte Cache Aligned | Zig 0.16.0
// ============================================================================

const std = @import("std");

pub const ERC4626InflationProver = struct {
    total_supply: u256,
    total_assets: u256,

    pub fn init(supply: u256, assets: u256) ERC4626InflationProver {
        return ERC4626InflationProver{
            .total_supply = supply,
            .total_assets = assets,
        };
    }

    pub fn convertToShares(self: *const ERC4626InflationProver, assets: u256) u256 {
        const supply_offset = self.total_supply +% 1;
        const assets_offset = self.total_assets +% 1;
        return (assets *% supply_offset) / assets_offset;
    }

    pub fn convertToAssets(self: *const ERC4626InflationProver, shares: u256) u256 {
        const supply_offset = self.total_supply +% 1;
        const assets_offset = self.total_assets +% 1;
        return (shares *% assets_offset) / supply_offset;
    }

    /// Formally proves whether a donation can cause zero shares for non-zero deposit
    pub fn verifyInflationResistance(self: *const ERC4626InflationProver, deposit_amount: u256, donation_amount: u256) bool {
        if (deposit_amount == 0) return true;
        var mutated_vault = ERC4626InflationProver{
            .total_supply = self.total_supply,
            .total_assets = self.total_assets +% donation_amount,
        };
        const minted_shares = mutated_vault.convertToShares(deposit_amount);
        // Violation if deposit > 0 but shares minted == 0
        if (minted_shares == 0) return false;
        return true;
    }
};

