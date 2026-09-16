//! volta: Formal Invariant Solvers & Mathematical Proofs
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const storage_mod = @import("storage.zig");

pub const InvariantEngine = struct {
    /// Prove Uniswap-style Constant Product AMM Invariant: Slot[0] * Slot[1] >= k
    pub fn verifyConstantProduct(storage: *const storage_mod.StorageState, min_k: u256) bool {
        const reserve_x = storage.select(0);
        const reserve_y = storage.select(1);
        const current_k: u512 = @as(u512, reserve_x) * @as(u512, reserve_y);
        return current_k >= @as(u512, min_k);
    }

    /// Prove Total Supply Conservation: Slot[0] + Slot[1] == Slot[2]
    pub fn verifyConservationOfSupply(storage: *const storage_mod.StorageState) bool {
        const user_a = storage.select(0);
        const user_b = storage.select(1);
        const total = storage.select(2);
        return (user_a +% user_b) == total;
    }

    /// Prove ERC-4626 Share Inflation Invariant: totalAssets > 0 => totalShares > 0
    pub fn verifyErc4626Inflation(storage: *const storage_mod.StorageState) bool {
        const total_assets = storage.select(0);
        const total_shares = storage.select(1);
        if (total_assets > 0 and total_shares == 0) {
            return false; // Share inflation / first deposit donation vulnerability
        }
        return true;
    }
};

test "Invariants: AMM & Conservation Proofs" {
    var storage = storage_mod.StorageState.init();
    storage.store(0, 1000);
    storage.store(1, 2000);
    try std.testing.expect(InvariantEngine.verifyConstantProduct(&storage, 2_000_000));
    try std.testing.expect(!InvariantEngine.verifyConstantProduct(&storage, 2_000_001));

    storage.store(2, 3000);
    try std.testing.expect(InvariantEngine.verifyConservationOfSupply(&storage));
}
