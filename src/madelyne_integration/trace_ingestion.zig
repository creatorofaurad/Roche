const std = @import("std");

pub const ExploitTracePacket = struct { pc: u32, memory_hash: u64 };

pub const TraceBuffer = struct {
    ring: [1024]ExploitTracePacket = undefined,
    head: usize = 0,
    
    pub fn ingest(self: *TraceBuffer, pkt: ExploitTracePacket) void {
        self.ring[self.head] = pkt;
        self.head = (self.head + 1) % 1024;
    }
};
