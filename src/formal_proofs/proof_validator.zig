//! Roche EVM Security Engine - Proof Validator
//! Interface for invoking Z3 / CVC5 solver binary to validate SMT-LIB2 horn clauses.

const std = @import("std");

pub const SolverType = enum {
    Z3,
    CVC5,
};

pub const ValidationResult = struct {
    is_valid: bool,
    solver: SolverType,
    execution_time_ms: u64,
    unsat_proof: bool,
};

pub const ProofValidator = struct {
    solver_path: []const u8 = "z3",
    solver_type: SolverType = .Z3,

    pub fn init(solver_type: SolverType) ProofValidator {
        return .{
            .solver_type = solver_type,
            .solver_path = if (solver_type == .Z3) "z3" else "cvc5",
        };
    }

    pub fn validateProofFile(self: *const ProofValidator, smt2_path: []const u8) !ValidationResult {
        const cmd_name = if (self.solver_type == .Z3) "z3" else "cvc5";
        var child = std.process.Child.init(&[_][]const u8{ cmd_name, smt2_path }, std.heap.page_allocator);
        child.stdout_behavior = .Pipe;
        child.stderr_behavior = .Pipe;

        const start_time = std.time.milliTimestamp();
        child.spawn() catch {
            return ValidationResult{
                .is_valid = false,
                .solver = self.solver_type,
                .execution_time_ms = 0,
                .unsat_proof = false,
            };
        };

        const stdout = try child.stdout.?.reader().readAllAlloc(std.heap.page_allocator, 8192);
        defer std.heap.page_allocator.free(stdout);

        _ = try child.wait();
        const elapsed = std.time.milliTimestamp() - start_time;

        const is_unsat = std.mem.indexOf(u8, stdout, "unsat") != null;
        return ValidationResult{
            .is_valid = is_unsat,
            .solver = self.solver_type,
            .execution_time_ms = @intCast(@max(0, elapsed)),
            .unsat_proof = is_unsat,
        };
    }
};

pub fn validateProof(smt2_path: []const u8) !bool {
    const validator = ProofValidator.init(.Z3);
    const res = try validator.validateProofFile(smt2_path);
    return res.is_valid;
}

test "ProofValidator init" {
    const v = ProofValidator.init(.Z3);
    try std.testing.expectEqual(SolverType.Z3, v.solver_type);
}
