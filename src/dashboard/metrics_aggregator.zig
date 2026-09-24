//! Roche EVM Security Engine - Metrics Aggregator
//! Solvency ratio, reserve utilization, storage slot entropy calculation.

const std = @import("std");

pub const ProtocolMetrics = struct {
    protocol_name: [64]u8 = [_]u8{0} ** 64,
    protocol_len: usize = 0,

    total_assets: u128 = 0,
    total_liabilities: u128 = 0,
    total_reserves: u128 = 0,

    solvency_ratio: f64 = 1.0,
    reserve_utilization: f64 = 0.0,
    storage_slot_entropy: f64 = 0.0,

    pub fn compute(assets: u128, liabilities: u128, reserves: u128, modified_slots: usize, total_slots: usize) ProtocolMetrics {
        var m = ProtocolMetrics{
            .total_assets = assets,
            .total_liabilities = liabilities,
            .total_reserves = reserves,
        };

        if (liabilities > 0) {
            m.solvency_ratio = @as(f64, @floatFromInt(assets)) / @as(f64, @floatFromInt(liabilities));
        } else {
            m.solvency_ratio = 1.0;
        }

        if (assets > 0) {
            m.reserve_utilization = @as(f64, @floatFromInt(reserves)) / @as(f64, @floatFromInt(assets));
        } else {
            m.reserve_utilization = 0.0;
        }

        if (total_slots > 0) {
            const p = @as(f64, @floatFromInt(modified_slots)) / @as(f64, @floatFromInt(total_slots));
            if (p > 0.0 and p < 1.0) {
                m.storage_slot_entropy = - (p * std.math.log2(p) + (1.0 - p) * std.math.log2(1.0 - p));
            } else {
                m.storage_slot_entropy = 0.0;
            }
        }

        return m;
    }

    pub fn isSolvent(self: *const ProtocolMetrics) bool {
        return self.solvency_ratio >= 1.0;
    }
};

pub const MetricsAggregator = struct {
    pub fn init() MetricsAggregator {
        return .{};
    }

    pub fn process(self: *const MetricsAggregator, assets: u128, liabilities: u128, reserves: u128, slots_mod: usize, slots_tot: usize) ProtocolMetrics {
        _ = self;
        return ProtocolMetrics.compute(assets, liabilities, reserves, slots_mod, slots_tot);
    }
};

test "ProtocolMetrics calculation" {
    const m = ProtocolMetrics.compute(1000, 800, 200, 10, 100);
    try std.testing.expectEqual(@as(f64, 1.25), m.solvency_ratio);
    try std.testing.expectEqual(@as(f64, 0.2), m.reserve_utilization);
    try std.testing.expect(m.isSolvent());
    try std.testing.expect(m.storage_slot_entropy > 0.0);
}
