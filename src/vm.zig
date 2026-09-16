//! volta: Bare-Silicon EVM Virtual Machine Interpreter
//! Zero Dynamic Heap Allocations (`malloc=0`), Multi-Account State & Cheatcode Hooks.

const std = @import("std");
const types = @import("types.zig");
const storage_mod = @import("storage.zig");
const fuzzer_mod = @import("fuzzer.zig");

pub const MemoryState = struct {
    bytes: [types.MAX_MEMORY_BYTES]u8 align(64) = [_]u8{0} ** types.MAX_MEMORY_BYTES,
    size: usize = 0,

    pub inline fn mstore(self: *MemoryState, offset: usize, val: u256) void {
        if (offset + 32 <= types.MAX_MEMORY_BYTES) {
            var temp = val;
            var i: usize = 32;
            while (i > 0) {
                i -= 1;
                self.bytes[offset + i] = @truncate(temp & 0xFF);
                temp >>= 8;
            }
            if (offset + 32 > self.size) {
                self.size = offset + 32;
            }
        }
    }

    pub inline fn mload(self: *const MemoryState, offset: usize) u256 {
        if (offset + 32 <= types.MAX_MEMORY_BYTES) {
            var val: u256 = 0;
            for (0..32) |i| {
                val = (val << 8) | @as(u256, self.bytes[offset + i]);
            }
            return val;
        }
        return 0;
    }

    pub inline fn reset(self: *MemoryState) void {
        @memset(&self.bytes, 0);
        self.size = 0;
    }
};

pub const VM = struct {
    stack: [types.MAX_STACK_DEPTH]u256 align(64) = [_]u256{0} ** types.MAX_STACK_DEPTH,
    sp: usize = 0,
    pc: usize = 0,
    memory: MemoryState = .{},
    storage: storage_mod.StorageState = storage_mod.StorageState.init(),
    transient_storage: storage_mod.TransientStorage = storage_mod.TransientStorage.init(),
    world: storage_mod.WorldState = storage_mod.WorldState.init(),
    cheatcodes: storage_mod.CheatcodeContext = storage_mod.CheatcodeContext.init(),
    coverage: fuzzer_mod.CoverageEngine = .{},
    status: types.ExecutionStatus = .SUCCESS,

    pub fn init() VM {
        return .{};
    }

    pub inline fn push(self: *VM, val: u256) bool {
        if (self.sp >= types.MAX_STACK_DEPTH) {
            self.status = .STACK_OVERFLOW;
            return false;
        }
        self.stack[self.sp] = val;
        self.sp += 1;
        return true;
    }

    pub inline fn pop(self: *VM) ?u256 {
        if (self.sp == 0) {
            self.status = .STACK_UNDERFLOW;
            return null;
        }
        self.sp -= 1;
        return self.stack[self.sp];
    }

    pub inline fn peek(self: *const VM, depth: usize) ?u256 {
        if (self.sp <= depth) return null;
        return self.stack[self.sp - 1 - depth];
    }

    pub inline fn swap(self: *VM, depth: usize) bool {
        if (self.sp <= depth) {
            self.status = .STACK_UNDERFLOW;
            return false;
        }
        const top_idx = self.sp - 1;
        const swap_idx = self.sp - 1 - depth;
        const tmp = self.stack[top_idx];
        self.stack[top_idx] = self.stack[swap_idx];
        self.stack[swap_idx] = tmp;
        return true;
    }

    pub fn execute(self: *VM, bytecode: []const u8) types.ExecutionStatus {
        self.pc = 0;
        self.sp = 0;
        self.status = .SUCCESS;
        self.coverage.resetTrace();

        while (self.pc < bytecode.len) {
            const cur_pc = self.pc;
            self.coverage.recordBranch(cur_pc);

            const op = bytecode[self.pc];
            self.pc += 1;

            switch (op) {
                0x00 => break, // STOP
                0x01 => { // ADD
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    _ = self.push(a +% b);
                },
                0x02 => { // MUL
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    _ = self.push(a *% b);
                },
                0x03 => { // SUB
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    _ = self.push(a -% b);
                },
                0x04 => { // DIV
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    const res = if (b == 0) 0 else a / b;
                    _ = self.push(res);
                },
                0x10 => { // LT
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    _ = self.push(if (a < b) 1 else 0);
                },
                0x11 => { // GT
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    _ = self.push(if (a > b) 1 else 0);
                },
                0x14 => { // EQ
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    _ = self.push(if (a == b) 1 else 0);
                },
                0x15 => { // ISZERO
                    const a = self.pop() orelse return self.status;
                    _ = self.push(if (a == 0) 1 else 0);
                },
                0x16 => { // AND
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    _ = self.push(a & b);
                },
                0x17 => { // OR
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    _ = self.push(a | b);
                },
                0x18 => { // XOR
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    _ = self.push(a ^ b);
                },
                0x19 => { // NOT
                    const a = self.pop() orelse return self.status;
                    _ = self.push(~a);
                },

                // Environmental & Cheatcode Context Opcodes
                0x30 => { // ADDRESS
                    var addr_val: u256 = 0;
                    for (self.cheatcodes.current_address) |byte| {
                        addr_val = (addr_val << 8) | @as(u256, byte);
                    }
                    _ = self.push(addr_val);
                },
                0x31 => { // BALANCE
                    const target_u = self.pop() orelse return self.status;
                    var target_addr: [20]u8 = undefined;
                    var temp = target_u;
                    var i: usize = 20;
                    while (i > 0) {
                        i -= 1;
                        target_addr[i] = @truncate(temp & 0xFF);
                        temp >>= 8;
                    }
                    const bal = self.world.getOrCreateAccount(target_addr).balance;
                    _ = self.push(bal);
                },
                0x33 => { // CALLER (affected by vm.prank)
                    var caller_val: u256 = 0;
                    for (self.cheatcodes.current_caller) |byte| {
                        caller_val = (caller_val << 8) | @as(u256, byte);
                    }
                    _ = self.push(caller_val);
                },
                0x42 => { // TIMESTAMP (affected by vm.warp)
                    _ = self.push(@as(u256, self.cheatcodes.block_timestamp));
                },
                0x43 => { // NUMBER (affected by vm.roll)
                    _ = self.push(@as(u256, self.cheatcodes.block_number));
                },
                0x46 => { // CHAINID
                    _ = self.push(@as(u256, self.cheatcodes.chain_id));
                },

                0x50 => { // POP
                    _ = self.pop() orelse return self.status;
                },
                0x51 => { // MLOAD
                    const offset = self.pop() orelse return self.status;
                    const off: usize = @truncate(offset);
                    _ = self.push(self.memory.mload(off));
                },
                0x52 => { // MSTORE
                    const offset = self.pop() orelse return self.status;
                    const val = self.pop() orelse return self.status;
                    const off: usize = @truncate(offset);
                    self.memory.mstore(off, val);
                },
                0x54 => { // SLOAD
                    const slot_u = self.pop() orelse return self.status;
                    const slot: usize = @truncate(slot_u);
                    _ = self.push(self.storage.select(slot));
                },
                0x55 => { // SSTORE
                    const slot_u = self.pop() orelse return self.status;
                    const val = self.pop() orelse return self.status;
                    const slot: usize = @truncate(slot_u);
                    self.storage.store(slot, val);
                },
                0x56 => { // JUMP
                    const dest = self.pop() orelse return self.status;
                    const d: usize = @truncate(dest);
                    if (d >= bytecode.len or bytecode[d] != 0x5B) {
                        self.status = .INVALID_JUMP;
                        return self.status;
                    }
                    self.pc = d + 1;
                },
                0x57 => { // JUMPI
                    const dest = self.pop() orelse return self.status;
                    const cond = self.pop() orelse return self.status;
                    if (cond != 0) {
                        const d: usize = @truncate(dest);
                        if (d >= bytecode.len or bytecode[d] != 0x5B) {
                            self.status = .INVALID_JUMP;
                            return self.status;
                        }
                        self.pc = d + 1;
                    }
                },
                0x5B => {}, // JUMPDEST
                0x5C => { // TLOAD (EIP-1153)
                    const slot_u = self.pop() orelse return self.status;
                    const slot: usize = @truncate(slot_u);
                    _ = self.push(self.transient_storage.tload(slot));
                },
                0x5D => { // TSTORE (EIP-1153)
                    const slot_u = self.pop() orelse return self.status;
                    const val = self.pop() orelse return self.status;
                    const slot: usize = @truncate(slot_u);
                    self.transient_storage.tstore(slot, val);
                },

                0x60...0x7F => { // PUSH1..PUSH32
                    const num_bytes: usize = op - 0x60 + 1;
                    var val: u256 = 0;
                    for (0..num_bytes) |_| {
                        if (self.pc < bytecode.len) {
                            val = (val << 8) | @as(u256, bytecode[self.pc]);
                            self.pc += 1;
                        }
                    }
                    _ = self.push(val);
                },

                0x80...0x8F => { // DUP1..DUP16
                    const depth: usize = op - 0x80;
                    const val = self.peek(depth) orelse {
                        self.status = .STACK_UNDERFLOW;
                        return self.status;
                    };
                    _ = self.push(val);
                },

                0x90...0x9F => { // SWAP1..SWAP16
                    const depth: usize = op - 0x90 + 1;
                    if (!self.swap(depth)) {
                        return self.status;
                    }
                },

                0xFD => { // REVERT
                    self.status = .REVERTED;
                    return self.status;
                },

                else => {},
            }
        }

        return self.status;
    }
};

test "VM: Stack, Arithmetic, Cheatcodes & Environmental Execution" {
    var vm = VM.init();
    
    // Test vm.prank and CALLER opcode (0x33)
    const attacker = [_]u8{0x99} ** 20;
    vm.cheatcodes.prank(attacker);
    
    // CALLER (0x33) STOP
    const caller_code = [_]u8{ 0x33, 0x00 };
    _ = vm.execute(&caller_code);
    const popped_caller = vm.pop().?;
    var expected_caller: u256 = 0;
    for (attacker) |byte| {
        expected_caller = (expected_caller << 8) | @as(u256, byte);
    }
    try std.testing.expectEqual(expected_caller, popped_caller);

    // Test vm.warp and TIMESTAMP opcode (0x42)
    vm.cheatcodes.warp(1700009999);
    const time_code = [_]u8{ 0x42, 0x00 };
    _ = vm.execute(&time_code);
    try std.testing.expectEqual(@as(u256, 1700009999), vm.pop().?);
}
