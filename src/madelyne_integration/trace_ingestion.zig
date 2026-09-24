// ============================================================================
// FILE: src/madelyne_integration/trace_ingestion.zig
// DESCRIPTION: ExploitTracePacket ring buffer ingestion system
// ARCHITECTURE: Bare-Silicon Zig 0.16.0 / Lock-Free SPSC / Fixed-Buffer Ingestion
// INVARIANTS: Zero Dynamic Heap Allocations. 64-Byte Cache Line Aligned.
// ============================================================================

const std = @import("std");

pub const StorageSlotDiff = extern struct {
    address: [20]u8 = [_]u8{0} ** 20,
    slot: [32]u8 = [_]u8{0} ** 32,
    old_value: [32]u8 = [_]u8{0} ** 32,
    new_value: [32]u8 = [_]u8{0} ** 32,
    opcode: u8 = 0,
    padding: [11]u8 = [_]u8{0} ** 11,
};

pub const BranchConstraint = extern struct {
    pc_offset: u64 = 0,
    opcode: u8 = 0,
    condition_met: u8 = 0,
    padding: [6]u8 = [_]u8{0} ** 6,
    stack_operands: [32]u8 = [_]u8{0} ** 32,
};

pub const ExploitTracePacket = extern struct {
    timestamp_ns: u64 = 0,
    bytecode_len: u16 = 0,
    bytecode: [256]u8 = [_]u8{0} ** 256,
    storage_diffs_len: u8 = 0,
    branch_constraints_len: u8 = 0,
    invariant_violated: u8 = 0,
    padding_header: [5]u8 = [_]u8{0} ** 5,
    storage_changes: [16]StorageSlotDiff = [_]StorageSlotDiff{.{}} ** 16,
    branch_constraints: [8]BranchConstraint = [_]BranchConstraint{.{}} ** 8,
    padding_tail: [40]u8 = [_]u8{0} ** 40,
};

pub const RingBufferCapacity: usize = 1024;

pub const TraceIngestionBuffer = struct {
    ring: [RingBufferCapacity]ExploitTracePacket align(64) = undefined,
    head: std.atomic.Value(usize) align(64) = std.atomic.Value(usize).init(0),
    tail: std.atomic.Value(usize) align(64) = std.atomic.Value(usize).init(0),
    packets_ingested: u64 = 0,
    packets_dropped: u64 = 0,
    total_bytes_ingested: u64 = 0,

    pub fn init() TraceIngestionBuffer {
        return .{
            .head = std.atomic.Value(usize).init(0),
            .tail = std.atomic.Value(usize).init(0),
            .ring = undefined,
            .packets_ingested = 0,
            .packets_dropped = 0,
            .total_bytes_ingested = 0,
        };
    }

    pub fn ingest(self: *TraceIngestionBuffer, pkt: ExploitTracePacket) bool {
        const t = self.tail.load(.monotonic);
        const h = self.head.load(.acquire);

        if (t - h >= RingBufferCapacity) {
            self.packets_dropped += 1;
            return false;
        }

        self.ring[t % RingBufferCapacity] = pkt;
        self.tail.store(t + 1, .release);
        self.packets_ingested += 1;
        self.total_bytes_ingested += @sizeOf(ExploitTracePacket);
        return true;
    }

    pub fn pop(self: *TraceIngestionBuffer) ?ExploitTracePacket {
        const h = self.head.load(.monotonic);
        const t = self.tail.load(.acquire);

        if (h >= t) return null;

        const pkt = self.ring[h % RingBufferCapacity];
        self.head.store(h + 1, .release);
        return pkt;
    }

    pub fn len(self: *const TraceIngestionBuffer) usize {
        const t = self.tail.load(.monotonic);
        const h = self.head.load(.monotonic);
        if (t >= h) return t - h;
        return 0;
    }

    pub fn isFull(self: *const TraceIngestionBuffer) bool {
        return self.len() >= RingBufferCapacity;
    }

    pub fn isEmpty(self: *const TraceIngestionBuffer) bool {
        return self.len() == 0;
    }
};

// ============================================================================
// UNIT TESTS
// ============================================================================
test "TraceIngestion: Lock-free SPSC Ring Buffer Ingestion" {
    var ingestor = TraceIngestionBuffer.init();
    try std.testing.expect(ingestor.isEmpty());

    var pkt1 = ExploitTracePacket{};
    pkt1.timestamp_ns = 1000;
    pkt1.invariant_violated = 7;
    pkt1.bytecode_len = 16;

    const pushed = ingestor.ingest(pkt1);
    try std.testing.expect(pushed);
    try std.testing.expectEqual(@as(usize, 1), ingestor.len());
    try std.testing.expectEqual(@as(u64, 1), ingestor.packets_ingested);

    const popped = ingestor.pop();
    try std.testing.expect(popped != null);
    try std.testing.expectEqual(@as(u8, 7), popped.?.invariant_violated);
    try std.testing.expect(ingestor.isEmpty());
}

test "TraceIngestion: Buffer Overflow Drop Policy" {
    var ingestor = TraceIngestionBuffer.init();

    var i: usize = 0;
    while (i < RingBufferCapacity) : (i += 1) {
        var pkt = ExploitTracePacket{};
        pkt.timestamp_ns = @intCast(i);
        try std.testing.expect(ingestor.ingest(pkt));
    }

    try std.testing.expect(ingestor.isFull());

    // 1025th packet should drop
    var overflow_pkt = ExploitTracePacket{};
    overflow_pkt.timestamp_ns = 99999;
    try std.testing.expect(!ingestor.ingest(overflow_pkt));
    try std.testing.expectEqual(@as(u64, 1), ingestor.packets_dropped);
}
