//! Roche EVM Security Engine - Custom DSL Detector Registry
//! Dynamic detector registry & memory-mapped store logic.

const std = @import("std");
const parser = @import("parser.zig");

pub const MAX_REGISTERED_DETECTORS: usize = 64;
pub const MAX_DETECTOR_CODE_SIZE: usize = 4096;

pub const RegisteredDetector = struct {
    id: u32,
    name: [64]u8 = [_]u8{0} ** 64,
    name_len: usize = 0,
    severity: parser.Severity = .HIGH,
    code_buf: [MAX_DETECTOR_CODE_SIZE]u8 = [_]u8{0} ** MAX_DETECTOR_CODE_SIZE,
    code_len: usize = 0,
    active: bool = false,

    pub fn getName(self: *const RegisteredDetector) []const u8 {
        return self.name[0..self.name_len];
    }

    pub fn getCode(self: *const RegisteredDetector) []const u8 {
        return self.code_buf[0..self.code_len];
    }
};

pub const DetectorRegistry = struct {
    detectors: [MAX_REGISTERED_DETECTORS]RegisteredDetector = [_]RegisteredDetector{.{ .id = 0 }} ** MAX_REGISTERED_DETECTORS,
    count: usize = 0,

    pub fn init() DetectorRegistry {
        return .{};
    }

    pub fn register(self: *DetectorRegistry, name: []const u8, severity: parser.Severity, code: []const u8) !u32 {
        if (self.count >= MAX_REGISTERED_DETECTORS) return error.RegistryFull;

        const idx = self.count;
        var det = &self.detectors[idx];
        det.id = @intCast(idx + 1);

        const name_len = @min(name.len, 64);
        @memcpy(det.name[0..name_len], name[0..name_len]);
        det.name_len = name_len;

        det.severity = severity;

        const code_len = @min(code.len, MAX_DETECTOR_CODE_SIZE);
        @memcpy(det.code_buf[0..code_len], code[0..code_len]);
        det.code_len = code_len;

        det.active = true;
        self.count += 1;

        return det.id;
    }

    pub fn getDetector(self: *const DetectorRegistry, id: u32) ?*const RegisteredDetector {
        if (id == 0 or id > self.count) return null;
        return &self.detectors[id - 1];
    }

    pub fn activeCount(self: *const DetectorRegistry) usize {
        return self.count;
    }
};

test "DetectorRegistry register and retrieve" {
    var reg = DetectorRegistry.init();
    const id = try reg.register("AMM Constant Product", .HIGH, "pub fn check() bool { return true; }");
    try std.testing.expectEqual(@as(u32, 1), id);
    try std.testing.expectEqual(@as(usize, 1), reg.activeCount());

    const det = reg.getDetector(id).?;
    try std.testing.expectEqualStrings("AMM Constant Product", det.getName());
    try std.testing.expectEqual(parser.Severity.HIGH, det.severity);
}
