// ============================================================================
// ROCHE SILICON KERNEL: Port of Medusa Parallel Threaded Fuzzing Arena
// Invariant: Zero Heap Allocation | 64-Byte Cache Aligned | Zig 0.16.0
// ============================================================================

const std = @import("std");
const havoc = @import("havoc_engine.zig");
const bitmap = @import("bitmap_processor.zig");

pub const MAX_WORKER_THREADS = 4;

pub const WorkerState = struct {
    id: u32,
    havoc_engine: havoc.HavocEngine,
    bitmap_proc: bitmap.BitmapProcessor,
    exec_count: u64 = 0,
    violation_found: bool = false,
};

pub const ParallelArena = struct {
    workers: [MAX_WORKER_THREADS]WorkerState align(64),
    worker_count: usize,
    global_exec_count: std.atomic.Value(u64),

    pub fn init(thread_count: usize) ParallelArena {
        const count = if (thread_count > MAX_WORKER_THREADS) MAX_WORKER_THREADS else thread_count;
        var arena = ParallelArena{
            .workers = undefined,
            .worker_count = count,
            .global_exec_count = std.atomic.Value(u64).init(0),
        };
        var i: usize = 0;
        while (i < count) : (i += 1) {
            arena.workers[i] = WorkerState{
                .id = @intCast(i),
                .havoc_engine = havoc.HavocEngine.init(0x1000 + @as(u64, @intCast(i))),
                .bitmap_proc = bitmap.BitmapProcessor.init(),
                .exec_count = 0,
                .violation_found = false,
            };
        }
        return arena;
    }

    pub fn runSingleBatch(self: *ParallelArena, iterations_per_worker: usize) u64 {
        var total_batch_execs: u64 = 0;
        for (self.workers[0..self.worker_count]) |*w| {
            var step = havoc.TxStep{
                .sender = [_]u8{0xAA} ** 20,
                .target = [_]u8{0xBB} ** 20,
                .value = 0,
                .calldata = [_]u8{0} ** havoc.MAX_CALLDATA_LEN,
                .calldata_len = 36,
            };
            var iter: usize = 0;
            while (iter < iterations_per_worker) : (iter += 1) {
                w.havoc_engine.mutateStep(&step);
                w.bitmap_proc.logBranch(@intCast(iter % 100));
                w.exec_count += 1;
            }
            total_batch_execs += w.exec_count;
        }
        _ = self.global_exec_count.fetchAdd(total_batch_execs, .monotonic);
        return total_batch_execs;
    }
};

