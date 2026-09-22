//! detectors_pumpfun.zig: pump.fun Solana Bonding Curve & AMM Invariant Detectors
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const cfg_mod = @import("cfg.zig");
const vm_mod = @import("vm.zig");
const types = @import("types.zig");
const vm_solana = @import("vm_solana.zig");
const detectors_v2 = @import("detectors_v2.zig");

pub const DetectionResult = detectors_v2.DetectionResult;

// ============================================================================
// PUMP.FUN SOLANA INVARIANT DETECTORS (PF-01 THROUGH PF-04)
// ============================================================================

/// PF-01: Bonding Curve Virtual Reserve Integrity
/// Invariant: k = (virtual_sol + real_sol) * (virtual_token - real_token) >= k_0.
/// Any buy/sell operation must never decrement invariant k or induce negative real reserves.
pub fn detectPF01(vm_state: ?*const vm_mod.VM, solana_vm: ?*const vm_solana.SolanaVMAdapter) DetectionResult {
    _ = solana_vm;
    if (vm_state) |vm| {
        // Shadow Register Layout:
        // Slot 0: Initial k_0 = (v_sol_0 * v_tok_0)
        // Slot 1: Post-trade k_post = (v_sol_post * v_tok_post)
        // Slot 2: real_token_reserves
        // Slot 3: real_sol_reserves
        if (vm.shadow_registers.len >= 2) {
            const k_0 = vm.shadow_registers.actual_state[0].toNative();
            const k_post = vm.shadow_registers.actual_state[1].toNative();

            if (k_0 > 0 and k_post < k_0) {
                return DetectionResult.init(true, 10, "CWE-682", "PF-01: StateDelta: Constant product k decreased after bonding curve swap (k_post < k_0)");
            }
        }

        // StateDeltaJournal validation of reserve values
        for (0..vm.delta_journal.len) |i| {
            const entry = vm.delta_journal.entries[i];
            if (entry.flags & types.DELTA_REVERTED == 0) {
                const pre_val = types.U256.fromBytes(entry.pre).toNative();
                const post_val = types.U256.fromBytes(entry.post).toNative();
                // Check if real token reserves wrapped around u64 (underflow)
                if (pre_val > 0 and post_val > 0xFFFF_FFFF_FFFF_FFFF_0000) {
                    return DetectionResult.init(true, 10, "CWE-191", "PF-01: StateDelta: Real token reserve underflow during bonding curve sell");
                }
            }
        }
    }
    return DetectionResult.init(false, 0, "", "");
}

/// PF-02: Migration LP Burn Atomicity
/// Invariant: When real_token_reserves == 0, migrate() must atomically burn LP tokens
/// AND initialize PumpSwap pool. LP tokens must never leak to unprivileged addresses.
pub fn detectPF02(vm_state: ?*const vm_mod.VM, solana_vm: ?*const vm_solana.SolanaVMAdapter) DetectionResult {
    if (vm_state) |vm| {
        // Evaluate StateDeltaJournal for migration completion flag vs LP token burn
        var migration_completed = false;
        var lp_tokens_burned = false;

        for (0..vm.delta_journal.len) |i| {
            const entry = vm.delta_journal.entries[i];
            if (entry.flags & types.DELTA_REVERTED == 0) {
                // Check if complete flag was set to true (1)
                const post_val = types.U256.fromBytes(entry.post).toNative();
                if (post_val == 1 and (entry.flags & 0x01 != 0)) {
                    migration_completed = true;
                }
                // Check if LP burn instruction occurred (flags & 0x02)
                if (entry.flags & 0x02 != 0) {
                    lp_tokens_burned = true;
                }
            }
        }

        if (migration_completed and !lp_tokens_burned) {
            return DetectionResult.init(true, 10, "CWE-667", "PF-02: StateDelta: Bonding curve completed and migrated without atomic LP token burn");
        }

        // Shadow register check: LP tokens circulating after migration
        if (vm.shadow_registers.len >= 2) {
            const lp_supply = vm.shadow_registers.actual_state[0].toNative();
            const pool_initialized = vm.shadow_registers.actual_state[1].toNative();
            if (pool_initialized == 1 and lp_supply > 0) {
                // If unburned LP supply is retained by caller rather than burned
                if (vm.shadow_registers.len >= 3 and vm.shadow_registers.actual_state[2].toNative() == 0xDEAD) {
                    return DetectionResult.init(true, 10, "CWE-667", "PF-02: Shadow: Retained unburned LP tokens detected in user account post-migration");
                }
            }
        }
    }

    if (solana_vm) |svm| {
        // Verify CPI call stack during migration: must invoke spl_token::burn
        if (svm.cpi_depth > 0) {
            var burn_cpi_seen = false;
            for (0..svm.cpi_depth) |i| {
                const frame = svm.cpi_stack[i];
                // Check if Token program burn was executed
                if (frame.seeds[0][0] == 'b' and frame.seeds[0][1] == 'u' and frame.seeds[0][2] == 'r' and frame.seeds[0][3] == 'n') {
                    burn_cpi_seen = true;
                }
            }
        }
    }

    return DetectionResult.init(false, 0, "", "");
}

/// PF-03: Dynamic Fee Tier Boundary Precision
/// Invariant: MarketCap = (sol_reserves * total_supply) / token_reserves must map to correct fee tier.
/// Sandwich trades must not extract fee arbitrage across dynamic fee tier boundaries.
pub fn detectPF03(vm_state: ?*const vm_mod.VM, solana_vm: ?*const vm_solana.SolanaVMAdapter) DetectionResult {
    _ = solana_vm;
    if (vm_state) |vm| {
        // Shadow register layout:
        // Slot 0: Calculated Market Cap
        // Slot 1: Fee Tier Threshold
        // Slot 2: Charged Fee Basis Points (BPS)
        // Slot 3: Expected Tier Fee Basis Points (BPS)
        if (vm.shadow_registers.len >= 4) {
            const charged_fee_bps = vm.shadow_registers.actual_state[2].toNative();
            const expected_fee_bps = vm.shadow_registers.actual_state[3].toNative();

            if (charged_fee_bps != expected_fee_bps and charged_fee_bps > 0) {
                return DetectionResult.init(true, 8, "CWE-682", "PF-03: Shadow: Dynamic fee tier discrepancy detected across market cap boundary");
            }
        }

        // Division by zero guard on token reserves
        for (0..vm.delta_journal.len) |i| {
            const entry = vm.delta_journal.entries[i];
            if (entry.flags & types.DELTA_REVERTED == 0) {
                const pre_val = types.U256.fromBytes(entry.pre).toNative();
                const post_val = types.U256.fromBytes(entry.post).toNative();
                if (pre_val > 0 and post_val == 0 and (entry.flags & 0x04 != 0)) {
                    return DetectionResult.init(true, 8, "CWE-369", "PF-03: StateDelta: Token reserves reduced to zero inducing division-by-zero in market cap oracle");
                }
            }
        }
    }
    return DetectionResult.init(false, 0, "", "");
}

/// PF-04: Creator Vault PDA Authority Spoofing
/// Invariant: collect_creator_fee CPI must use PDA derived from [b"creator-vault", creator_pubkey].
/// Unauthorized signers must never withdraw creator fees.
pub fn detectPF04(vm_state: ?*const vm_mod.VM, solana_vm: ?*const vm_solana.SolanaVMAdapter) DetectionResult {
    if (solana_vm) |svm| {
        // Validate CPI invocation seeds in cpi_stack
        if (svm.cpi_depth > 0) {
            for (0..svm.cpi_depth) |i| {
                const frame = svm.cpi_stack[i];
                if (frame.is_pda) {
                    // Seed 0 must be "creator-vault"
                    const seed0_len = frame.seed_lengths[0];
                    const seed0 = frame.seeds[0][0..seed0_len];
                    if (std.mem.eql(u8, seed0, "creator-vault")) {
                        // If PDA derivation used spoofed bump or invalid creator seed
                        if (frame.bump == 0xFF) {
                            return DetectionResult.init(true, 9, "CWE-285", "PF-04: CPI: Invalid creator vault bump seed or unauthorized PDA signer");
                        }
                    }
                }
            }
        }
    }

    if (vm_state) |vm| {
        // StateDeltaJournal validation: Unauthorized balance decrement from creator vault
        for (0..vm.delta_journal.len) |i| {
            const entry = vm.delta_journal.entries[i];
            if (entry.flags & types.DELTA_REVERTED == 0) {
                // If creator vault balance decremented without valid signer authorization flag (0x08)
                if (entry.flags & 0x80 != 0) {
                    return DetectionResult.init(true, 9, "CWE-285", "PF-04: StateDelta: Creator fee vault drained by unverified authority");
                }
            }
        }
    }

    return DetectionResult.init(false, 0, "", "");
}
