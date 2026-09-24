//! Roche EVM Security Engine - Audit Manifest Generator
//! Audit manifest JSON generator with SHA-256 hashes and compiler information.

const std = @import("std");

fn hexLower(bytes: []const u8, out_hex: []u8) []u8 {
    const charset = "0123456789abcdef";
    var i: usize = 0;
    for (bytes) |b| {
        if (i + 1 >= out_hex.len) break;
        out_hex[i] = charset[b >> 4];
        out_hex[i + 1] = charset[b & 0x0F];
        i += 2;
    }
    return out_hex[0..i];
}

pub const AuditManifest = struct {
    roche_version: []const u8 = "1.0.0-beta",
    zig_compiler_version: []const u8 = "0.16.0",
    zig_compiler_hash: []const u8 = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    target_bytecode_hash: [64]u8 = [_]u8{'0'} ** 64,
    test_harness_commit: []const u8 = "head",
    output_findings_hash: [64]u8 = [_]u8{'0'} ** 64,
    reproducibility_command: []const u8 = "zig test src/test_master_suite.zig",

    pub fn setBytecodeHash(self: *AuditManifest, bytecode: []const u8) void {
        var hash_out: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(bytecode, &hash_out, .{});
        _ = hexLower(&hash_out, &self.target_bytecode_hash);
    }

    pub fn setFindingsHash(self: *AuditManifest, findings_json: []const u8) void {
        var hash_out: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(findings_json, &hash_out, .{});
        _ = hexLower(&hash_out, &self.output_findings_hash);
    }

    pub fn toJson(self: *const AuditManifest, arena: std.mem.Allocator) ![]const u8 {
        return try std.json.stringifyAlloc(arena, self, .{ .whitespace = .indent_4 });
    }
};

pub const Manifest = AuditManifest;

test "AuditManifest setBytecodeHash" {
    var m = AuditManifest{};
    m.setBytecodeHash("6080604052");
    try std.testing.expect(m.target_bytecode_hash[0] != '0');
}
