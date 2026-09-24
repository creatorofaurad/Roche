//! Roche EVM Security Engine - Custom DSL Codegen
//! Compiles invariant AST to Zig detector source / bytecode representation.

const std = @import("std");
const parser = @import("parser.zig");

pub const Codegen = struct {
    pub fn init() Codegen {
        return .{};
    }

    pub fn generate(self: *const Codegen, ast: *const parser.InvariantAST, out_buf: []u8) !usize {
        _ = self;
        var stream = std.io.fixedBufferStream(out_buf);
        const w = stream.writer();

        try w.print("//! Auto-generated Roche Invariant Detector for: {s}\n", .{ast.getName()});
        try w.print("//! Severity: {s}\n\n", .{@tagName(ast.severity)});
        try w.print("const std = @import(\"std\");\n\n", .{});

        try w.print("pub fn evaluatePreState(state_buf: []const u8) bool {{\n", .{});
        try w.print("    // Pre-condition: {s}\n", .{ast.getPre()});
        try w.print("    _ = state_buf;\n", .{});
        try w.print("    return true;\n", .{});
        try w.print("}}\n\n", .{});

        try w.print("pub fn evaluatePostState(state_buf: []const u8) bool {{\n", .{});
        try w.print("    // Post-condition: {s}\n", .{ast.getPost()});
        try w.print("    _ = state_buf;\n", .{});
        try w.print("    return true;\n", .{});
        try w.print("}}\n\n", .{});

        try w.print("pub fn getViolationMessage() []const u8 {{\n", .{});
        try w.print("    return \"{s}\";\n", .{ast.getViolation()});
        try w.print("}}\n", .{});

        return stream.getWritten().len;
    }
};

test "codegen generates valid output buffer" {
    const dsl = "invariant \"Test\" { pre { x > 0 } post { x > 1 } violation: \"Err\" severity: CRITICAL }";
    const p = parser.Parser.init(dsl);
    const ast = try p.parse();
    const cg = Codegen.init();

    var buf: [2048]u8 = undefined;
    const len = try cg.generate(&ast, &buf);
    try std.testing.expect(len > 0);
    try std.testing.expect(std.mem.indexOf(u8, buf[0..len], "Test") != null);
}
