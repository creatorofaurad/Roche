//! ROCHE: Slither-Style Basic Block Disassembly & Control Flow Graph
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const types = @import("types.zig");

pub const TerminatorType = enum {
    FALLTHROUGH,
    JUMP,
    JUMPI,
    RETURN,
    REVERT,
    STOP,
    INVALID,
};

pub const BasicBlock = struct {
    id: usize = 0,
    start_pc: usize = 0,
    end_pc: usize = 0,
    terminator: TerminatorType = .FALLTHROUGH,
    first_external_call_pc: ?usize = null,
    last_state_write_pc: ?usize = null,
    first_state_read_pc: ?usize = null,
    has_delegatecall: bool = false,
    has_selfdestruct: bool = false,
    has_divide_before_multiply: bool = false,
    has_strict_balance_equality: bool = false,
    has_timestamp_dependency: bool = false,
    has_block_number_dependency: bool = false,
    has_tx_origin: bool = false,
    has_unchecked_call_return: bool = false,
    has_weak_prng: bool = false,
    has_missing_zero_check: bool = false,
    has_tstore: bool = false,
    has_push1_zero: bool = false,
    has_ecrecover_call: bool = false,
    has_loop_jump: bool = false,
    has_raw_memory_ops: bool = false,
    has_storage_collision_risk: bool = false,
    has_read_only_reentrancy_pattern: bool = false,
    has_oracle_staleness_pattern: bool = false,
};

pub const ControlFlowGraph = struct {
    blocks: [types.MAX_BASIC_BLOCKS]BasicBlock = [_]BasicBlock{.{}} ** types.MAX_BASIC_BLOCKS,
    block_count: usize = 0,
    has_back_edge: bool = false,

    pub fn build(bytecode: []const u8) ControlFlowGraph {
        var cfg = ControlFlowGraph{};
        if (bytecode.len == 0) return cfg;

        var pc: usize = 0;
        var current_block = BasicBlock{
            .id = 0,
            .start_pc = 0,
        };

        var prev_op: ?u8 = null;
        var prev_prev_op: ?u8 = null;
        var saw_div_in_block = false;
        var saw_prng_source = false;
        var saw_caller_without_check = false;

        while (pc < bytecode.len) {
            const op_pc = pc;
            const op = bytecode[pc];
            pc += 1;

            if (op >= 0x60 and op <= 0x7F) { // PUSH1 to PUSH32
                const push_bytes: usize = op - 0x60 + 1;
                // Check PUSH1 0x00 optimization opportunity
                if (op == 0x60 and pc < bytecode.len and bytecode[pc] == 0x00) {
                    current_block.has_push1_zero = true;
                }
                pc += push_bytes;
                prev_prev_op = prev_op;
                prev_op = op;
                continue;
            }

            // Detector 1 & 2: External Calls (CALL, DELEGATECALL, STATICCALL)
            if (op == 0xF1 or op == 0xF4 or op == 0xFA) {
                if (current_block.first_external_call_pc == null) {
                    current_block.first_external_call_pc = op_pc;
                }
                // Check if CALL to address 0x01 (ecrecover precompile)
                if (prev_op != null and prev_op.? == 0x60) {
                    current_block.has_ecrecover_call = true;
                }
            }
            if (op == 0xF4) { // DELEGATECALL
                current_block.has_delegatecall = true;
            }

            // Detector: Unchecked Low-Level Call / Return Value Discarded (CALL -> POP)
            if (prev_op != null and (prev_op.? == 0xF1 or prev_op.? == 0xFA or prev_op.? == 0xF4) and op == 0x50) {
                current_block.has_unchecked_call_return = true;
            }

            // Detector 3: State Writes (SSTORE)
            if (op == 0x55) {
                current_block.last_state_write_pc = op_pc;
                if (saw_caller_without_check) {
                    current_block.has_missing_zero_check = true;
                }
                // Check storage collision risk on slot 0 / 1 writes in proxy
                if (current_block.has_delegatecall) {
                    current_block.has_storage_collision_risk = true;
                }
            }

            // Detector 4: State Reads (SLOAD)
            if (op == 0x54) {
                if (current_block.first_state_read_pc == null) {
                    current_block.first_state_read_pc = op_pc;
                }
                if (current_block.first_external_call_pc != null) {
                    current_block.has_read_only_reentrancy_pattern = true;
                }
            }

            // Detector 5: SELFDESTRUCT
            if (op == 0xFF) {
                current_block.has_selfdestruct = true;
            }

            // Detector 6: Divide before Multiply (DIV -> MUL)
            if (op == 0x04 or op == 0x05) { // DIV, SDIV
                saw_div_in_block = true;
            }
            if (saw_div_in_block and op == 0x02) { // MUL
                current_block.has_divide_before_multiply = true;
            }

            // Detector 7: Strict Balance Equality (BALANCE / SELFBALANCE -> EQ)
            if (prev_op != null and (prev_op.? == 0x31 or prev_op.? == 0x47) and op == 0x14) {
                current_block.has_strict_balance_equality = true;
            }

            // Detector 8: Timestamp Dependency (TIMESTAMP)
            if (op == 0x42) { // TIMESTAMP
                current_block.has_timestamp_dependency = true;
            }

            // Detector 9: Block Number Dependency (NUMBER)
            if (op == 0x43) { // NUMBER
                current_block.has_block_number_dependency = true;
            }

            // Detector 10: Tx.Origin Authentication (ORIGIN)
            if (op == 0x32) { // ORIGIN
                current_block.has_tx_origin = true;
            }

            // Detector 11: Weak PRNG (PREVRANDAO / BLOCKHASH -> MOD / AND)
            if (op == 0x44 or op == 0x40) {
                saw_prng_source = true;
            }
            if (saw_prng_source and (op == 0x06 or op == 0x16)) {
                current_block.has_weak_prng = true;
            }

            // Detector 12: Missing Zero Check (CALLER / ADDRESS directly into storage)
            if (op == 0x33 or op == 0x30) {
                saw_caller_without_check = true;
            }
            if (op == 0x15) { // ISZERO
                saw_caller_without_check = false;
            }

            // Detector 13: EIP-1153 Transient Storage
            if (op == 0x5D) { // TSTORE
                current_block.has_tstore = true;
            }

            // Detector 14: Raw Memory & Assembly Bypass
            if (op == 0x59 or op == 0x5E) { // MSIZE, MCOPY
                current_block.has_raw_memory_ops = true;
            }

            // Detector 15: Oracle Staleness Pattern (TIMESTAMP followed by SLOAD without validation)
            if (op == 0x42 and prev_op != null and prev_op.? == 0x54) {
                current_block.has_oracle_staleness_pattern = true;
            }

            prev_prev_op = prev_op;
            prev_op = op;

            // Check terminators
            var is_term = false;
            var term_type = TerminatorType.FALLTHROUGH;

            switch (op) {
                0x00 => { is_term = true; term_type = .STOP; },
                0x56 => { 
                    is_term = true; 
                    term_type = .JUMP; 
                    current_block.has_loop_jump = true;
                    cfg.has_back_edge = true;
                },
                0x57 => { 
                    is_term = true; 
                    term_type = .JUMPI; 
                    current_block.has_loop_jump = true;
                    cfg.has_back_edge = true;
                },
                0xF3 => { is_term = true; term_type = .RETURN; },
                0xFD => { is_term = true; term_type = .REVERT; },
                0xFE => { is_term = true; term_type = .INVALID; },
                0xFF => { is_term = true; term_type = .STOP; }, // SELFDESTRUCT terminates
                else => {},
            }

            if (is_term or (pc < bytecode.len and bytecode[pc] == 0x5B)) { // JUMPDEST starts new block
                current_block.end_pc = op_pc;
                current_block.terminator = term_type;
                if (cfg.block_count < types.MAX_BASIC_BLOCKS) {
                    current_block.id = cfg.block_count;
                    cfg.blocks[cfg.block_count] = current_block;
                    cfg.block_count += 1;
                }
                current_block = BasicBlock{
                    .id = cfg.block_count,
                    .start_pc = pc,
                };
                saw_div_in_block = false;
                saw_prng_source = false;
                saw_caller_without_check = false;
            }
        }

        if (current_block.start_pc < bytecode.len and cfg.block_count < types.MAX_BASIC_BLOCKS) {
            current_block.end_pc = bytecode.len - 1;
            current_block.id = cfg.block_count;
            cfg.blocks[cfg.block_count] = current_block;
            cfg.block_count += 1;
        }

        return cfg;
    }
};

test "CFG: Basic Block Disassembly" {
    const code = [_]u8{ 0x60, 0x01, 0x60, 0x02, 0x01, 0x00 };
    const cfg = ControlFlowGraph.build(&code);
    try std.testing.expectEqual(@as(usize, 1), cfg.block_count);
    try std.testing.expectEqual(TerminatorType.STOP, cfg.blocks[0].terminator);
}

