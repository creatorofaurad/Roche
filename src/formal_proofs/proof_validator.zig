const std = @import("std");
const posix = std.posix;

pub fn validateProof(smt2_path: []const u8) !bool {
    var child = std.process.Child.init(&[_][]const u8{ "z3", smt2_path }, std.heap.page_allocator);
    child.stdout_behavior = .Pipe;
    try child.spawn();

    const stdout = try child.stdout.?.reader().readAllAlloc(std.heap.page_allocator, 1024);
    defer std.heap.page_allocator.free(stdout);

    _ = try child.wait();
    return std.mem.indexOf(u8, stdout, "unsat") != null;
}
