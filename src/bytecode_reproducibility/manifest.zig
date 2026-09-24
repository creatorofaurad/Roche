const std = @import("std");

pub const Manifest = struct {
    roche_version: []const u8,
    zig_compiler_hash: []const u8,
    target_bytecode_hash: []const u8,
    test_harness_commit: []const u8,
    output_findings_hash: []const u8,
    reproducibility_command: []const u8,

    pub fn toJson(self: *Manifest, arena: std.mem.Allocator) ![]const u8 {
        return try std.json.stringifyAlloc(arena, self, .{ .whitespace = .indent_4 });
    }
};
