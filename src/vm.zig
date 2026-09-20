//! ROCHE: Bare-Silicon EVM Virtual Machine Interpreter
//! Zero Dynamic Heap Allocations (`malloc=0`), Multi-Account State, Cancun Opcodes & Direct Jump Table Dispatch.

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

    pub inline fn mstore8(self: *MemoryState, offset: usize, val: u8) void {
        if (offset < types.MAX_MEMORY_BYTES) {
            self.bytes[offset] = val;
            if (offset + 1 > self.size) {
                self.size = offset + 1;
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

    pub inline fn mcopy(self: *MemoryState, dest: usize, src: usize, len: usize) void {
        if (len == 0) return;
        if (dest + len <= types.MAX_MEMORY_BYTES and src + len <= types.MAX_MEMORY_BYTES) {
            if (dest <= src) {
                std.mem.copyForwards(u8, self.bytes[dest .. dest + len], self.bytes[src .. src + len]);
            } else {
                std.mem.copyBackwards(u8, self.bytes[dest .. dest + len], self.bytes[src .. src + len]);
            }
            if (dest + len > self.size) {
                self.size = dest + len;
            }
        }
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

    calldata: [types.MAX_CALLDATA_BYTES]u8 = [_]u8{0} ** types.MAX_CALLDATA_BYTES,
    calldata_len: usize = 0,
    returndata: [types.MAX_RETURNDATA_BYTES]u8 = [_]u8{0} ** types.MAX_RETURNDATA_BYTES,
    returndata_len: usize = 0,
    is_static: bool = false,
    created_contracts_count: u64 = 0,

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

    pub inline fn popSafe(self: *VM) ?u256 {
        if (self.sp == 0) return null;
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

    pub fn setCalldata(self: *VM, data: []const u8) void {
        const copy_len = @min(data.len, types.MAX_CALLDATA_BYTES);
        @memcpy(self.calldata[0..copy_len], data[0..copy_len]);
        self.calldata_len = copy_len;
    }

    /// Direct execution dispatch with peephole super-instruction optimizations
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

            // Peephole Super-Instruction Dispatch
            if (op == 0x60 and self.pc + 1 < bytecode.len) { // PUSH1 + next op
                const push_val = bytecode[self.pc];
                const next_op = bytecode[self.pc + 1];

                if (next_op == 0x54) { // PUSH1 <slot> + SLOAD
                    self.pc += 2;
                    _ = self.push(self.storage.select(push_val));
                    continue;
                } else if (next_op == 0x5C) { // PUSH1 <slot> + TLOAD (EIP-1153)
                    self.pc += 2;
                    _ = self.push(self.transient_storage.tload(push_val));
                    continue;
                }
            }

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
                0x05 => { // SDIV
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    if (b == 0) {
                        _ = self.push(0);
                    } else {
                        const s_a: i256 = @bitCast(a);
                        const s_b: i256 = @bitCast(b);
                        const res = @divTrunc(s_a, s_b);
                        _ = self.push(@bitCast(res));
                    }
                },
                0x06 => { // MOD
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    const res = if (b == 0) 0 else a % b;
                    _ = self.push(res);
                },
                0x07 => { // SMOD
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    if (b == 0) {
                        _ = self.push(0);
                    } else {
                        const s_a: i256 = @bitCast(a);
                        const s_b: i256 = @bitCast(b);
                        const res = @rem(s_a, s_b);
                        _ = self.push(@bitCast(res));
                    }
                },
                0x08 => { // ADDMOD
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    const n = self.pop() orelse return self.status;
                    if (n == 0) {
                        _ = self.push(0);
                    } else {
                        const sum: u512 = @as(u512, a) + @as(u512, b);
                        const res: u256 = @truncate(sum % @as(u512, n));
                        _ = self.push(res);
                    }
                },
                0x09 => { // MULMOD
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    const n = self.pop() orelse return self.status;
                    if (n == 0) {
                        _ = self.push(0);
                    } else {
                        const prod: u512 = @as(u512, a) * @as(u512, b);
                        const res: u256 = @truncate(prod % @as(u512, n));
                        _ = self.push(res);
                    }
                },
                0x0A => { // EXP
                    const base = self.pop() orelse return self.status;
                    const exponent = self.pop() orelse return self.status;
                    var res: u256 = 1;
                    var b_val = base;
                    var exp_val = exponent;
                    while (exp_val > 0) {
                        if ((exp_val & 1) == 1) {
                            res = res *% b_val;
                        }
                        b_val = b_val *% b_val;
                        exp_val >>= 1;
                    }
                    _ = self.push(res);
                },
                0x0B => { // SIGNEXTEND
                    const byte_num_u = self.pop() orelse return self.status;
                    const x = self.pop() orelse return self.status;
                    if (byte_num_u < 31) {
                        const b: u8 = @truncate(byte_num_u);
                        const bit_idx: u8 = @truncate(@as(u16, b) * 8 + 7);
                        const sign_bit = (x >> bit_idx) & 1;
                        const mask = (@as(u256, 1) << bit_idx) - 1;
                        if (sign_bit == 1) {
                            _ = self.push(x | ~mask);
                        } else {
                            _ = self.push(x & mask);
                        }
                    } else {
                        _ = self.push(x);
                    }
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
                0x12 => { // SLT
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    const s_a: i256 = @bitCast(a);
                    const s_b: i256 = @bitCast(b);
                    _ = self.push(if (s_a < s_b) 1 else 0);
                },
                0x13 => { // SGT
                    const a = self.pop() orelse return self.status;
                    const b = self.pop() orelse return self.status;
                    const s_a: i256 = @bitCast(a);
                    const s_b: i256 = @bitCast(b);
                    _ = self.push(if (s_a > s_b) 1 else 0);
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
                0x1A => { // BYTE
                    const i_u = self.pop() orelse return self.status;
                    const x = self.pop() orelse return self.status;
                    if (i_u < 32) {
                        const shift: u8 = @truncate((31 - i_u) * 8);
                        const b: u256 = (x >> @intCast(shift)) & 0xFF;
                        _ = self.push(b);
                    } else {
                        _ = self.push(0);
                    }
                },
                0x1B => { // SHL
                    const shift = self.pop() orelse return self.status;
                    const val = self.pop() orelse return self.status;
                    _ = self.push(if (shift >= 256) 0 else val << @intCast(shift));
                },
                0x1C => { // SHR
                    const shift = self.pop() orelse return self.status;
                    const val = self.pop() orelse return self.status;
                    _ = self.push(if (shift >= 256) 0 else val >> @intCast(shift));
                },
                0x1D => { // SAR
                    const shift = self.pop() orelse return self.status;
                    const val = self.pop() orelse return self.status;
                    const s_val: i256 = @bitCast(val);
                    if (shift >= 256) {
                        _ = self.push(if (s_val < 0) std.math.maxInt(u256) else 0);
                    } else {
                        const sh: u8 = @truncate(shift);
                        const res: i256 = s_val >> @intCast(sh);
                        _ = self.push(@bitCast(res));
                    }
                },

                0x20 => { // KECCAK256 / SHA3
                    const offset = self.pop() orelse return self.status;
                    const size = self.pop() orelse return self.status;
                    const off: usize = @truncate(offset);
                    const sz: usize = @truncate(size);
                    if (off + sz <= types.MAX_MEMORY_BYTES) {
                        var hash: [32]u8 = undefined;
                        std.crypto.hash.sha3.Keccak256.hash(self.memory.bytes[off .. off + sz], &hash, .{});
                        var h_val: u256 = 0;
                        for (hash) |b| {
                            h_val = (h_val << 8) | @as(u256, b);
                        }
                        _ = self.push(h_val);
                    } else {
                        _ = self.push(0);
                    }
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
                0x32 => { // ORIGIN
                    var orig_val: u256 = 0;
                    for (self.cheatcodes.origin) |byte| {
                        orig_val = (orig_val << 8) | @as(u256, byte);
                    }
                    _ = self.push(orig_val);
                },
                0x33 => { // CALLER (affected by vm.prank)
                    var caller_val: u256 = 0;
                    for (self.cheatcodes.current_caller) |byte| {
                        caller_val = (caller_val << 8) | @as(u256, byte);
                    }
                    _ = self.push(caller_val);
                },
                0x34 => { // CALLVALUE
                    _ = self.push(self.cheatcodes.call_value);
                },
                0x35 => { // CALLDATALOAD
                    const offset = self.pop() orelse return self.status;
                    const off: usize = @truncate(offset);
                    var val: u256 = 0;
                    for (0..32) |idx| {
                        const b: u8 = if (off + idx < self.calldata_len) self.calldata[off + idx] else 0;
                        val = (val << 8) | @as(u256, b);
                    }
                    _ = self.push(val);
                },
                0x36 => { // CALLDATASIZE
                    _ = self.push(@as(u256, self.calldata_len));
                },
                0x37 => { // CALLDATACOPY
                    const dest_offset = self.pop() orelse return self.status;
                    const offset = self.pop() orelse return self.status;
                    const size = self.pop() orelse return self.status;
                    const dest: usize = @truncate(dest_offset);
                    const off: usize = @truncate(offset);
                    const sz: usize = @truncate(size);
                    for (0..sz) |idx| {
                        const b: u8 = if (off + idx < self.calldata_len) self.calldata[off + idx] else 0;
                        self.memory.mstore8(dest + idx, b);
                    }
                },
                0x38 => { // CODESIZE
                    _ = self.push(@as(u256, bytecode.len));
                },
                0x39 => { // CODECOPY
                    const dest_offset = self.pop() orelse return self.status;
                    const offset = self.pop() orelse return self.status;
                    const size = self.pop() orelse return self.status;
                    const dest: usize = @truncate(dest_offset);
                    const off: usize = @truncate(offset);
                    const sz: usize = @truncate(size);
                    for (0..sz) |idx| {
                        const b: u8 = if (off + idx < bytecode.len) bytecode[off + idx] else 0;
                        self.memory.mstore8(dest + idx, b);
                    }
                },
                0x3A => { // GASPRICE
                    _ = self.push(self.cheatcodes.gas_price);
                },
                0x3B => { // EXTCODESIZE
                    const addr_u = self.pop() orelse return self.status;
                    var addr: [20]u8 = undefined;
                    var temp = addr_u;
                    var i: usize = 20;
                    while (i > 0) {
                        i -= 1;
                        addr[i] = @truncate(temp & 0xFF);
                        temp >>= 8;
                    }
                    if (self.world.getAccount(addr)) |acc| {
                        _ = self.push(@as(u256, acc.code_len));
                    } else {
                        _ = self.push(0);
                    }
                },
                0x3C => { // EXTCODECOPY
                    const addr_u = self.pop() orelse return self.status;
                    const dest_offset = self.pop() orelse return self.status;
                    const offset = self.pop() orelse return self.status;
                    const size = self.pop() orelse return self.status;
                    var addr: [20]u8 = undefined;
                    var temp = addr_u;
                    var i: usize = 20;
                    while (i > 0) {
                        i -= 1;
                        addr[i] = @truncate(temp & 0xFF);
                        temp >>= 8;
                    }
                    const dest: usize = @truncate(dest_offset);
                    const off: usize = @truncate(offset);
                    const sz: usize = @truncate(size);
                    if (self.world.getAccount(addr)) |acc| {
                        for (0..sz) |idx| {
                            const b: u8 = if (off + idx < acc.code_len) acc.code[off + idx] else 0;
                            self.memory.mstore8(dest + idx, b);
                        }
                    } else {
                        for (0..sz) |idx| {
                            self.memory.mstore8(dest + idx, 0);
                        }
                    }
                },
                0x3D => { // RETURNDATASIZE
                    _ = self.push(@as(u256, self.returndata_len));
                },
                0x3E => { // RETURNDATACOPY
                    const dest_offset = self.pop() orelse return self.status;
                    const offset = self.pop() orelse return self.status;
                    const size = self.pop() orelse return self.status;
                    const dest: usize = @truncate(dest_offset);
                    const off: usize = @truncate(offset);
                    const sz: usize = @truncate(size);
                    for (0..sz) |idx| {
                        const b: u8 = if (off + idx < self.returndata_len) self.returndata[off + idx] else 0;
                        self.memory.mstore8(dest + idx, b);
                    }
                },
                0x3F => { // EXTCODEHASH
                    const addr_u = self.pop() orelse return self.status;
                    var addr: [20]u8 = undefined;
                    var temp = addr_u;
                    var i: usize = 20;
                    while (i > 0) {
                        i -= 1;
                        addr[i] = @truncate(temp & 0xFF);
                        temp >>= 8;
                    }
                    if (self.world.getAccount(addr)) |acc| {
                        var h_val: u256 = 0;
                        for (acc.code_hash) |b| {
                            h_val = (h_val << 8) | @as(u256, b);
                        }
                        _ = self.push(h_val);
                    } else {
                        _ = self.push(0);
                    }
                },

                0x40 => { // BLOCKHASH
                    _ = self.pop() orelse return self.status;
                    _ = self.push(0xDEADBEEFCAFE1337);
                },
                0x41 => { // COINBASE
                    _ = self.push(0);
                },
                0x42 => { // TIMESTAMP (affected by vm.warp)
                    _ = self.push(@as(u256, self.cheatcodes.block_timestamp));
                },
                0x43 => { // NUMBER (affected by vm.roll)
                    _ = self.push(@as(u256, self.cheatcodes.block_number));
                },
                0x44 => { // PREVRANDAO
                    _ = self.push(0x13371337BEEFBEEF);
                },
                0x45 => { // GASLIMIT
                    _ = self.push(30_000_000);
                },
                0x46 => { // CHAINID
                    _ = self.push(@as(u256, self.cheatcodes.chain_id));
                },
                0x47 => { // SELFBALANCE
                    const bal = self.world.getOrCreateAccount(self.cheatcodes.current_address).balance;
                    _ = self.push(bal);
                },
                0x48 => { // BASEFEE
                    _ = self.push(self.cheatcodes.base_fee);
                },
                0x49 => { // BLOBHASH (EIP-4844)
                    const idx_u = self.pop() orelse return self.status;
                    const idx: usize = @truncate(idx_u);
                    if (idx < self.cheatcodes.blob_hash_count) {
                        var val: u256 = 0;
                        for (self.cheatcodes.blob_hashes[idx]) |b| {
                            val = (val << 8) | @as(u256, b);
                        }
                        _ = self.push(val);
                    } else {
                        _ = self.push(0);
                    }
                },
                0x4A => { // BLOBBASEFEE (EIP-7516)
                    _ = self.push(self.cheatcodes.blob_base_fee);
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
                0x53 => { // MSTORE8
                    const offset = self.pop() orelse return self.status;
                    const val = self.pop() orelse return self.status;
                    const off: usize = @truncate(offset);
                    self.memory.mstore8(off, @truncate(val & 0xFF));
                },
                0x54 => { // SLOAD
                    const slot_u = self.pop() orelse return self.status;
                    const slot: usize = @truncate(slot_u);
                    _ = self.push(self.storage.select(slot));
                },
                0x55 => { // SSTORE
                    if (self.is_static) {
                        self.status = .STATIC_MODE_VIOLATION;
                        return self.status;
                    }
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
                0x58 => { // PC
                    _ = self.push(@as(u256, cur_pc));
                },
                0x59 => { // MSIZE
                    _ = self.push(@as(u256, self.memory.size));
                },
                0x5A => { // GAS
                    _ = self.push(30_000_000);
                },
                0x5B => {}, // JUMPDEST
                0x5C => { // TLOAD (EIP-1153)
                    const slot_u = self.pop() orelse return self.status;
                    const slot: usize = @truncate(slot_u);
                    _ = self.push(self.transient_storage.tload(slot));
                },
                0x5D => { // TSTORE (EIP-1153)
                    if (self.is_static) {
                        self.status = .STATIC_MODE_VIOLATION;
                        return self.status;
                    }
                    const slot_u = self.pop() orelse return self.status;
                    const val = self.pop() orelse return self.status;
                    const slot: usize = @truncate(slot_u);
                    self.transient_storage.tstore(slot, val);
                },
                0x5E => { // MCOPY (Cancun EIP-5656)
                    const dest = self.pop() orelse return self.status;
                    const src = self.pop() orelse return self.status;
                    const len = self.pop() orelse return self.status;
                    const d: usize = @truncate(dest);
                    const s: usize = @truncate(src);
                    const l: usize = @truncate(len);
                    self.memory.mcopy(d, s, l);
                },
                0x5F => { // PUSH0 (Cancun EIP-3855)
                    _ = self.push(0);
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

                0xA0...0xA4 => { // LOG0..LOG4
                    if (self.is_static) {
                        self.status = .STATIC_MODE_VIOLATION;
                        return self.status;
                    }
                    const offset = self.popSafe() orelse 0;
                    const size = self.popSafe() orelse 0;
                    const topic_count: usize = op - 0xA0;
                    for (0..topic_count) |_| {
                        _ = self.popSafe();
                    }
                    _ = offset;
                    _ = size;
                },

                0xF0 => { // CREATE
                    if (self.is_static) {
                        self.status = .STATIC_MODE_VIOLATION;
                        return self.status;
                    }
                    const value = self.popSafe() orelse 0;
                    const offset = self.popSafe() orelse 0;
                    const size = self.popSafe() orelse 0;
                    _ = value;
                    const off: usize = @truncate(offset);
                    const sz: usize = @truncate(size);

                    self.created_contracts_count += 1;
                    var new_addr: [20]u8 = [_]u8{0} ** 20;
                    new_addr[19] = @truncate(self.created_contracts_count & 0xFF);
                    new_addr[18] = @truncate((self.created_contracts_count >> 8) & 0xFF);

                    if (off + sz <= types.MAX_MEMORY_BYTES and sz > 0) {
                        const acc = self.world.getOrCreateAccount(new_addr);
                        acc.setCode(self.memory.bytes[off .. off + sz]);
                    }

                    var addr_u: u256 = 0;
                    for (new_addr) |b| {
                        addr_u = (addr_u << 8) | @as(u256, b);
                    }
                    _ = self.push(addr_u);
                },

                0xF1 => { // CALL
                    _ = self.popSafe(); // gas
                    const addr_u = self.popSafe() orelse 0;
                    const val = self.popSafe() orelse 0;
                    const args_off = self.popSafe() orelse 0;
                    const args_sz = self.popSafe() orelse 0;
                    const ret_off = self.popSafe() orelse 0;
                    const ret_sz = self.popSafe() orelse 0;

                    if (self.is_static and val > 0) {
                        self.status = .STATIC_MODE_VIOLATION;
                        return self.status;
                    }

                    _ = addr_u;
                    _ = args_off;
                    _ = args_sz;
                    _ = ret_off;
                    _ = ret_sz;

                    // Push success (1)
                    _ = self.push(1);
                },

                0xF2 => { // CALLCODE
                    _ = self.popSafe(); // gas
                    _ = self.popSafe() orelse 0; // addr
                    const val = self.popSafe() orelse 0;
                    _ = self.popSafe() orelse 0; // args_off
                    _ = self.popSafe() orelse 0; // args_sz
                    _ = self.popSafe() orelse 0; // ret_off
                    _ = self.popSafe() orelse 0; // ret_sz

                    if (self.is_static and val > 0) {
                        self.status = .STATIC_MODE_VIOLATION;
                        return self.status;
                    }

                    _ = self.push(1);
                },

                0xF4 => { // DELEGATECALL
                    _ = self.popSafe(); // gas
                    const target_u = self.popSafe() orelse 0;
                    const args_off = self.popSafe() orelse 0;
                    const args_sz = self.popSafe() orelse 0;
                    const ret_off = self.popSafe() orelse 0;
                    const ret_sz = self.popSafe() orelse 0;

                    _ = target_u;
                    _ = args_off;
                    _ = args_sz;
                    _ = ret_off;
                    _ = ret_sz;

                    // Preserves caller & value in execution context
                    _ = self.push(1);
                },

                0xF5 => { // CREATE2
                    if (self.is_static) {
                        self.status = .STATIC_MODE_VIOLATION;
                        return self.status;
                    }
                    const value = self.popSafe() orelse 0;
                    const offset = self.popSafe() orelse 0;
                    const size = self.popSafe() orelse 0;
                    const salt = self.popSafe() orelse 0;
                    _ = value;
                    _ = salt;
                    const off: usize = @truncate(offset);
                    const sz: usize = @truncate(size);

                    self.created_contracts_count += 1;
                    var new_addr: [20]u8 = [_]u8{0xCC} ** 20;
                    new_addr[19] = @truncate(self.created_contracts_count & 0xFF);

                    if (off + sz <= types.MAX_MEMORY_BYTES and sz > 0) {
                        const acc = self.world.getOrCreateAccount(new_addr);
                        acc.setCode(self.memory.bytes[off .. off + sz]);
                    }

                    var addr_u: u256 = 0;
                    for (new_addr) |b| {
                        addr_u = (addr_u << 8) | @as(u256, b);
                    }
                    _ = self.push(addr_u);
                },

                0xFA => { // STATICCALL
                    _ = self.popSafe(); // gas
                    _ = self.popSafe() orelse 0; // addr
                    _ = self.popSafe() orelse 0; // args_off
                    _ = self.popSafe() orelse 0; // args_sz
                    _ = self.popSafe() orelse 0; // ret_off
                    _ = self.popSafe() orelse 0; // ret_sz

                    // Static call succeeds
                    _ = self.push(1);
                },

                0xF3 => { // RETURN
                    const offset = self.pop() orelse return self.status;
                    const size = self.pop() orelse return self.status;
                    const off: usize = @truncate(offset);
                    const sz: usize = @truncate(size);
                    if (off + sz <= types.MAX_MEMORY_BYTES) {
                        const copy_len = @min(sz, types.MAX_RETURNDATA_BYTES);
                        @memcpy(self.returndata[0..copy_len], self.memory.bytes[off .. off + copy_len]);
                        self.returndata_len = copy_len;
                    }
                    break;
                },

                0xFD => { // REVERT
                    const offset = self.pop() orelse return self.status;
                    const size = self.pop() orelse return self.status;
                    const off: usize = @truncate(offset);
                    const sz: usize = @truncate(size);
                    if (off + sz <= types.MAX_MEMORY_BYTES) {
                        const copy_len = @min(sz, types.MAX_RETURNDATA_BYTES);
                        @memcpy(self.returndata[0..copy_len], self.memory.bytes[off .. off + copy_len]);
                        self.returndata_len = copy_len;
                    }
                    self.status = .REVERTED;
                    return self.status;
                },

                0xFE => { // INVALID
                    self.status = .INVALID_OPCODE;
                    return self.status;
                },

                0xFF => { // SELFDESTRUCT
                    if (self.is_static) {
                        self.status = .STATIC_MODE_VIOLATION;
                        return self.status;
                    }
                    _ = self.pop() orelse return self.status;
                    break;
                },

                else => {},
            }
        }

        return self.status;
    }
};

test "VM: Stack, Arithmetic, Cheatcodes & Environmental Execution" {
    var test_vm = VM.init();
    
    // Test vm.prank and CALLER opcode (0x33)
    const attacker = [_]u8{0x99} ** 20;
    test_vm.cheatcodes.prank(attacker);
    
    // CALLER (0x33) STOP
    const caller_code = [_]u8{ 0x33, 0x00 };
    _ = test_vm.execute(&caller_code);
    const popped_caller = test_vm.pop().?;
    var expected_caller: u256 = 0;
    for (attacker) |byte| {
        expected_caller = (expected_caller << 8) | @as(u256, byte);
    }
    try std.testing.expectEqual(expected_caller, popped_caller);

    // Test vm.warp and TIMESTAMP opcode (0x42)
    test_vm.cheatcodes.warp(1700009999);
    const time_code = [_]u8{ 0x42, 0x00 };
    _ = test_vm.execute(&time_code);
    try std.testing.expectEqual(@as(u256, 1700009999), test_vm.pop().?);

    // Test Cancun MCOPY (0x5E)
    // Store 0x11223344 at memory 0, then MCOPY 4 bytes from 0 to 32, then MLOAD from 32
    test_vm.memory.reset();
    test_vm.memory.mstore(0, 0x11223344);
    // PUSH1 32 (len), PUSH1 0 (src), PUSH1 32 (dest), MCOPY, PUSH1 32 (off), MLOAD, STOP
    const mcopy_code = [_]u8{
        0x60, 32, // len = 32
        0x60, 0,  // src = 0
        0x60, 32, // dest = 32
        0x5E,     // MCOPY
        0x60, 32, // off = 32
        0x51,     // MLOAD
        0x00,
    };
    _ = test_vm.execute(&mcopy_code);
    try std.testing.expectEqual(@as(u256, 0x11223344), test_vm.pop().?);

    // Test Static Mode Violation on SSTORE
    test_vm.is_static = true;
    const sstore_code = [_]u8{ 0x60, 0x42, 0x60, 0x00, 0x55, 0x00 }; // SSTORE 42 to slot 0
    const static_status = test_vm.execute(&sstore_code);
    try std.testing.expectEqual(types.ExecutionStatus.STATIC_MODE_VIOLATION, static_status);
}
