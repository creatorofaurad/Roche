//! test_018_zero_heap_policy_tests.zig: Zero-Heap Allocation Policy Test Suite (ZHP-001 through ZHP-006)
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const testing = std.testing;
const types = @import("types.zig");
const vm_mod = @import("vm.zig");
const cfg_mod = @import("cfg.zig");
const fuzzer_mod = @import("fuzzer.zig");
const detectors = @import("detectors_v2.zig");

test "ZHP-001: types.zig Zero-Heap & Static Allocation Invariant" {
    // Inspect source code at compile time
    const src = @embedFile("types.zig");
    try testing.expect(std.mem.indexOf(u8, src, "std.heap.page_allocator") == null);
    try testing.expect(std.mem.indexOf(u8, src, "std.heap.c_allocator") == null);
    try testing.expect(std.mem.indexOf(u8, src, "c.malloc") == null);
    try testing.expect(std.mem.indexOf(u8, src, "c.free") == null);
}

test "ZHP-002: vm.zig Zero-Heap & Static Stack Execution Invariant" {
    const src = @embedFile("vm.zig");
    try testing.expect(std.mem.indexOf(u8, src, "std.heap.page_allocator") == null);
    try testing.expect(std.mem.indexOf(u8, src, "std.heap.c_allocator") == null);
    try testing.expect(std.mem.indexOf(u8, src, "c.malloc") == null);
    try testing.expect(std.mem.indexOf(u8, src, "c.free") == null);
}

test "ZHP-003: cfg.zig Zero-Heap Static Basic Block Invariant" {
    const src = @embedFile("cfg.zig");
    try testing.expect(std.mem.indexOf(u8, src, "std.heap.page_allocator") == null);
    try testing.expect(std.mem.indexOf(u8, src, "std.heap.c_allocator") == null);
    try testing.expect(std.mem.indexOf(u8, src, "c.malloc") == null);
    try testing.expect(std.mem.indexOf(u8, src, "c.free") == null);
}

test "ZHP-004: fuzzer.zig Zero-Heap Invariant" {
    const src = @embedFile("fuzzer.zig");
    try testing.expect(std.mem.indexOf(u8, src, "std.heap.page_allocator") == null);
    try testing.expect(std.mem.indexOf(u8, src, "std.heap.c_allocator") == null);
    try testing.expect(std.mem.indexOf(u8, src, "c.malloc") == null);
    try testing.expect(std.mem.indexOf(u8, src, "c.free") == null);
}

test "ZHP-005: detectors_v2.zig Zero-Heap Invariant" {
    const src = @embedFile("detectors_v2.zig");
    try testing.expect(std.mem.indexOf(u8, src, "std.heap.page_allocator") == null);
    try testing.expect(std.mem.indexOf(u8, src, "std.heap.c_allocator") == null);
    try testing.expect(std.mem.indexOf(u8, src, "c.malloc") == null);
    try testing.expect(std.mem.indexOf(u8, src, "c.free") == null);
}

test "ZHP-006: Hardware Sizing & Memory Boundary Bounds" {
    const sdj_size = @sizeOf(types.StateDeltaJournal);
    const tsj_size = @sizeOf(types.TransientStorageJournal);
    const cfs_size = @sizeOf(types.CallFrameStack);
    const shm_size = @sizeOf(types.ShadowRegisterFile);
    const vm_size = @sizeOf(vm_mod.VM);

    // Bounded static sizing strictly under 10MB / 50MB hardware memory ceilings
    try testing.expect(sdj_size < 10_000_000);
    try testing.expect(tsj_size < 10_000_000);
    try testing.expect(cfs_size < 1_000_000);
    try testing.expect(shm_size < 1_000_000);
    try testing.expect(vm_size < 50_000_000);
}
