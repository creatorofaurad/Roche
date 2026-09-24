//! Roche EVM Security Engine - Pierre Contradiction Detector
//! Ground truth conflict detection engine for protocol assertions and vault facts.

const std = @import("std");
const fact_query = @import("fact_query.zig");

pub const ContradictionType = enum {
    NO_CONTRADICTION,
    VALUE_MISMATCH,
    INVARIANT_BREACH,
    STALE_FACT_OBSERVED,
};

pub const ContradictionReport = struct {
    has_conflict: bool = false,
    conflict_type: ContradictionType = .NO_CONTRADICTION,
    fact_id: u32 = 0,
    expected_value: u128 = 0,
    observed_value: u128 = 0,
};

pub const ContradictionDetector = struct {
    pub fn init() ContradictionDetector {
        return .{};
    }

    pub fn checkFactContradiction(
        self: *const ContradictionDetector,
        vault_fact: *const fact_query.PierreFact,
        observed_value: u128
    ) ContradictionReport {
        _ = self;
        if (!vault_fact.valid) {
            return .{
                .has_conflict = true,
                .conflict_type = .STALE_FACT_OBSERVED,
            };
        }

        if (vault_fact.value != observed_value) {
            return .{
                .has_conflict = true,
                .conflict_type = .VALUE_MISMATCH,
                .fact_id = vault_fact.id,
                .expected_value = vault_fact.value,
                .observed_value = observed_value,
            };
        }

        return .{
            .has_conflict = false,
            .conflict_type = .NO_CONTRADICTION,
        };
    }
};

test "ContradictionDetector value mismatch" {
    var fact = fact_query.PierreFact{
        .id = 1,
        .value = 1000,
        .valid = true,
    };

    const detector = ContradictionDetector.init();
    const report = detector.checkFactContradiction(&fact, 900);
    try std.testing.expect(report.has_conflict);
    try std.testing.expectEqual(ContradictionType.VALUE_MISMATCH, report.conflict_type);
}
