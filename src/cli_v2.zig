//! cli_v2.zig: Roche v2 Master Command Line Interface
//! Invariant: Zero Dynamic Heap Allocation | Zig 0.16.0 | Direct OS Sockets & Named Pipes

const std = @import("std");
const detectors = @import("detectors_v2.zig");
const orchestrator = @import("ingestion_orchestrator.zig");
const cli_v1 = @import("cli.zig");

pub const CliV2 = struct {
    handler_v1: cli_v1.CliHandler = cli_v1.CliHandler.init(),

    pub fn printBanner() void {
        std.debug.print(
            \\=============================================================================
            \\   ROCHE v2: INSTITUTIONAL EVM INVARIANT PROVER & 3-TIER MAINNET STREAMER
            \\   90 DETECTORS | ZERO HEAP | AVX2 SIMD | ZIG 0.16.0 | HARDENED BARE SILICON
            \\=============================================================================
            \\
        , .{});
    }

    pub fn listDetectors() void {
        printBanner();
        std.debug.print("Active Registered Detectors ({}/{}):\n\n", .{ detectors.DETECTOR_REGISTRY.len, detectors.DETECTOR_REGISTRY.len });
        for (detectors.DETECTOR_REGISTRY, 0..) |det, i| {
            std.debug.print("  [{d:0>2}] {s:<36} [{s:<12}] (Severity: {d:0>2}/10 | {s})\n", .{
                i + 1,
                det.name,
                det.category,
                det.severity,
                det.cwe,
            });
        }
    }
};

test "CliV2: Banner & Detector Registry Listing" {
    CliV2.listDetectors();
    try std.testing.expectEqual(@as(usize, 90), detectors.DETECTOR_REGISTRY.len);
}
