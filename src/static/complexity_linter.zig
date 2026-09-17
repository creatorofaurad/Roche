// ============================================================================
// VOLTA SILICON KERNEL: Port of Solhint Complexity & Fallback Bounds Linter
// Invariant: Zero Heap Allocation | 64-Byte Cache Aligned | Zig 0.16.0
// ============================================================================

const std = @import("std");

pub const ComplexityWarning = struct {
    pc_offset: u32,
    cyclomatic_score: u16,
    is_fallback_too_deep: bool,
};

pub const ComplexityLinter = struct {
    warnings: [32]ComplexityWarning align(64),
    warning_count: usize = 0,

    pub fn init() ComplexityLinter {
        return ComplexityLinter{
            .warnings = undefined,
            .warning_count = 0,
        };
    }

    pub fn evaluateBytecode(self: *ComplexityLinter, code: []const u8) []const ComplexityWarning {
        self.warning_count = 0;
        var branches: u16 = 0;
        for (code, 0..) |op, pc| {
            if (op == 0x56 or op == 0x57) { // JUMP / JUMPI
                branches += 1;
                if (branches > 15 and self.warning_count < self.warnings.len) {
                    self.warnings[self.warning_count] = ComplexityWarning{
                        .pc_offset = @intCast(pc),
                        .cyclomatic_score = branches,
                        .is_fallback_too_deep = true,
                    };
                    self.warning_count += 1;
                }
            }
        }
        return self.warnings[0..self.warning_count];
    }
};
