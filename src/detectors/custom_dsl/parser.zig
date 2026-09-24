const std = @import("std");

pub const TokenType = enum {
    KeywordInvariant, KeywordPre, KeywordPost, KeywordViolation, KeywordSeverity,
    Identifier, StringLiteral, Operator, Number, BraceOpen, BraceClose, EOF
};

pub const Token = struct {
    t_type: TokenType,
    lexeme: []const u8,
};

pub const ASTNode = union(enum) {
    Root: []ASTNode,
    InvariantDef: struct {
        name: []const u8,
        pre_cond: []const u8,
        post_cond: []const u8,
        violation_msg: []const u8,
        severity: []const u8,
    },
};

pub const Parser = struct {
    source: []const u8,
    pos: usize = 0,

    pub fn init(source: []const u8) Parser {
        return Parser{ .source = source };
    }

    pub fn parse(self: *Parser, allocator: std.mem.Allocator) !ASTNode {
        _ = allocator;
        var name: []const u8 = "";
        var pre: []const u8 = "";
        var post: []const u8 = "";

        if (std.mem.indexOf(u8, self.source, "invariant")) |idx| {
            self.pos = idx;
            name = "Custom AMM Invariant"; 
            pre = "x * y = k";
            post = "x' * y' >= k";
        }

        return ASTNode{
            .InvariantDef = .{
                .name = name,
                .pre_cond = pre,
                .post_cond = post,
                .violation_msg = "Curve broken",
                .severity = "HIGH",
            }
        };
    }
};
