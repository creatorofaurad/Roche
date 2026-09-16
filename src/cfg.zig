//! volta: Slither-Style Basic Block Disassembly & Control Flow Graph
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
};

pub const ControlFlowGraph = struct {
    blocks: [types.MAX_BASIC_BLOCKS]BasicBlock = [_]BasicBlock{.{}} ** types.MAX_BASIC_BLOCKS,
    block_count: usize = 0,

    pub fn build(bytecode: []const u8) ControlFlowGraph {
        var cfg = ControlFlowGraph{};
        if (bytecode.len == 0) return cfg;

        var pc: usize = 0;
        var current_block = BasicBlock{
            .id = 0,
            .start_pc = 0,
        };

        while (pc < bytecode.len) {
            const op_pc = pc;
            const op = bytecode[pc];
            pc += 1;

            if (op >= 0x60 and op <= 0x7F) { // PUSH1 to PUSH32
                const push_bytes: usize = op - 0x60 + 1;
                pc += push_bytes;
                continue;
            }

            // Track external calls
            if (op == 0xF1 or op == 0xF4 or op == 0xFA) { // CALL, DELEGATECALL, STATICCALL
                if (current_block.first_external_call_pc == null) {
                    current_block.first_external_call_pc = op_pc;
                }
            }
            // Track state writes
            if (op == 0x55) { // SSTORE
                current_block.last_state_write_pc = op_pc;
            }
            // Track state reads
            if (op == 0x54) { // SLOAD
                if (current_block.first_state_read_pc == null) {
                    current_block.first_state_read_pc = op_pc;
                }
            }

            // Check terminators
            var is_term = false;
            var term_type = TerminatorType.FALLTHROUGH;

            switch (op) {
                0x00 => { is_term = true; term_type = .STOP; },
                0x56 => { is_term = true; term_type = .JUMP; },
                0x57 => { is_term = true; term_type = .JUMPI; },
                0xF3 => { is_term = true; term_type = .RETURN; },
                0xFD => { is_term = true; term_type = .REVERT; },
                0xFE => { is_term = true; term_type = .INVALID; },
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
