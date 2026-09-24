//! Roche EVM Security Engine - SMT-LIB2 Exporter
//! Generates SMT-LIB2 Horn clauses (.smt2 format) for Z3 / CVC5 automated solvers.

const std = @import("std");

pub const SmtExporter = struct {
    pub fn exportHornClauses(state_cond: []const u8, inv_cond: []const u8, out_buf: []u8) !usize {
        const res = try std.fmt.bufPrint(out_buf,
            \\(set-logic HORN)
            \\(declare-fun State (Int Int Int) Bool)
            \\(declare-fun Invariant (Int Int Int) Bool)
            \\(declare-fun Exploitable (Int Int Int) Bool)
            \\
            \\; Pre-state condition: {s}
            \\; Invariant assertion: {s}
            \\(assert (forall ((balance Int) (reserve Int) (shares Int))
            \\  (=> (and (State balance reserve shares) (not (Invariant balance reserve shares)))
            \\      (Exploitable balance reserve shares))))
            \\
            \\(check-sat)
            \\(get-model)
            \\
        , .{ state_cond, inv_cond });

        return res.len;
    }
};

pub fn exportSmt2(arena: std.mem.Allocator, state_cond: []const u8, inv_cond: []const u8) ![]const u8 {
    var buf = std.ArrayList(u8).init(arena);
    const w = buf.writer();

    try w.print("(set-logic HORN)\n", .{});
    try w.print("(declare-fun State (Int) Bool)\n", .{});
    try w.print("(declare-fun Invariant (Int) Bool)\n", .{});
    try w.print("(declare-fun Exploitable (Int) Bool)\n", .{});

    try w.print("; Context: {s} -> {s}\n", .{ state_cond, inv_cond });
    try w.print("(assert (forall ((t Int)) (=> (and (State t) (Invariant t)) (not (Exploitable t)))))\n", .{});
    try w.print("(check-sat)\n", .{});

    return try buf.toOwnedSlice();
}

test "exportHornClauses generates smt2 text" {
    var buf: [2048]u8 = undefined;
    const len = try SmtExporter.exportHornClauses("balance >= 0", "balance >= total_shares", &buf);
    try std.testing.expect(len > 0);
    try std.testing.expect(std.mem.indexOf(u8, buf[0..len], "(set-logic HORN)") != null);
    try std.testing.expect(std.mem.indexOf(u8, buf[0..len], "(check-sat)") != null);
}
