const std = @import("std");

pub const PatternMatrix = struct {
    // Pre-allocated O(N^2) cross-link matrix for V2.1 Madelyne
    data: []f32,
};
