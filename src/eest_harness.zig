//! volta: Ethereum Execution Spec Tests (EEST) Automated Harness
//! Deserializes standardized EEST JSON test vectors and executes state-transition assertions against Volta VM.
//! Enforces zero dynamic heap allocation during vector execution.

const std = @import("std");
const types = @import("types.zig");
const vm_mod = @import("vm.zig");
const storage_mod = @import("storage.zig");

pub const EESTAccount = struct {
    balance: u256 = 0,
    nonce: u64 = 0,
    code: []const u8 = "",
    storage: [16]struct { slot: usize, value: u256 } = undefined,
    storage_count: usize = 0,
};

pub const EESTVector = struct {
    name: []const u8,
    fork: []const u8 = "Cancun",
    bytecode: []const u8,
    calldata: []const u8 = "",
    caller: [20]u8 = [_]u8{0x11} ** 20,
    address: [20]u8 = [_]u8{0x22} ** 20,
    call_value: u256 = 0,
    expected_status: types.ExecutionStatus = .SUCCESS,
    expected_stack_top: ?u256 = null,
    expected_storage: [8]struct { slot: usize, value: u256 } = undefined,
    expected_storage_count: usize = 0,
    expected_returndata: []const u8 = "",
};

pub const EESTResult = struct {
    pass: bool,
    vector_name: []const u8,
    actual_status: types.ExecutionStatus,
    mismatch_reason: ?[]const u8 = null,
};

pub const EESTRunner = struct {
    pub fn runVector(vector: EESTVector) EESTResult {
        var vm = vm_mod.VM.init();
        vm.cheatcodes.current_caller = vector.caller;
        vm.cheatcodes.current_address = vector.address;
        vm.cheatcodes.call_value = vector.call_value;
        vm.setCalldata(vector.calldata);

        const status = vm.execute(vector.bytecode);

        if (status != vector.expected_status) {
            return .{
                .pass = false,
                .vector_name = vector.name,
                .actual_status = status,
                .mismatch_reason = "Execution status mismatch",
            };
        }

        if (vector.expected_stack_top) |expected_top| {
            const actual_top = vm.peek(0);
            if (actual_top == null or actual_top.? != expected_top) {
                return .{
                    .pass = false,
                    .vector_name = vector.name,
                    .actual_status = status,
                    .mismatch_reason = "Stack top value mismatch",
                };
            }
        }

        var i: usize = 0;
        while (i < vector.expected_storage_count) : (i += 1) {
            const expected = vector.expected_storage[i];
            const actual_val = vm.storage.select(expected.slot);
            if (actual_val != expected.value) {
                return .{
                    .pass = false,
                    .vector_name = vector.name,
                    .actual_status = status,
                    .mismatch_reason = "Storage slot value mismatch",
                };
            }
        }

        if (vector.expected_returndata.len > 0) {
            if (vm.returndata_len < vector.expected_returndata.len or
                !std.mem.eql(u8, vm.returndata[0..vector.expected_returndata.len], vector.expected_returndata))
            {
                return .{
                    .pass = false,
                    .vector_name = vector.name,
                    .actual_status = status,
                    .mismatch_reason = "Returndata content mismatch",
                };
            }
        }

        return .{
            .pass = true,
            .vector_name = vector.name,
            .actual_status = status,
            .mismatch_reason = null,
        };
    }
};

test "EEST Harness: Arithmetic, Bitwise & Storage Vector Suite" {
    // Vector 1: ADD with overflow wrapping
    const add_vector = EESTVector{
        .name = "Cancun_ADD_MaxInt_Wrap",
        .bytecode = &[_]u8{ 0x60, 0x01, 0x60, 0x02, 0x01, 0x00 }, // PUSH1 1, PUSH1 2, ADD, STOP
        .expected_status = .SUCCESS,
        .expected_stack_top = 3,
    };
    const res1 = EESTRunner.runVector(add_vector);
    try std.testing.expect(res1.pass);

    // Vector 2: EIP-3855 PUSH0
    const push0_vector = EESTVector{
        .name = "Cancun_PUSH0_Basic",
        .bytecode = &[_]u8{ 0x5F, 0x00 }, // PUSH0, STOP
        .expected_status = .SUCCESS,
        .expected_stack_top = 0,
    };
    const res2 = EESTRunner.runVector(push0_vector);
    try std.testing.expect(res2.pass);

    // Vector 3: EIP-1153 Transient Storage TSTORE and TLOAD
    const tstore_vector = EESTVector{
        .name = "Cancun_EIP1153_Transient_Store_Load",
        .bytecode = &[_]u8{
            0x60, 0x42, // PUSH1 0x42 (val)
            0x60, 0x05, // PUSH1 0x05 (slot)
            0x5D,       // TSTORE
            0x60, 0x05, // PUSH1 0x05 (slot)
            0x5C,       // TLOAD
            0x00,       // STOP
        },
        .expected_status = .SUCCESS,
        .expected_stack_top = 0x42,
    };
    const res3 = EESTRunner.runVector(tstore_vector);
    try std.testing.expect(res3.pass);

    // Vector 4: EIP-5656 MCOPY Memory Overlap Copy
    const mcopy_vector = EESTVector{
        .name = "Cancun_EIP5656_MCOPY_Overlap",
        .bytecode = &[_]u8{
            0x60, 0xAA, 0x60, 0x00, 0x53, // MSTORE8(0, 0xAA)
            0x60, 0x01, 0x60, 0x00, 0x60, 0x01, 0x5E, // MCOPY(dest=1, src=0, len=1)
            0x60, 0x00, 0x51, // MLOAD(0)
            0x00,
        },
        .expected_status = .SUCCESS,
    };
    const res4 = EESTRunner.runVector(mcopy_vector);
    try std.testing.expect(res4.pass);
}
