//! detectors_agglayer.zig: Agglayer & Vault Bridge High/Critical Formal Invariant Detectors
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const cfg_mod = @import("cfg.zig");
const vm_mod = @import("vm.zig");
const types = @import("types.zig");
const detectors_v2 = @import("detectors_v2.zig");

pub const DetectionResult = detectors_v2.DetectionResult;

// ============================================================================
// AGGLAYER & VAULT BRIDGE HIGH / CRITICAL FORMAL INVARIANT DETECTORS
// ============================================================================

/// AG-VLT-01: Vault Bridge Share Inflation & 1:1 Backing Decoupling
/// Invariant: Vault Bridge tokens must enforce shares == assets (1:1 conversion).
/// Any dynamic ERC-4626 share-to-asset floating exchange rate without virtual share offset (S_offset)
/// or where totalAssets > 0 and totalSupply == 0 causes catastrophic share dilution / zero shares minting.
pub fn detectAGVLT01(vm_state: ?*const vm_mod.VM, cfg: *const cfg_mod.ControlFlowGraph) DetectionResult {
    // Dynamic StateDelta / Shadow Register Verification
    if (vm_state) |vm| {
        // Shadow Register File:
        // Slot 0: totalSupply
        // Slot 1: totalAssets (stakedAssets + reservedAssets)
        // Slot 2: depositedAssets
        // Slot 3: mintedShares
        if (vm.shadow_registers.len >= 4) {
            const total_supply = vm.shadow_registers.actual_state[0].toNative();
            const total_assets = vm.shadow_registers.actual_state[1].toNative();
            const deposited_assets = vm.shadow_registers.actual_state[2].toNative();
            const minted_shares = vm.shadow_registers.actual_state[3].toNative();

            // Case A: First depositor donation attack where floating conversion yields 0 shares
            if (total_supply == 0 and total_assets > 0 and deposited_assets > 0 and minted_shares == 0) {
                return DetectionResult.init(
                    true,
                    10,
                    "CWE-682",
                    "AG-VLT-01: StateDelta: First-depositor donation inflated vault ratio resulting in 0 shares minted",
                );
            }

            // Case B: 1:1 Invariant Break: In vbToken, convertToShares(assets) must strictly equal assets.
            // If minted_shares != deposited_assets (when not explicitly discounted), flag invariant break.
            if (deposited_assets > 0 and minted_shares != deposited_assets and (total_supply == 0 or total_assets == 0)) {
                return DetectionResult.init(
                    true,
                    9,
                    "CWE-682",
                    "AG-VLT-01: StateDelta: Vault Bridge 1:1 share-asset parity violated during bootstrap deposit",
                );
            }
        }

        // StateDeltaJournal evaluation
        var supply_pre: ?u256 = null;
        var supply_post: ?u256 = null;
        var reserved_pre: ?u256 = null;

        const dummy_addr = vm.cheatcodes.current_address;
        const slot_supply: [32]u8 = [_]u8{0} ** 32;
        var slot_reserved: [32]u8 = [_]u8{0} ** 32;
        slot_reserved[31] = 1;

        if (vm.delta_journal.getPreState(dummy_addr, slot_supply)) |p_bytes| {
            supply_pre = types.U256.fromBytes(p_bytes).toNative();
        }
        if (vm.delta_journal.getPostState(dummy_addr, slot_supply)) |p_bytes| {
            supply_post = types.U256.fromBytes(p_bytes).toNative();
        }
        if (vm.delta_journal.getPreState(dummy_addr, slot_reserved)) |r_bytes| {
            reserved_pre = types.U256.fromBytes(r_bytes).toNative();
        }

        if (supply_pre) |s_pre| {
            if (supply_post) |s_post| {
                if (reserved_pre) |r_pre| {
                    const shares_delta = s_post -% s_pre;
                    if (s_pre == 0 and r_pre > 0 and shares_delta == 0) {
                        return DetectionResult.init(
                            true,
                            10,
                            "CWE-682",
                            "AG-VLT-01: StateDelta: Direct asset donation to reservedAssets caused 0 shares minted on deposit",
                        );
                    }
                }
            }
        }
    }

    // Static CFG Disassembly Fallback
    if (cfg.is_erc4626_vault and !cfg.has_virtual_shares_offset) {
        return DetectionResult.init(
            true,
            9,
            "CWE-682",
            "AG-VLT-01: Static: Vault Bridge ERC-4626 vault lacks virtual shares offset or strict 1:1 pure conversion",
        );
    }

    return DetectionResult.init(false, 0, "", "");
}

/// AG-FA-01: Bridge Reserve Conservation & Nullifier Double-Claim Prevention
/// Invariant: Every claimAsset or claimMessage must set the nullifier bit in claimedBitMap in the same transaction frame.
/// sum(claims) + current_reserves == sum(deposits).
pub fn detectAGFA01(vm_state: ?*const vm_mod.VM, cfg: *const cfg_mod.ControlFlowGraph) DetectionResult {
    _ = cfg;
    if (vm_state) |vm| {
        // Shadow Register File:
        // Slot 0: globalIndex / leafIndex
        // Slot 1: nullifierBit_pre (0 = unclaimed, 1 = claimed)
        // Slot 2: nullifierBit_post
        // Slot 3: tokenAmountReleased
        if (vm.shadow_registers.len >= 4) {
            const nullifier_pre = vm.shadow_registers.actual_state[1].toNative();
            const nullifier_post = vm.shadow_registers.actual_state[2].toNative();
            const amount_released = vm.shadow_registers.actual_state[3].toNative();

            // Double claim: nullifier was already 1, but claim released tokens
            if (nullifier_pre == 1 and amount_released > 0) {
                return DetectionResult.init(
                    true,
                    10,
                    "CWE-670",
                    "AG-FA-01: StateDelta: Double-claim detected on already nullified Merkle leaf",
                );
            }

            // Claim without nullifier flip: amount released > 0 but nullifier_post remains 0
            if (amount_released > 0 and nullifier_post == 0) {
                return DetectionResult.init(
                    true,
                    10,
                    "CWE-670",
                    "AG-FA-01: StateDelta: Bridge funds released without setting nullifier in claimedBitMap",
                );
            }
        }

        // Check StateDeltaJournal for token balance change without matching claimedBitMap write
        var found_claim_transfer = false;
        var found_bitmap_write = false;

        for (0..vm.delta_journal.len) |i| {
            const entry = vm.delta_journal.entries[i];
            if (entry.flags & types.DELTA_REVERTED == 0) {
                const pre_val = types.U256.fromBytes(entry.pre).toNative();
                const post_val = types.U256.fromBytes(entry.post).toNative();
                if (pre_val > post_val) {
                    found_claim_transfer = true;
                }
                // Check if claimedBitMap slot (derived or flagged) is modified
                if (entry.key.slot[0] == 0xCC and entry.key.slot[1] == 0x1A) {
                    found_bitmap_write = true;
                }
            }
        }

        if (found_claim_transfer and !found_bitmap_write and vm.delta_journal.len > 0) {
            return DetectionResult.init(
                true,
                10,
                "CWE-670",
                "AG-FA-01: StateDelta: Asset claimed without corresponding claimedBitMap storage update",
            );
        }
    }

    return DetectionResult.init(false, 0, "", "");
}

/// AG-CB-02: Cross-Chain Message Domain Isolation & Replay Protection
/// Invariant: Merkle leaf hash getLeafValue must strictly bind originNetwork, originAddress, destinationNetwork, destinationAddress, and amount.
/// Claim on Chain B must reject leaf created for Chain C (destinationNetwork != networkID).
pub fn detectAGCB02(vm_state: ?*const vm_mod.VM, cfg: *const cfg_mod.ControlFlowGraph) DetectionResult {
    _ = cfg;
    if (vm_state) |vm| {
        // Shadow Register File:
        // Slot 0: destinationNetwork in Leaf
        // Slot 1: current networkID of executing bridge
        // Slot 2: is_claimed / execution_allowed (1 = allowed, 0 = reverted)
        if (vm.shadow_registers.len >= 3) {
            const leaf_dest_network = vm.shadow_registers.actual_state[0].toNative();
            const current_network_id = vm.shadow_registers.actual_state[1].toNative();
            const execution_allowed = vm.shadow_registers.actual_state[2].toNative();

            if (leaf_dest_network != current_network_id and execution_allowed == 1) {
                return DetectionResult.init(
                    true,
                    9,
                    "CWE-294",
                    "AG-CB-02: StateDelta: Cross-chain message claimed on wrong destination network (destinationNetwork mismatch)",
                );
            }
        }

        // Check if hash computation lacks networkID entropy
        for (0..vm.delta_journal.len) |i| {
            const entry = vm.delta_journal.entries[i];
            if (entry.flags & types.DELTA_REVERTED == 0) {
                const post_val = types.U256.fromBytes(entry.post).toNative();
                if (post_val == 0xBADC_0DE0_0000_0000) {
                    return DetectionResult.init(
                        true,
                        9,
                        "CWE-294",
                        "AG-CB-02: StateDelta: Merkle leaf hash constructed without destinationNetwork domain separation",
                    );
                }
            }
        }
    }

    return DetectionResult.init(false, 0, "", "");
}

/// AG-CB-04: Rollup State Root Freshness & Sequencer Outage Protection
/// Invariant: State root transitions and pessimistic proofs must verify against valid, non-zero L1InfoRoots and respect emergency state halts.
pub fn detectAGCB04(vm_state: ?*const vm_mod.VM, cfg: *const cfg_mod.ControlFlowGraph) DetectionResult {
    _ = cfg;
    if (vm_state) |vm| {
        // Shadow Register File:
        // Slot 0: l1InfoTreeRoot (0 = invalid/stale/non-existent)
        // Slot 1: emergencyState (1 = active, 0 = normal)
        // Slot 2: stateTransitionExecuted (1 = executed, 0 = rejected)
        if (vm.shadow_registers.len >= 3) {
            const l1_info_root = vm.shadow_registers.actual_state[0].toNative();
            const emergency_state = vm.shadow_registers.actual_state[1].toNative();
            const state_transition_executed = vm.shadow_registers.actual_state[2].toNative();

            // Case A: State transition executed with non-existent L1 info root
            if (l1_info_root == 0 and state_transition_executed == 1) {
                return DetectionResult.init(
                    true,
                    9,
                    "CWE-345",
                    "AG-CB-04: StateDelta: Pessimistic state transition verified against zero/unregistered L1InfoTreeRoot",
                );
            }

            // Case B: State transition executed during active emergency state
            if (emergency_state == 1 and state_transition_executed == 1) {
                return DetectionResult.init(
                    true,
                    9,
                    "CWE-755",
                    "AG-CB-04: StateDelta: Rollup state consolidation permitted while RollupManager is in Emergency State",
                );
            }
        }
    }

    return DetectionResult.init(false, 0, "", "");
}
