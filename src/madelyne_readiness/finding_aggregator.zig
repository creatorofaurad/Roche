// ============================================================================
// FILE: src/madelyne_readiness/finding_aggregator.zig
// DESCRIPTION: Protocol pattern aggregator and zero-allocation JSON builder
// ARCHITECTURE: Bare-Silicon Zig 0.16.0 / Fixed-Buffer Formatter / Zero Heap Alloc
// INVARIANTS: 0 Dynamic Allocations.
// ============================================================================

const std = @import("std");

pub const Severity = enum {
    Info,
    Low,
    Medium,
    High,
    Critical,

    pub fn asString(self: Severity) []const u8 {
        return switch (self) {
            .Info => "INFO",
            .Low => "LOW",
            .Medium => "MEDIUM",
            .High => "HIGH",
            .Critical => "CRITICAL",
        };
    }
};

pub const Finding = struct {
    detector_id: u32 = 0,
    severity: Severity = .Info,
    pc: u32 = 0,
    pattern_hash: u64 = 0,
    title: [64]u8 = [_]u8{0} ** 64,
    title_len: u8 = 0,
};

pub const MaxFindings: usize = 64;

pub const FindingAggregator = struct {
    findings: [MaxFindings]Finding = [_]Finding{.{}} ** MaxFindings,
    findings_cnt: usize = 0,
    critical_cnt: u32 = 0,
    high_cnt: u32 = 0,
    medium_cnt: u32 = 0,
    low_cnt: u32 = 0,

    pub fn init() FindingAggregator {
        return .{
            .findings = [_]Finding{.{}} ** MaxFindings,
            .findings_cnt = 0,
            .critical_cnt = 0,
            .high_cnt = 0,
            .medium_cnt = 0,
            .low_cnt = 0,
        };
    }

    pub fn addFinding(self: *FindingAggregator, finding: Finding) bool {
        if (self.findings_cnt >= MaxFindings) return false;
        self.findings[self.findings_cnt] = finding;
        self.findings_cnt += 1;

        switch (finding.severity) {
            .Critical => self.critical_cnt += 1,
            .High => self.high_cnt += 1,
            .Medium => self.medium_cnt += 1,
            .Low, .Info => self.low_cnt += 1,
        }
        return true;
    }

    pub fn aggregateFindings(self: *FindingAggregator) void {
        std.debug.print("[Yelena-Madelyne] Aggregating {d} common patterns for V2.1 training...\n", .{self.findings_cnt});
    }

    pub fn buildJsonReport(self: *const FindingAggregator, out_buf: []u8) ![]const u8 {
        var stream = std.io.fixedBufferStream(out_buf);
        const writer = stream.writer();

        try writer.print(
            \\{{"status":"SUCCESS","total_findings":{d},"summary":{{"critical":{d},"high":{d},"medium":{d},"low":{d}}},"findings":[
        , .{ self.findings_cnt, self.critical_cnt, self.high_cnt, self.medium_cnt, self.low_cnt });

        var i: usize = 0;
        while (i < self.findings_cnt) : (i += 1) {
            const f = self.findings[i];
            const title_slice = f.title[0..f.title_len];
            if (i > 0) try writer.writeAll(",");
            try writer.print(
                \\{{"detector_id":{d},"severity":"{s}","pc":{d},"pattern_hash":"0x{x}","title":"{s}"}}
            , .{ f.detector_id, f.severity.asString(), f.pc, f.pattern_hash, title_slice });
        }

        try writer.writeAll("]}");
        return stream.getWritten();
    }
};

// ============================================================================
// UNIT TESTS
// ============================================================================
test "FindingAggregator: Aggregation & Zero-Heap JSON Generation" {
    var aggregator = FindingAggregator.init();

    var f1 = Finding{
        .detector_id = 42,
        .severity = .Critical,
        .pc = 0x01E0,
        .pattern_hash = 0xDeadBeef12345678,
        .title_len = 25,
    };
    @memcpy(f1.title[0..25], "ERC-4626 Inflation Vector");

    try std.testing.expect(aggregator.addFinding(f1));
    try std.testing.expectEqual(@as(usize, 1), aggregator.findings_cnt);
    try std.testing.expectEqual(@as(u32, 1), aggregator.critical_cnt);

    var json_buf: [1024]u8 = undefined;
    const json_out = try aggregator.buildJsonReport(&json_buf);

    try std.testing.expect(json_out.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, json_out, "\"status\":\"SUCCESS\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, json_out, "ERC-4626 Inflation Vector") != null);
}
