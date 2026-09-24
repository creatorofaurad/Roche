const std = @import("std");

pub fn exportSmt2(arena: std.mem.Allocator, state_cond: []const u8, inv_cond: []const u8) ![]const u8 {
    var buf = std.ArrayList(u8).init(arena);
    const w = buf.writer();

    try w.print("(set-logic HORN)\n", .{});
    try w.print("(declare-fun State (Int) Bool)\n", .{});
    try w.print("(declare-fun Invariant (Int) Bool)\n", .{});
    try w.print("(declare-fun Exploitable (Int) Bool)\n", .{});
    
    try w.print("; Context: {s} -> {s}\n", .{state_cond, inv_cond});
    try w.print("(assert (forall ((t Int)) (=> (and (State t) (Invariant t)) (not (Exploitable t)))))\n", .{});
    try w.print("(check-sat)\n", .{});

    return try buf.toOwnedSlice();
}
