//! test_006_opcode_mask.zig: Complete OPM-001 through OPM-007 Test Suite
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const testing = std.testing;
const types = @import("types.zig");

test "OPM-001: opmask.sstore_only" {
    const mask = types.OpMask.SSTORE;
    try testing.expect(mask & types.OpMask.SSTORE != 0);
    try testing.expect(mask & types.OpMask.SLOAD == 0);
}

test "OPM-002: opmask.tstore_only" {
    const mask = types.OpMask.TSTORE;
    try testing.expect(mask & types.OpMask.TSTORE != 0);
    try testing.expect(mask & types.OpMask.TLOAD == 0);
}

test "OPM-003: opmask.call_family" {
    const call_mask = types.OpMask.CALL | types.OpMask.CALLCODE | types.OpMask.DELEGATECALL | types.OpMask.STATICCALL;
    try testing.expect(call_mask & types.OpMask.CALL != 0);
    try testing.expect(call_mask & types.OpMask.DELEGATECALL != 0);
    try testing.expect(call_mask & types.OpMask.STATICCALL != 0);
    try testing.expect(call_mask & types.OpMask.SSTORE == 0);
}

test "OPM-004: opmask.state_mutation" {
    const mutation_mask = types.OpMask.SSTORE | types.OpMask.TSTORE | types.OpMask.CREATE | types.OpMask.CREATE2 | types.OpMask.SELFDESTRUCT;
    try testing.expect(mutation_mask & types.OpMask.SSTORE != 0);
    try testing.expect(mutation_mask & types.OpMask.CREATE2 != 0);
    try testing.expect(mutation_mask & types.OpMask.SLOAD == 0);
}

test "OPM-005: opmask.log_family" {
    const log_mask = types.OpMask.LOG0 | types.OpMask.LOG1 | types.OpMask.LOG2 | types.OpMask.LOG3 | types.OpMask.LOG4;
    try testing.expect(log_mask & types.OpMask.LOG2 != 0);
    try testing.expect(log_mask & types.OpMask.CALL == 0);
}

test "OPM-006: opmask.detector_precondition_skip" {
    const trace_mask = types.OpMask.SLOAD | types.OpMask.BALANCE;
    const required_mask = types.OpMask.SSTORE;
    const should_skip = (trace_mask & required_mask) == 0;
    try testing.expect(should_skip);
}

test "OPM-007: opmask.deterministic" {
    const m1 = types.OpMask.SLOAD | types.OpMask.SSTORE | types.OpMask.CALL;
    const m2 = types.OpMask.SLOAD | types.OpMask.SSTORE | types.OpMask.CALL;
    try testing.expectEqual(m1, m2);
}
