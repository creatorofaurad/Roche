// ============================================================================
// ROCHE SILICON KERNEL: Port of Heimdall SIMD Jump-Table Selector Matcher
// Invariant: Zero Heap Allocation | 64-Byte Cache Aligned | Zig 0.16.0
// ============================================================================

const std = @import("std");

pub const FunctionSelectorMatch = struct {
    selector: [4]u8,
    jumpdest_pc: u32,
};

pub const JumpdestMatcher = struct {
    matches: [64]FunctionSelectorMatch align(64),
    match_count: usize = 0,

    pub fn init() JumpdestMatcher {
        return JumpdestMatcher{
            .matches = undefined,
            .match_count = 0,
        };
    }

    pub fn scanBytecode(self: *JumpdestMatcher, code: []const u8) []const FunctionSelectorMatch {
        self.match_count = 0;
        if (code.len < 8) return self.matches[0..0];

        var i: usize = 0;
        while (i + 7 < code.len) : (i += 1) {
            if (code[i] == 0x63 and i + 5 <= code.len) { // PUSH4 selector
                const sel = code[i + 1 .. i + 5];
                var offset = i + 5;
                if (offset < code.len and code[offset] == 0x81) offset += 1; // optional DUP2
                if (offset < code.len and (code[offset] == 0x14 or code[offset] == 0x10 or code[offset] == 0x11)) { // EQ
                    offset += 1;
                    var target_pc: u32 = 0;
                    if (offset < code.len and code[offset] == 0x60 and offset + 2 < code.len) { // PUSH1
                        target_pc = code[offset + 1];
                    } else if (offset < code.len and code[offset] == 0x61 and offset + 3 < code.len) { // PUSH2
                        target_pc = (@as(u32, code[offset + 1]) << 8) | @as(u32, code[offset + 2]);
                    }
                    if (self.match_count < self.matches.len) {
                        self.matches[self.match_count] = FunctionSelectorMatch{
                            .selector = sel[0..4].*,
                            .jumpdest_pc = target_pc,
                        };
                        self.match_count += 1;
                    }
                }
            }
        }
        return self.matches[0..self.match_count];
    }
};

