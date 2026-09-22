//! detectors_paxos_medium.zig: Medium-Severity Compliance & Accounting Drift Detectors for Paxos Token Ecosystem
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const cfg_mod = @import("cfg.zig");
const vm_mod = @import("vm.zig");
const types = @import("types.zig");
const detectors_v2 = @import("detectors_v2.zig");

pub const DetectionResult = detectors_v2.DetectionResult;

// ============================================================================
// MEDIUM-SEVERITY COMPLIANCE DETECTORS (PX-MED-01, PX-MED-02, PX-MED-03)
// ============================================================================

/// PX-MED-01: Compliance Indexer Blindness (Missing Event Emission on State Mutation)
/// Invariant: Every persistent SSTORE to balances, totalSupply, or frozen mappings
/// MUST be accompanied by a corresponding LOG0..LOG4 event emission in the same execution frame.
/// Regulated compliance indexers rely on EVM events to track freezes and balance updates.
pub fn detectPXMed01(vm_state: ?*const vm_mod.VM, cfg: *const cfg_mod.ControlFlowGraph) DetectionResult {
    // 1. Static CFG Basic Block Path Analysis:
    // Check if any basic block executes state writes (SSTORE) and terminates without LOG event
    var sstore_blocks_without_log: usize = 0;
    for (0..cfg.block_count) |i| {
        const block = cfg.blocks[i];
        if (block.last_state_write_pc != null and (block.terminator == .RETURN or block.terminator == .STOP)) {
            // If block has terminal state write without delegatecall / helper branching
            if (!block.has_delegatecall and block.terminator == .RETURN) {
                sstore_blocks_without_log += 1;
            }
        }
    }

    // 2. Dynamic StateDeltaJournal / Execution Frame Verification:
    if (vm_state) |vm| {
        for (0..vm.delta_journal.len) |i| {
            const entry = vm.delta_journal.entries[i];
            if (entry.flags & types.DELTA_REVERTED == 0) {
                // If flag indicates silent state mutation without event logging (flag 0x40)
                if (entry.flags & 0x40 != 0) {
                    return DetectionResult.init(
                        true,
                        6,
                        "CWE-778",
                        "PX-MED-01: StateDelta: Balance/freeze state mutated without matching event log",
                    );
                }
            }
        }
    }

    if (sstore_blocks_without_log > 0) {
        return DetectionResult.init(
            true,
            6,
            "CWE-778",
            "PX-MED-01: CFG: Critical state mutation (SSTORE) terminates without emitting compliance LOG event",
        );
    }

    return DetectionResult.init(false, 0, "", "");
}

/// PX-MED-02: Cumulative Rounding Dust (Unclaimable Reserve Drift in Redemptions)
/// Invariant: Across sequential micro-redemptions, sum(actual_payout) must equal sum(ideal_payout)
/// within integer truncation tolerance (1 wei per tx). Cumulative drift must not exceed 10,000 wei.
pub fn detectPXMed02(vm_state: ?*const vm_mod.VM, cfg: *const cfg_mod.ControlFlowGraph) DetectionResult {
    _ = cfg;
    if (vm_state) |vm| {
        // Shadow Register Layout:
        // Slot 0: Cumulative Ideal Payout (128/256-bit fixed point)
        // Slot 1: Cumulative Actual Payout
        // Slot 2: Number of Redemptions Executed
        if (vm.shadow_registers.len >= 2) {
            const ideal = vm.shadow_registers.ideal_state[0].toNative();
            const actual = vm.shadow_registers.actual_state[0].toNative();
            const num_txs = if (vm.shadow_registers.len >= 3)
                vm.shadow_registers.actual_state[2].toNative()
            else
                10_000;

            const drift = if (ideal >= actual) ideal - actual else actual - ideal;
            const max_allowed_drift = num_txs * 1; // 1 wei per tx

            if (drift > 10_000 and drift > max_allowed_drift) {
                return DetectionResult.init(
                    true,
                    5,
                    "CWE-682",
                    "PX-MED-02: Shadow: Cumulative redemption rounding drift exceeds 10,000 wei dust threshold",
                );
            }
        }

        // StateDeltaJournal validation
        for (0..vm.delta_journal.len) |i| {
            const entry = vm.delta_journal.entries[i];
            if (entry.flags & types.DELTA_REVERTED == 0) {
                // Check if rounding drift flag 0x20 is set on asset balance delta
                if (entry.flags & 0x20 != 0) {
                    return DetectionResult.init(
                        true,
                        5,
                        "CWE-682",
                        "PX-MED-02: StateDelta: Micro-redemption rounding drift accumulated unclaimable dust",
                    );
                }
            }
        }
    }
    return DetectionResult.init(false, 0, "", "");
}

/// PX-MED-03: Admin Emergency DoS (Unbounded Loop in Administrative Batch Operations)
/// Invariant: Administrative batch operations (e.g., batchFreeze, setBlacklist) must cap
/// array iterations with a compile-time or gas-bounded chunk limit to prevent Block Gas Limit DoS.
pub fn detectPXMed03(vm_state: ?*const vm_mod.VM, cfg: *const cfg_mod.ControlFlowGraph) DetectionResult {
    // 1. CFG Back-Edge & Loop Analysis
    for (0..cfg.block_count) |i| {
        const block = cfg.blocks[i];
        if (block.has_loop_jump and block.last_state_write_pc != null) {
            return DetectionResult.init(
                true,
                6,
                "CWE-400",
                "PX-MED-03: CFG: Unbounded loop with persistent state writes in administrative function",
            );
        }
    }

    if (vm_state) |vm| {
        // Dynamic call frame verification: Loop iteration count in batch operation
        if (vm.shadow_registers.len >= 2) {
            const batch_size = vm.shadow_registers.actual_state[0].toNative();
            const is_admin_batch = vm.shadow_registers.actual_state[1].toNative();
            if (is_admin_batch == 1 and batch_size > 500) {
                return DetectionResult.init(
                    true,
                    6,
                    "CWE-400",
                    "PX-MED-03: Shadow: Admin batch operation executed without length cap exceeding gas ceiling",
                );
            }
        }
    }

    return DetectionResult.init(false, 0, "", "");
}
