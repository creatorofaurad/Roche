//! Roche EVM Security Engine - Bytecode Audit Verifier
//! Bitwise verification logic for third-party audit reproducibility.

const std = @import("std");
const manifest = @import("manifest.zig");

pub const VerificationStatus = enum {
    EXACT_BITWISE_MATCH,
    BYTECODE_HASH_MISMATCH,
    FINDINGS_HASH_MISMATCH,
    COMPILER_MISMATCH,
};

pub const BytecodeVerifier = struct {
    pub fn init() BytecodeVerifier {
        return .{};
    }

    pub fn verify(
        self: *const BytecodeVerifier,
        audit_manifest: *const manifest.AuditManifest,
        actual_bytecode: []const u8,
        actual_findings_json: []const u8
    ) VerificationStatus {
        _ = self;

        // Compute SHA-256 of actual bytecode
        var bc_hash_raw: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(actual_bytecode, &bc_hash_raw, .{});
        var bc_hash_hex: [64]u8 = undefined;
        _ = std.fmt.bufPrint(&bc_hash_hex, "{s}", .{std.fmt.fmtSliceHexLower(&bc_hash_raw)}) catch return .BYTECODE_HASH_MISMATCH;

        if (!std.mem.eql(u8, &bc_hash_hex, &audit_manifest.target_bytecode_hash)) {
            return .BYTECODE_HASH_MISMATCH;
        }

        // Compute SHA-256 of actual findings
        var find_hash_raw: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(actual_findings_json, &find_hash_raw, .{});
        var find_hash_hex: [64]u8 = undefined;
        _ = std.fmt.bufPrint(&find_hash_hex, "{s}", .{std.fmt.fmtSliceHexLower(&find_hash_raw)}) catch return .FINDINGS_HASH_MISMATCH;

        if (!std.mem.eql(u8, &find_hash_hex, &audit_manifest.output_findings_hash)) {
            return .FINDINGS_HASH_MISMATCH;
        }

        return .EXACT_BITWISE_MATCH;
    }
};

test "BytecodeVerifier exact match" {
    var m = manifest.AuditManifest{};
    const bc = "6080604052";
    const find = "{\"findings\":[]}";
    m.setBytecodeHash(bc);
    m.setFindingsHash(find);

    const v = BytecodeVerifier.init();
    const res = v.verify(&m, bc, find);
    try std.testing.expectEqual(VerificationStatus.EXACT_BITWISE_MATCH, res);
}
