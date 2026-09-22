//! test_master_suite.zig: Roche v2 Master Acceptance Test Suite
//! Runs all 9 Kernel, Sentinel Invariant, Integration, and Zero-Heap Test Suites.

const std = @import("std");

test {
    _ = @import("test_001_state_delta_journal.zig");
    _ = @import("test_002_transient_storage.zig");
    _ = @import("test_003_call_frame.zig");
    _ = @import("test_004_reentrancy_bitmap.zig");
    _ = @import("test_005_shadow_math.zig");
    _ = @import("test_006_opcode_mask.zig");
    _ = @import("test_007_sentinel_detectors.zig");
    _ = @import("test_008_coinbase_tier0.zig");
    _ = @import("test_009_paxos_compositional.zig");
    _ = @import("test_010_pumpfun_solana.zig");
    _ = @import("test_011_paxos_medium.zig");
    _ = @import("test_012_agglayer.zig");
    _ = @import("test_017_integration_tests.zig");
    _ = @import("test_018_zero_heap_policy_tests.zig");
}
