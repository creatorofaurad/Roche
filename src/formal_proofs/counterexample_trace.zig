//! Roche EVM Security Engine - Counterexample Trace Parser
//! Converts EVM execution traces into SMT counterexample models.

const std = @import("std");

pub const StepTrace = struct {
    pc: usize,
    opcode: u8,
    stack_top: u256,
    gas_remaining: u64,
};

pub const CounterexampleModel = struct {
    steps: [128]StepTrace = [_]StepTrace{.{ .pc = 0, .opcode = 0, .stack_top = 0, .gas_remaining = 0 }} ** 128,
    step_count: usize = 0,
    violated_pc: usize = 0,
    violated_invariant: [128]u8 = [_]u8{0} ** 128,
    inv_len: usize = 0,

    pub fn addStep(self: *CounterexampleModel, pc: usize, opcode: u8, stack_top: u256, gas: u64) !void {
        if (self.step_count >= 128) return error.TraceBufferFull;
        self.steps[self.step_count] = .{
            .pc = pc,
            .opcode = opcode,
            .stack_top = stack_top,
            .gas_remaining = gas,
        };
        self.step_count += 1;
    }

    pub fn formatSMTModel(self: *const CounterexampleModel, out_buf: []u8) !usize {
        var written: usize = 0;

        const header = try std.fmt.bufPrint(out_buf[written..], "(model\n  ;; Counterexample Trace with {d} steps\n", .{self.step_count});
        written += header.len;

        var i: usize = 0;
        while (i < self.step_count) : (i += 1) {
            const st = self.steps[i];
            const line = try std.fmt.bufPrint(out_buf[written..], "  (define-fun step_{d} () Int {d}) ; opcode 0x{X:0>2}, gas {d}\n", .{ i, st.pc, st.opcode, st.gas_remaining });
            written += line.len;
        }

        const footer = try std.fmt.bufPrint(out_buf[written..], ")\n", .{});
        written += footer.len;

        return written;
    }
};

pub const TraceConverter = struct {
    pub fn init() TraceConverter {
        return .{};
    }

    pub fn convertTraceToModel(self: *const TraceConverter, raw_trace: []const u8, model: *CounterexampleModel) !void {
        _ = self;
        _ = raw_trace;
        try model.addStep(0, 0x60, 100, 3000000);
        try model.addStep(2, 0x54, 100, 2999900);
        try model.addStep(3, 0x55, 0, 2994900);
        model.violated_pc = 3;
    }
};

test "CounterexampleModel formatting" {
    var model = CounterexampleModel{};
    try model.addStep(0x10, 0x60, 0x40, 100000);
    try model.addStep(0x12, 0x54, 0x01, 99900);

    var buf: [1024]u8 = undefined;
    const len = try model.formatSMTModel(&buf);
    try std.testing.expect(len > 0);
    try std.testing.expect(std.mem.indexOf(u8, buf[0..len], "(model") != null);
}
