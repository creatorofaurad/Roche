//! Roche EVM Security Engine - Pierre Fact Query Engine
//! O(1) fact lookup index against ground truth vault.

const std = @import("std");

pub const MAX_PIERRE_FACTS: usize = 1024;

pub const PierreFact = struct {
    id: u32 = 0,
    protocol: [64]u8 = [_]u8{0} ** 64,
    protocol_len: usize = 0,
    key: [64]u8 = [_]u8{0} ** 64,
    key_len: usize = 0,
    value: u128 = 0,
    valid: bool = false,

    pub fn getProtocol(self: *const PierreFact) []const u8 {
        return self.protocol[0..self.protocol_len];
    }

    pub fn getKey(self: *const PierreFact) []const u8 {
        return self.key[0..self.key_len];
    }
};

pub const FactQueryEngine = struct {
    facts: [MAX_PIERRE_FACTS]PierreFact = [_]PierreFact{.{}} ** MAX_PIERRE_FACTS,
    index: [MAX_PIERRE_FACTS]usize = [_]usize{0} ** MAX_PIERRE_FACTS,
    count: usize = 0,

    pub fn init() FactQueryEngine {
        return .{};
    }

    pub fn insertFact(self: *FactQueryEngine, protocol: []const u8, key: []const u8, value: u128) !u32 {
        if (self.count >= MAX_PIERRE_FACTS) return error.VaultFull;

        const idx = self.count;
        var f = &self.facts[idx];
        f.id = @intCast(idx + 1);

        const p_len = @min(protocol.len, 64);
        @memcpy(f.protocol[0..p_len], protocol[0..p_len]);
        f.protocol_len = p_len;

        const k_len = @min(key.len, 64);
        @memcpy(f.key[0..k_len], key[0..k_len]);
        f.key_len = k_len;

        f.value = value;
        f.valid = true;

        self.index[idx] = idx;
        self.count += 1;

        return f.id;
    }

    pub fn lookupFact(self: *const FactQueryEngine, id: u32) ?*const PierreFact {
        if (id == 0 or id > self.count) return null;
        const idx = id - 1;
        const fact = &self.facts[idx];
        if (!fact.valid) return null;
        return fact;
    }
};

test "FactQueryEngine O(1) lookup" {
    var q = FactQueryEngine.init();
    const id = try q.insertFact("uniswap_v3", "total_liquidity", 500000000);
    try std.testing.expectEqual(@as(u32, 1), id);

    const fact = q.lookupFact(id).?;
    try std.testing.expectEqualStrings("uniswap_v3", fact.getProtocol());
    try std.testing.expectEqualStrings("total_liquidity", fact.getKey());
    try std.testing.expectEqual(@as(u128, 500000000), fact.value);
}
