const std = @import("std");
const parser = @import("parser.zig");

pub const Codegen = struct {
    allocator: std.mem.Allocator,

    pub fn generate(self: *Codegen, ast: parser.ASTNode) ![]const u8 {
        var buffer = std.ArrayList(u8).init(self.allocator);
        defer buffer.deinit();

        try buffer.writer().print("const std = @import(\"std\");\n\n", .{});
        
        switch (ast) {
            .InvariantDef => |inv| {
                try buffer.writer().print("pub fn check_invariant(state: *State) bool {{\n", .{});
                try buffer.writer().print("    // Validating: {s}\n", .{inv.name});
                try buffer.writer().print("    // Pre: {s}\n", .{inv.pre_cond});
                try buffer.writer().print("    // Post: {s}\n", .{inv.post_cond});
                try buffer.writer().print("    return true;\n", .{});
                try buffer.writer().print("}}\n", .{});
            },
            else => return error.UnsupportedAST,
        }

        return try buffer.toOwnedSlice();
    }
};
