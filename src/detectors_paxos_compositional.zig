//! detectors_paxos_compositional.zig: Paxos Compositional & Cross-Subsystem State-Delta Invariant Detectors
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const cfg_mod = @import("cfg.zig");
const vm_mod = @import("vm.zig");
const types = @import("types.zig");
const detectors_v2 = @import("detectors_v2.zig");

pub const DetectionResult = detectors_v2.DetectionResult;

// ============================================================================
// PAXOS COMPOSITIONAL INVARIANT DETECTORS (PX-DIAMOND-01, PX-RATE-01, PX-FREEZE-01)
// ============================================================================

/// PX-DIAMOND-01: EIP-2535 Diamond Facet Selector Collision Verification
/// Invariant: For all facets F_i, F_j in DiamondProxy, if i != j, then selectors(F_i) ∩ selectors(F_j) == ∅.
/// Any collision silently overwrites facet function dispatch causing state corruption or auth bypass.
pub fn detectPXDiamond01(vm_state: ?*const vm_mod.VM, cfg: *const cfg_mod.ControlFlowGraph) DetectionResult {
    _ = cfg;
    if (vm_state) |vm| {
        // Shadow Register Layout for Diamond Selector Dispatch:
        // Slot 0..N: Function Selectors (bytes4 packed as u32 / u256)
        // If two different registered facets emit identical selector writes to facet mapping:
        if (vm.shadow_registers.len >= 2) {
            for (0..vm.shadow_registers.len) |i| {
                const sel_i = vm.shadow_registers.actual_state[i].toNative();
                const facet_i = vm.shadow_registers.ideal_state[i].toNative();
                if (sel_i != 0 and facet_i != 0) {
                    for (i + 1..vm.shadow_registers.len) |j| {
                        const sel_j = vm.shadow_registers.actual_state[j].toNative();
                        const facet_j = vm.shadow_registers.ideal_state[j].toNative();
                        // If same selector is claimed by distinct facet implementation addresses
                        if (sel_i == sel_j and facet_i != facet_j) {
                            return DetectionResult.init(true, 10, "CWE-436", "PX-DIAMOND-01: StateDelta: EIP-2535 selector collision detected across distinct Diamond facets");
                        }
                    }
                }
            }
        }

        // StateDeltaJournal verification of facet storage slot overwrites
        for (0..vm.delta_journal.len) |i| {
            const entry = vm.delta_journal.entries[i];
            if (entry.flags & types.DELTA_REVERTED == 0) {
                const pre_val = types.U256.fromBytes(entry.pre).toNative();
                const post_val = types.U256.fromBytes(entry.post).toNative();
                // If pre_val was an active facet address and overwritten by another non-zero facet during cut
                if (pre_val != 0 and post_val != 0 and pre_val != post_val and (entry.flags & 0x08 != 0)) {
                    return DetectionResult.init(true, 9, "CWE-436", "PX-DIAMOND-01: StateDelta: Facet selector mapping slot overwritten by secondary facet");
                }
            }
        }
    }
    return DetectionResult.init(false, 0, "", "");
}

/// PX-RATE-01: Token Bucket Rate Limiter Truncation & Capacity Exhaustion DoS
/// Invariant: Refill rate and time delta arithmetic must never underflow, truncate to zero,
/// or allow complete bucket exhaustion where refill duration exceeds max allowable block window.
pub fn detectPXRate01(vm_state: ?*const vm_mod.VM, cfg: *const cfg_mod.ControlFlowGraph) DetectionResult {
    _ = cfg;
    if (vm_state) |vm| {
        // Evaluate StateDeltaJournal for rate limiter storage transitions
        for (0..vm.delta_journal.len) |i| {
            const entry = vm.delta_journal.entries[i];
            if (entry.flags & types.DELTA_REVERTED == 0) {
                const pre_val = types.U256.fromBytes(entry.pre).toNative();
                const post_val = types.U256.fromBytes(entry.post).toNative();

                // Check for rate limit bucket drain to 0 with zero or negligible refillPerSecond
                if (pre_val > 0 and post_val == 0) {
                    if (vm.shadow_registers.len >= 2) {
                        const refill_rate = vm.shadow_registers.actual_state[0].toNative();
                        const capacity = vm.shadow_registers.actual_state[1].toNative();
                        // If capacity is non-zero but refill_rate is 0 or takes > 86,400s (24h) to refill 10%
                        if (capacity > 0 and (refill_rate == 0 or (capacity / (refill_rate * 10)) > 86400)) {
                            return DetectionResult.init(true, 8, "CWE-400", "PX-RATE-01: StateDelta: Rate limiter bucket exhausted with disproportionate refill delay (DoS griefing)");
                        }
                    }
                }
            }
        }

        // Check for arithmetic truncation in refillPerSecond * secondsElapsed
        for (0..vm.shadow_registers.len) |i| {
            const actual = vm.shadow_registers.actual_state[i].toNative();
            const ideal = vm.shadow_registers.ideal_state[i].toNative();
            // Truncation detection: ideal value was positive tokens, but actual bucket refill evaluated to 0
            if (ideal > 0 and actual == 0) {
                return DetectionResult.init(true, 8, "CWE-682", "PX-RATE-01: Shadow: Integer truncation in rate limit refill math zeroes out token replenishment");
            }
        }
    }
    return DetectionResult.init(false, 0, "", "");
}

/// PX-FREEZE-01: Legacy Frozen Mapping (Slot 7) Reentrancy / External CALL Ordering
/// Invariant: In PAXG transfers, the overridden `_isAddrFrozen` check (Slot 7) must strictly occur
/// BEFORE any external CALL or state modification in the execution sequence.
pub fn detectPXFreeze01(vm_state: ?*const vm_mod.VM, cfg: *const cfg_mod.ControlFlowGraph) DetectionResult {
    _ = cfg;
    if (vm_state) |vm| {
        // Analyze CallFrameStack execution sequence:
        // Flag if an external CALL occurs at frame depth >= 1 before Slot 7 freeze verification
        if (vm.call_stack.depth > 0) {
            var external_call_seen = false;
            var freeze_checked = false;

            for (0..vm.call_stack.depth) |i| {
                const frame = vm.call_stack.frames[i];
                if (frame.call_kind == .call or frame.call_kind == .delegatecall) {
                    if (!freeze_checked and i > 0) {
                        external_call_seen = true;
                    }
                }
                if (frame.flags & 0x04 != 0) {
                    freeze_checked = true;
                }
            }

            if (external_call_seen and !freeze_checked) {
                return DetectionResult.init(true, 9, "CWE-841", "PX-FREEZE-01: CallFrame: External call executed prior to PAXG Slot 7 freeze verification");
            }
        }

        // StateDeltaJournal verification: Balance transfer SSTORE executed for an account marked frozen in post-state
        for (0..vm.delta_journal.len) |i| {
            const entry = vm.delta_journal.entries[i];
            if (entry.flags & types.DELTA_REVERTED == 0) {
                // If transfer delta succeeded while address was in frozen state
                if (entry.flags & 0x10 != 0) {
                    return DetectionResult.init(true, 9, "CWE-841", "PX-FREEZE-01: StateDelta: Balance transfer executed for frozen address");
                }
            }
        }
    }
    return DetectionResult.init(false, 0, "", "");
}
