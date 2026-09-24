//! Roche EVM Security Engine - Custom DSL Parser
//! Parses invariant "name" { pre { ... } post { ... } violation: "..." severity: HIGH }

const std = @import("std");

pub const Severity = enum {
    INFO,
    LOW,
    MEDIUM,
    HIGH,
    CRITICAL,

    pub fn parse(s: []const u8) Severity {
        if (std.mem.eql(u8, s, "CRITICAL")) return .CRITICAL;
        if (std.mem.eql(u8, s, "HIGH")) return .HIGH;
        if (std.mem.eql(u8, s, "MEDIUM")) return .MEDIUM;
        if (std.mem.eql(u8, s, "LOW")) return .LOW;
        return .INFO;
    }
};

pub const InvariantAST = struct {
    name: [128]u8 = [_]u8{0} ** 128,
    name_len: usize = 0,

    pre_condition: [512]u8 = [_]u8{0} ** 512,
    pre_len: usize = 0,

    post_condition: [512]u8 = [_]u8{0} ** 512,
    post_len: usize = 0,

    violation_msg: [256]u8 = [_]u8{0} ** 256,
    violation_len: usize = 0,

    severity: Severity = .HIGH,

    pub fn getName(self: *const InvariantAST) []const u8 {
        return self.name[0..self.name_len];
    }

    pub fn getPre(self: *const InvariantAST) []const u8 {
        return self.pre_condition[0..self.pre_len];
    }

    pub fn getPost(self: *const InvariantAST) []const u8 {
        return self.post_condition[0..self.post_len];
    }

    pub fn getViolation(self: *const InvariantAST) []const u8 {
        return self.violation_msg[0..self.violation_len];
    }
};

pub const Parser = struct {
    source: []const u8,

    pub fn init(source: []const u8) Parser {
        return .{ .source = source };
    }

    pub fn parse(self: *const Parser) !InvariantAST {
        var ast = InvariantAST{};

        // Extract invariant name: invariant "..."
        if (std.mem.indexOf(u8, self.source, "invariant")) |inv_pos| {
            const after_inv = self.source[inv_pos + 9 ..];
            if (std.mem.indexOfScalar(u8, after_inv, '"')) |q1| {
                const after_q1 = after_inv[q1 + 1 ..];
                if (std.mem.indexOfScalar(u8, after_q1, '"')) |q2| {
                    const name = after_q1[0..q2];
                    const len = @min(name.len, 128);
                    @memcpy(ast.name[0..len], name[0..len]);
                    ast.name_len = len;
                }
            }
        }

        // Extract pre { ... }
        if (std.mem.indexOf(u8, self.source, "pre")) |pre_pos| {
            if (extractBlock(self.source[pre_pos + 3 ..])) |pre_block| {
                const len = @min(pre_block.len, 512);
                @memcpy(ast.pre_condition[0..len], pre_block[0..len]);
                ast.pre_len = len;
            }
        }

        // Extract post { ... }
        if (std.mem.indexOf(u8, self.source, "post")) |post_pos| {
            if (extractBlock(self.source[post_pos + 4 ..])) |post_block| {
                const len = @min(post_block.len, 512);
                @memcpy(ast.post_condition[0..len], post_block[0..len]);
                ast.post_len = len;
            }
        }

        // Extract violation: "..."
        if (std.mem.indexOf(u8, self.source, "violation:")) |viol_pos| {
            const after_viol = self.source[viol_pos + 10 ..];
            if (std.mem.indexOfScalar(u8, after_viol, '"')) |q1| {
                const after_q1 = after_viol[q1 + 1 ..];
                if (std.mem.indexOfScalar(u8, after_q1, '"')) |q2| {
                    const viol = after_q1[0..q2];
                    const len = @min(viol.len, 256);
                    @memcpy(ast.violation_msg[0..len], viol[0..len]);
                    ast.violation_len = len;
                }
            }
        }

        // Extract severity: HIGH
        if (std.mem.indexOf(u8, self.source, "severity:")) |sev_pos| {
            const after_sev = std.mem.trimLeft(u8, self.source[sev_pos + 9 ..], " \t\r\n");
            var end: usize = 0;
            while (end < after_sev.len and std.ascii.isAlphabetic(after_sev[end])) : (end += 1) {}
            if (end > 0) {
                ast.severity = Severity.parse(after_sev[0..end]);
            }
        }

        return ast;
    }
};

fn extractBlock(s: []const u8) ?[]const u8 {
    const open = std.mem.indexOfScalar(u8, s, '{') orelse return null;
    const close = std.mem.indexOfScalar(u8, s[open + 1 ..], '}') orelse return null;
    return std.mem.trim(u8, s[open + 1 .. open + 1 + close], " \t\r\n");
}

test "parse invariant DSL" {
    const dsl =
        \\invariant "Vault Solvency" {
        \\  pre { balance >= total_shares }
        \\  post { balance >= total_shares }
        \\  violation: "Solvency invariant violated"
        \\  severity: HIGH
        \\}
    ;
    const parser = Parser.init(dsl);
    const ast = try parser.parse();
    try std.testing.expectEqualStrings("Vault Solvency", ast.getName());
    try std.testing.expectEqualStrings("balance >= total_shares", ast.getPre());
    try std.testing.expectEqualStrings("balance >= total_shares", ast.getPost());
    try std.testing.expectEqualStrings("Solvency invariant violated", ast.getViolation());
    try std.testing.expectEqual(Severity.HIGH, ast.severity);
}
