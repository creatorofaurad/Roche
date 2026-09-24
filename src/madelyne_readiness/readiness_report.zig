// ============================================================================
// FILE: src/madelyne_readiness/readiness_report.zig
// DESCRIPTION: Learning readiness report generator for Madelyne v2.1
// ARCHITECTURE: Bare-Silicon Zig 0.16.0 / Zero Heap Allocation / JSON Report Generator
// INVARIANTS: 0 Dynamic Allocations.
// ============================================================================

const std = @import("std");

pub const ReadinessStatus = enum {
    NotReady,
    Bootstrap,
    Ready,
    Production,

    pub fn asString(self: ReadinessStatus) []const u8 {
        return switch (self) {
            .NotReady => "NOT_READY",
            .Bootstrap => "BOOTSTRAP",
            .Ready => "READY",
            .Production => "PRODUCTION",
        };
    }
};

pub const ReadinessMetrics = struct {
    trace_count: u64 = 0,
    matrix_density: f32 = 0.0,
    detector_coverage: f32 = 0.0,
    ged_confidence_score: f64 = 0.0,
};

pub const ReadinessReport = struct {
    status: ReadinessStatus = .NotReady,
    overall_score: f32 = 0.0,
    metrics: ReadinessMetrics = .{},

    pub fn evaluateReadiness(metrics: ReadinessMetrics) ReadinessReport {
        var score: f32 = 0.0;

        // Weight trace count (up to 100 traces = 0.30 weight)
        const trace_contrib: f32 = @min(1.0, @as(f32, @floatFromInt(metrics.trace_count)) / 100.0) * 0.30;
        score += trace_contrib;

        // Weight matrix density (up to 0.5 density = 0.25 weight)
        const density_contrib: f32 = @min(1.0, metrics.matrix_density / 0.50) * 0.25;
        score += density_contrib;

        // Weight detector coverage (0.25 weight)
        score += @min(1.0, metrics.detector_coverage) * 0.25;

        // Weight GED confidence (0.20 weight)
        score += @as(f32, @floatCast(@min(1.0, metrics.ged_confidence_score))) * 0.20;

        const status: ReadinessStatus = if (score >= 0.85)
            .Production
        else if (score >= 0.65)
            .Ready
        else if (score >= 0.30)
            .Bootstrap
        else
            .NotReady;

        return .{
            .status = status,
            .overall_score = score,
            .metrics = metrics,
        };
    }

    pub fn formatReportJson(self: *const ReadinessReport, out_buf: []u8) ![]const u8 {
        return std.fmt.bufPrint(out_buf,
            \\{{"readiness_status":"{s}","overall_score":{d},"metrics":{{"trace_count":{d},"matrix_density":{d},"detector_coverage":{d},"ged_confidence":{d}}}}}
        , .{
            self.status.asString(),
            self.overall_score,
            self.metrics.trace_count,
            self.metrics.matrix_density,
            self.metrics.detector_coverage,
            self.metrics.ged_confidence_score,
        });
    }
};

pub fn printReadiness() void {
    std.debug.print("[Yelena-Madelyne] v2.1 Learning Readiness Report: Bootstrap Ready.\n", .{});
}

// ============================================================================
// UNIT TESTS
// ============================================================================
test "ReadinessReport: Status Threshold Evaluation & JSON Formatting" {
    const metrics = ReadinessMetrics{
        .trace_count = 120,
        .matrix_density = 0.45,
        .detector_coverage = 0.90,
        .ged_confidence_score = 0.95,
    };

    const report = ReadinessReport.evaluateReadiness(metrics);
    try std.testing.expect(report.status == .Ready or report.status == .Production);
    try std.testing.expect(report.overall_score > 0.70);

    var buf: [512]u8 = undefined;
    const json_out = try report.formatReportJson(&buf);

    try std.testing.expect(json_out.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, json_out, "readiness_status") != null);
}
