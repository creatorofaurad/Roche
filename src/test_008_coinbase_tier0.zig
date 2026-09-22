//! test_008_coinbase_tier0.zig: Concrete State-Delta Acceptance Test Suite for Coinbase Tier 0 Detectors
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const testing = std.testing;
const types = @import("types.zig");
const vm_mod = @import("vm.zig");
const cfg_mod = @import("cfg.zig");
const cb = @import("detectors_coinbase_tier0.zig");

// --- CB-01: ExchangeRateUpdater Discrete Jump ---
test "CB-01-TP: StateDelta: Exchange rate jumps by 20% exceeding 5% max cap" {
    var vm = vm_mod.VM.init();
    const dummy_addr = vm.cheatcodes.current_address;
    const slot_rate: [32]u8 = [_]u8{0} ** 32;

    const pre_rate = types.U256.fromNative(1_000_000_000_000_000_000).toBytes();
    const post_rate = types.U256.fromNative(1_200_000_000_000_000_000).toBytes(); // +20%

    vm.delta_journal.recordSSTORE(dummy_addr, slot_rate, pre_rate, post_rate, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = cb.detectCB01(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "CB-01-TN: StateDelta: Exchange rate updates within 0.5% allowed band" {
    var vm = vm_mod.VM.init();
    const dummy_addr = vm.cheatcodes.current_address;
    const slot_rate: [32]u8 = [_]u8{0} ** 32;

    const pre_rate = types.U256.fromNative(1_000_000_000_000_000_000).toBytes();
    const post_rate = types.U256.fromNative(1_005_000_000_000_000_000).toBytes(); // +0.5%

    vm.delta_journal.recordSSTORE(dummy_addr, slot_rate, pre_rate, post_rate, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = cb.detectCB01(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// --- CB-02: Cross-Chain Message Replay Prevention ---
test "CB-02-TP: StateDelta: Unseparated cross-chain message produces collision on distinct chains" {
    var vm = vm_mod.VM.init();
    const unseparated_msg_hash: u256 = 0xA1B2C3D4E5F6;
    // Slot 0: Chain A hash, Slot 1: Chain B hash (identical!), Slot 2: Chain 1 (L1), Slot 3: Chain 8453 (Base)
    vm.shadow_registers.recordSlot(0, unseparated_msg_hash, unseparated_msg_hash);
    vm.shadow_registers.recordSlot(1, unseparated_msg_hash, unseparated_msg_hash);
    vm.shadow_registers.recordSlot(2, 1, 1);
    vm.shadow_registers.recordSlot(3, 8453, 8453);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = cb.detectCB02(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 9), res.severity);
}

test "CB-02-TN: StateDelta: Domain-separated message hash differs across chains" {
    var vm = vm_mod.VM.init();
    const hash_chain_1: u256 = 0x1111_A1B2C3D4E5F6;
    const hash_chain_8453: u256 = 0x8453_A1B2C3D4E5F6;

    vm.shadow_registers.recordSlot(0, hash_chain_1, hash_chain_1);
    vm.shadow_registers.recordSlot(1, hash_chain_8453, hash_chain_8453);
    vm.shadow_registers.recordSlot(2, 1, 1);
    vm.shadow_registers.recordSlot(3, 8453, 8453);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = cb.detectCB02(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// --- CB-03: Custodial Wrapper Share Inflation ---
test "CB-03-TP: StateDelta: Front-run asset donation causes 0 shares minted for non-zero deposit" {
    var vm = vm_mod.VM.init();
    const dummy_addr = vm.cheatcodes.current_address;
    const slot_supply: [32]u8 = [_]u8{0} ** 32;
    var slot_assets: [32]u8 = [_]u8{0} ** 32;
    slot_assets[31] = 1;

    // Pre-state: totalSupply = 0, totalAssets = 1000 BTC (donated)
    // Post-state: victim deposits 50 BTC, but totalSupply remains 0 (0 shares minted)
    const s_pre = types.U256.fromNative(0).toBytes();
    const s_post = types.U256.fromNative(0).toBytes();
    const a_pre = types.U256.fromNative(1000_00000000).toBytes();
    const a_post = types.U256.fromNative(1050_00000000).toBytes();

    vm.delta_journal.recordSSTORE(dummy_addr, slot_supply, s_pre, s_post, 1);
    vm.delta_journal.recordSSTORE(dummy_addr, slot_assets, a_pre, a_post, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = cb.detectCB03(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "CB-03-TN: StateDelta: Virtual shares offset protects depositor with positive shares" {
    var vm = vm_mod.VM.init();
    const dummy_addr = vm.cheatcodes.current_address;
    const slot_supply: [32]u8 = [_]u8{0} ** 32;
    var slot_assets: [32]u8 = [_]u8{0} ** 32;
    slot_assets[31] = 1;

    // Pre-state: totalSupply = 0, totalAssets = 1000 BTC
    // Post-state: victim deposits 50 BTC, receives 47_619 shares (virtual offset calculation)
    const s_pre = types.U256.fromNative(0).toBytes();
    const s_post = types.U256.fromNative(47619).toBytes();
    const a_pre = types.U256.fromNative(1000_00000000).toBytes();
    const a_post = types.U256.fromNative(1050_00000000).toBytes();

    vm.delta_journal.recordSSTORE(dummy_addr, slot_supply, s_pre, s_post, 1);
    vm.delta_journal.recordSSTORE(dummy_addr, slot_assets, a_pre, a_post, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = cb.detectCB03(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// --- CB-04: Sequencer Freshness Validation ---
test "CB-04-TP: StateDelta: Execution occurs during unelapsed sequencer restart grace period" {
    var vm = vm_mod.VM.init();
    const current_time: u256 = 20000;
    const sequencer_is_up: u256 = 1;
    const uptime_started_at: u256 = 19500; // Delta = 500s < 1800s grace period
    const state_root_time: u256 = 19900;

    vm.shadow_registers.recordSlot(0, current_time, current_time);
    vm.shadow_registers.recordSlot(1, sequencer_is_up, sequencer_is_up);
    vm.shadow_registers.recordSlot(2, uptime_started_at, uptime_started_at);
    vm.shadow_registers.recordSlot(3, state_root_time, state_root_time);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = cb.detectCB04(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 9), res.severity);
}

test "CB-04-TN: StateDelta: Sequencer uptime grace period and fresh root verified" {
    var vm = vm_mod.VM.init();
    const current_time: u256 = 20000;
    const sequencer_is_up: u256 = 1;
    const uptime_started_at: u256 = 18000; // Delta = 2000s > 1800s grace period
    const state_root_time: u256 = 19500;   // Delta = 500s < 3600s max downtime

    vm.shadow_registers.recordSlot(0, current_time, current_time);
    vm.shadow_registers.recordSlot(1, sequencer_is_up, sequencer_is_up);
    vm.shadow_registers.recordSlot(2, uptime_started_at, uptime_started_at);
    vm.shadow_registers.recordSlot(3, state_root_time, state_root_time);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = cb.detectCB04(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// --- CB-05: Oracle Heartbeat Enforcement ---
test "CB-05-TP: StateDelta: Stale oracle price consumed beyond 24-hour heartbeat threshold" {
    var vm = vm_mod.VM.init();
    const current_time: u256 = 200000;
    const price: u256 = 2000e8;
    const updated_at: u256 = 100000; // Delta = 100,000s > 86,400s (24h)
    const round_id: u256 = 10;
    const answered_in_round: u256 = 10;

    vm.shadow_registers.recordSlot(0, current_time, current_time);
    vm.shadow_registers.recordSlot(1, price, price);
    vm.shadow_registers.recordSlot(2, updated_at, updated_at);
    vm.shadow_registers.recordSlot(3, round_id, round_id);
    vm.shadow_registers.recordSlot(4, answered_in_round, answered_in_round);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = cb.detectCB05(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 8), res.severity);
}

test "CB-05-TN: StateDelta: Fresh oracle price consumed within heartbeat threshold" {
    var vm = vm_mod.VM.init();
    const current_time: u256 = 200000;
    const price: u256 = 2000e8;
    const updated_at: u256 = 190000; // Delta = 10,000s <= 86,400s
    const round_id: u256 = 10;
    const answered_in_round: u256 = 10;

    vm.shadow_registers.recordSlot(0, current_time, current_time);
    vm.shadow_registers.recordSlot(1, price, price);
    vm.shadow_registers.recordSlot(2, updated_at, updated_at);
    vm.shadow_registers.recordSlot(3, round_id, round_id);
    vm.shadow_registers.recordSlot(4, answered_in_round, answered_in_round);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = cb.detectCB05(&vm, &dummy_cfg);
    try testing.expect(!res.found);
}

// ============================================================================
// ADVERSARIAL BOUNDARY TRUE-POSITIVE SUITE (CB-01 THROUGH CB-05)
// ============================================================================

test "CB-01-BND-TP: Boundary: 5.01% jump just exceeds 5% threshold (501 bps)" {
    var vm = vm_mod.VM.init();
    const dummy_addr = vm.cheatcodes.current_address;
    const slot_rate: [32]u8 = [_]u8{0} ** 32;

    const pre_rate = types.U256.fromNative(1_000_000_000_000_000_000).toBytes();
    // 5.01% jump = 1.0501 ether (501 bps)
    const post_rate = types.U256.fromNative(1_050_100_000_000_000_000).toBytes();

    vm.delta_journal.recordSSTORE(dummy_addr, slot_rate, pre_rate, post_rate, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = cb.detectCB01(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "CB-02-BND-TP: Boundary: Domain separator missing salt/chainid causes cross-chain replay collision" {
    var vm = vm_mod.VM.init();
    const unseparated_msg_hash: u256 = 0xDEAD_BEEF_C014;
    // On Chain 1 (Ethereum) and Chain 8453 (Base), identical message produces same hash without domain separator
    vm.shadow_registers.recordSlot(0, unseparated_msg_hash, unseparated_msg_hash);
    vm.shadow_registers.recordSlot(1, unseparated_msg_hash, unseparated_msg_hash);
    vm.shadow_registers.recordSlot(2, 1, 1);
    vm.shadow_registers.recordSlot(3, 8453, 8453);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = cb.detectCB02(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 9), res.severity);
}

test "CB-03-BND-TP: Boundary: Rounding truncation gives 1 share for 50 BTC deposit (severe dilution)" {
    var vm = vm_mod.VM.init();
    const dummy_addr = vm.cheatcodes.current_address;
    const slot_supply: [32]u8 = [_]u8{0} ** 32;
    var slot_assets: [32]u8 = [_]u8{0} ** 32;
    slot_assets[31] = 1;

    // Pre-state: totalSupply = 0, totalAssets = 1000 BTC
    // Post-state: victim deposits 50 BTC, receives only 1 share (rounding truncation)
    const s_pre = types.U256.fromNative(0).toBytes();
    const s_post = types.U256.fromNative(1).toBytes();
    const a_pre = types.U256.fromNative(1000_00000000).toBytes();
    const a_post = types.U256.fromNative(1050_00000000).toBytes();

    vm.delta_journal.recordSSTORE(dummy_addr, slot_supply, s_pre, s_post, 1);
    vm.delta_journal.recordSSTORE(dummy_addr, slot_assets, a_pre, a_post, 1);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = cb.detectCB03(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 10), res.severity);
}

test "CB-04-BND-TP: Boundary: Exactly 1799s uptime (1s below grace period) and stale root at 3601s" {
    var vm = vm_mod.VM.init();
    const current_time: u256 = 20000;
    const sequencer_is_up: u256 = 1;
    const uptime_started_at: u256 = 18201; // Delta = 1799s (< 1800s grace period)
    const state_root_time: u256 = 16399;   // Delta = 3601s (> 3600s max downtime)

    vm.shadow_registers.recordSlot(0, current_time, current_time);
    vm.shadow_registers.recordSlot(1, sequencer_is_up, sequencer_is_up);
    vm.shadow_registers.recordSlot(2, uptime_started_at, uptime_started_at);
    vm.shadow_registers.recordSlot(3, state_root_time, state_root_time);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = cb.detectCB04(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 9), res.severity);
}

test "CB-05-BND-TP: Boundary: Exactly 86,401s stale (1s past heartbeat) + round regression (answeredInRound == roundId - 1)" {
    var vm = vm_mod.VM.init();
    const current_time: u256 = 200000;
    const price: u256 = 2000e8;
    const updated_at: u256 = 200000 - 86401; // Exactly 86,401s stale (1s past 24h)
    const round_id: u256 = 10;
    const answered_in_round: u256 = 9; // Round regression (answeredInRound < roundId)

    vm.shadow_registers.recordSlot(0, current_time, current_time);
    vm.shadow_registers.recordSlot(1, price, price);
    vm.shadow_registers.recordSlot(2, updated_at, updated_at);
    vm.shadow_registers.recordSlot(3, round_id, round_id);
    vm.shadow_registers.recordSlot(4, answered_in_round, answered_in_round);

    var dummy_cfg = cfg_mod.ControlFlowGraph.init();
    const res = cb.detectCB05(&vm, &dummy_cfg);
    try testing.expect(res.found);
    try testing.expectEqual(@as(u8, 8), res.severity);
}
