// ============================================================================
// ROCHE SILICON KERNEL: Institutional Zero-Heap CLI & Kernel Router
// Invariant: Zero Heap Allocation | OS-Level MMap | Zig 0.16.0
// ============================================================================

const std = @import("std");
const builtin = @import("builtin");
const orchestrator = @import("orchestrator.zig");

// 1. The CI/CD Exit Code Contract
pub const ExitCode = enum(u8) {
    Success = 0,
    InvariantBreached = 1,
    MalformedInput = 2,
    SigIntTerminated = 130,
};

// Global interrupt flag mapped to hardware registers
pub var sigint_triggered: std.atomic.Value(bool) = std.atomic.Value(bool).init(false);

// Direct Win32 Kernel32 Silicon Definitions
const PAGE_READONLY: u32 = 0x02;
const FILE_MAP_READ: u32 = 0x0004;

extern "kernel32" fn CreateFileMappingA(
    hFile: ?*anyopaque,
    lpFileMappingAttributes: ?*anyopaque,
    flProtect: u32,
    dwMaximumSizeHigh: u32,
    dwMaximumSizeLow: u32,
    lpName: ?[*:0]const u8,
) callconv(.winapi) ?*anyopaque;

extern "kernel32" fn MapViewOfFile(
    hFileMappingObject: ?*anyopaque,
    dwDesiredAccess: u32,
    dwFileOffsetHigh: u32,
    dwFileOffsetLow: u32,
    dwNumberOfBytesToMap: usize,
) callconv(.winapi) ?*anyopaque;

extern "kernel32" fn UnmapViewOfFile(
    lpBaseAddress: ?*anyopaque,
) callconv(.winapi) i32;

extern "kernel32" fn CloseHandle(
    hObject: ?*anyopaque,
) callconv(.winapi) i32;

extern "kernel32" fn SetConsoleCtrlHandler(
    HandlerRoutine: ?*const fn (dwCtrlType: u32) callconv(.winapi) i32,
    Add: i32,
) callconv(.winapi) i32;

fn win32ConsoleHandler(ctrl_type: u32) callconv(.winapi) i32 {
    _ = ctrl_type;
    sigint_triggered.store(true, .seq_cst);
    std.debug.print("\n\x1b[31;1m[ROCHE KERNEL] SIGINT Trapped. Halting workers & synthesizing partial trace...\x1b[0m\n", .{});
    return 1;
}

// 2. Bare-Metal Signal Trapping (POSIX / Win32)
fn handleSigIntPosix(sig: c_int) callconv(.c) void {
    _ = sig;
    sigint_triggered.store(true, .seq_cst);
    std.debug.print("\n\x1b[31;1m[ROCHE KERNEL] SIGINT Trapped. Halting workers & synthesizing partial trace...\x1b[0m\n", .{});
}

pub fn bindInterruptHandlers() void {
    if (builtin.os.tag == .windows) {
        _ = SetConsoleCtrlHandler(win32ConsoleHandler, 1);
    } else {
        const posix = std.posix;
        var act = posix.Sigaction{
            .handler = .{ .handler = handleSigIntPosix },
            .mask = posix.empty_sigset,
            .flags = 0,
        };
        posix.sigaction(posix.SIG.INT, &act, null) catch {};
    }
}

// 3. Zero-Copy Kernel Memory Mapping (Bypass RAM Allocators)
pub fn mapTargetFile(path: []const u8) ![]align(64) const u8 {
    const file = try std.fs.cwd().openFile(path, .{ .mode = .read_only });
    defer file.close();

    const file_size = try file.getEndPos();
    if (file_size == 0) return error.EmptyTarget;

    if (builtin.os.tag == .windows) {
        const mapping = CreateFileMappingA(
            file.handle,
            null,
            PAGE_READONLY,
            0,
            0,
            null,
        );
        if (mapping == null) return error.MMapFailed;
        defer _ = CloseHandle(mapping);

        const ptr = MapViewOfFile(
            mapping,
            FILE_MAP_READ,
            0,
            0,
            0,
        );
        if (ptr == null) return error.MMapFailed;

        // Cast raw OS pointer to 64-byte aligned slice
        return @as([*]align(64) const u8, @ptrCast(@alignCast(ptr)))[0..file_size];
    } else {
        const posix = std.posix;
        const ptr = try posix.mmap(
            null,
            file_size,
            posix.PROT.READ,
            posix.MAP.PRIVATE,
            file.handle,
            0,
        );
        return @as([*]align(64) const u8, @ptrCast(@alignCast(ptr.ptr)))[0..file_size];
    }
}

// 4. Zero-Heap VT100 Telemetry Dashboard
pub fn printTelemetry(cycles: u64, coverage: u16, throughput: u64) void {
    std.debug.print("\x1b[1A\x1b[2K\x1b[36m[ROCHE]\x1b[0m Cycles: \x1b[1m{d}\x1b[0m | Edges: \x1b[33m{d}/65536\x1b[0m | Speed: \x1b[32m{d} tx/sec\x1b[0m\n", .{ cycles, coverage, throughput });
}

test "Kernel Router: Exit Codes & Signal Registration" {
    bindInterruptHandlers();
    try std.testing.expectEqual(@as(u8, 0), @intFromEnum(ExitCode.Success));
    try std.testing.expectEqual(@as(u8, 1), @intFromEnum(ExitCode.InvariantBreached));
    try std.testing.expectEqual(@as(u8, 2), @intFromEnum(ExitCode.MalformedInput));
    try std.testing.expectEqual(@as(u8, 130), @intFromEnum(ExitCode.SigIntTerminated));
}
