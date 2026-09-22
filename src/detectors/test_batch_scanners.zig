//! test_batch_scanners.zig: Batch Trace Invariant Verification Runner
//! Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.
//! Direct Win32 FindFirstFileA / FindNextFileA / ReadFile Kernel System Calls.

const std = @import("std");
const bc = @import("bc_inv_01.zig");

const MAX_JSON_SIZE: usize = 131072; // 128 KB fixed buffer per trace file

// Win32 Kernel32 API Declarations (Zero Heap Allocation)
const GENERIC_READ: u32 = 0x80000000;
const FILE_SHARE_READ: u32 = 0x00000001;
const OPEN_EXISTING: u32 = 3;
const FILE_ATTRIBUTE_NORMAL: u32 = 0x00000080;
const INVALID_HANDLE: ?*anyopaque = @ptrFromInt(std.math.maxInt(usize));

const FILE_ATTRIBUTE_DIRECTORY: u32 = 0x10;

const WIN32_FIND_DATAA = extern struct {
    dwFileAttributes: u32,
    ftCreationTimeLow: u32,
    ftCreationTimeHigh: u32,
    ftLastAccessTimeLow: u32,
    ftLastAccessTimeHigh: u32,
    ftLastWriteTimeLow: u32,
    ftLastWriteTimeHigh: u32,
    nFileSizeHigh: u32,
    nFileSizeLow: u32,
    dwReserved0: u32,
    dwReserved1: u32,
    cFileName: [260]u8,
    cAlternateFileName: [14]u8,
};

extern "kernel32" fn FindFirstFileA(
    lpFileName: [*:0]const u8,
    lpFindFileData: *WIN32_FIND_DATAA,
) callconv(@import("std").builtin.CallingConvention.winapi) ?*anyopaque;

extern "kernel32" fn FindNextFileA(
    hFindFile: ?*anyopaque,
    lpFindFileData: *WIN32_FIND_DATAA,
) callconv(@import("std").builtin.CallingConvention.winapi) i32;

extern "kernel32" fn FindClose(
    hFindFile: ?*anyopaque,
) callconv(@import("std").builtin.CallingConvention.winapi) i32;

extern "kernel32" fn CreateFileA(
    lpFileName: [*:0]const u8,
    dwDesiredAccess: u32,
    dwShareMode: u32,
    lpSecurityAttributes: ?*anyopaque,
    dwCreationDisposition: u32,
    dwFlagsAndAttributes: u32,
    hTemplateFile: ?*anyopaque,
) callconv(@import("std").builtin.CallingConvention.winapi) ?*anyopaque;

extern "kernel32" fn ReadFile(
    hFile: ?*anyopaque,
    lpBuffer: [*]u8,
    nNumberOfBytesToRead: u32,
    lpNumberOfBytesRead: ?*u32,
    lpOverlapped: ?*anyopaque,
) callconv(@import("std").builtin.CallingConvention.winapi) i32;

extern "kernel32" fn CloseHandle(
    hObject: ?*anyopaque,
) callconv(@import("std").builtin.CallingConvention.winapi) i32;

fn parseU256(str: []const u8) ?u256 {
    return std.fmt.parseInt(u256, str, 10) catch null;
}

fn extractJsonStringField(source: []const u8, field_key: []const u8, out_buf: []u8) ?usize {
    const key_pos = std.mem.indexOf(u8, source, field_key) orelse return null;
    const colon_pos = std.mem.indexOfPos(u8, source, key_pos + field_key.len, ":") orelse return null;
    const start_quote = std.mem.indexOfPos(u8, source, colon_pos, "\"") orelse return null;
    const end_quote = std.mem.indexOfPos(u8, source, start_quote + 1, "\"") orelse return null;
    const len = end_quote - (start_quote + 1);
    if (len > out_buf.len) return null;
    @memcpy(out_buf[0..len], source[start_quote + 1 .. end_quote]);
    return len;
}

fn parseJsonTraceToState(json_data: []const u8, state: *bc.State) bool {
    state.* = bc.State.init();

    // Parse protocol_fee_pool_balance
    var buf: [64]u8 = undefined;
    if (extractJsonStringField(json_data, "\"protocol_fee_pool_balance\"", &buf)) |len| {
        state.protocol_fee_pool_balance = parseU256(buf[0..len]) orelse 0;
    }

    // Parse is_migrated
    if (std.mem.indexOf(u8, json_data, "\"is_migrated\"")) |pos| {
        const colon_pos = std.mem.indexOfPos(u8, json_data, pos, ":") orelse 0;
        if (colon_pos > 0 and colon_pos + 5 < json_data.len) {
            const val_slice = json_data[colon_pos + 1 .. colon_pos + 6];
            if (std.mem.indexOf(u8, val_slice, "true") != null) {
                state.is_migrated = true;
            }
        }
    }

    // Parse migration fields
    if (extractJsonStringField(json_data, "\"migration_virtual_reserves\"", &buf)) |len| {
        state.migration_virtual_reserves = parseU256(buf[0..len]) orelse 0;
    }
    if (extractJsonStringField(json_data, "\"migrated_target_liquidity\"", &buf)) |len| {
        state.migrated_target_liquidity = parseU256(buf[0..len]) orelse 0;
    }

    // Iterate through transitions array
    const trans_key = "\"transitions\"";
    var cursor = std.mem.indexOf(u8, json_data, trans_key) orelse return true;

    while (state.transition_count < bc.MAX_TRANSITIONS) {
        const obj_start = std.mem.indexOfPos(u8, json_data, cursor, "{") orelse break;
        const obj_end = std.mem.indexOfPos(u8, json_data, obj_start, "}") orelse break;
        const obj_slice = json_data[obj_start .. obj_end + 1];

        var t_type: bc.TransitionType = .Buy;
        if (std.mem.indexOf(u8, obj_slice, "\"transition_type\"")) |t_pos| {
            const colon = std.mem.indexOfPos(u8, obj_slice, t_pos, ":") orelse 0;
            if (colon > 0 and colon + 2 < obj_slice.len) {
                const char = obj_slice[colon + 1 .. colon + 3];
                if (std.mem.indexOf(u8, char, "1") != null) {
                    t_type = .Sell;
                } else if (std.mem.indexOf(u8, char, "2") != null) {
                    t_type = .Migration;
                }
            }
        }

        var v_sol: u256 = 0;
        if (extractJsonStringField(obj_slice, "\"virtual_sol_reserves\"", &buf)) |len| {
            v_sol = parseU256(buf[0..len]) orelse 0;
        }

        var v_token: u256 = 0;
        if (extractJsonStringField(obj_slice, "\"virtual_token_reserves\"", &buf)) |len| {
            v_token = parseU256(buf[0..len]) orelse 0;
        }

        var fee: u256 = 0;
        if (extractJsonStringField(obj_slice, "\"marginal_fee\"", &buf)) |len| {
            fee = parseU256(buf[0..len]) orelse 0;
        }

        state.recordTransition(t_type, v_sol, v_token, fee);
        cursor = obj_end + 1;
    }

    return true;
}

test "BC-INV: Batch Scanner - Mainnet Traces Verification" {
    var file_buffer: [MAX_JSON_SIZE]u8 = undefined;

    const search_pattern: [:0]const u8 = "traces\\*.json";
    var find_data: WIN32_FIND_DATAA = undefined;

    const hFind = FindFirstFileA(search_pattern, &find_data);
    if (hFind == null or hFind == INVALID_HANDLE) {
        std.debug.print("\n[!] Directory 'traces/*.json' not found or empty.\n", .{});
        return;
    }
    defer _ = FindClose(hFind);

    var scanned_count: usize = 0;
    var total_violations: usize = 0;

    std.debug.print("\n=================================================================\n", .{});
    std.debug.print("ROCHE SILICON KERNEL: SCANNING MAINNET TRACES FOR INVARIANT BREAKS\n", .{});
    std.debug.print("=================================================================\n", .{});

    var has_more: i32 = 1;
    while (has_more != 0) : (has_more = FindNextFileA(hFind, &find_data)) {
        if (find_data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY != 0) continue;

        // Extract null-terminated filename
        const name_len = std.mem.sliceTo(&find_data.cFileName, 0).len;
        const filename = find_data.cFileName[0..name_len];

        // Build file path: "traces\\" + filename
        var full_path: [512:0]u8 = undefined;
        @memcpy(full_path[0..7], "traces\\");
        @memcpy(full_path[7 .. 7 + name_len], filename);
        full_path[7 + name_len] = 0;

        const hFile = CreateFileA(
            &full_path,
            GENERIC_READ,
            FILE_SHARE_READ,
            null,
            OPEN_EXISTING,
            FILE_ATTRIBUTE_NORMAL,
            null,
        );

        if (hFile == null or hFile == INVALID_HANDLE) continue;

        var bytes_read: u32 = 0;
        const read_ok = ReadFile(hFile, &file_buffer, @truncate(MAX_JSON_SIZE), &bytes_read, null);
        _ = CloseHandle(hFile);

        if (read_ok == 0 or bytes_read == 0) continue;

        var state: bc.State = undefined;
        if (!parseJsonTraceToState(file_buffer[0..bytes_read], &state)) continue;

        const findings = bc.BondingCurveInvariantDetector.evaluate(&state);
        scanned_count += 1;

        if (findings.count > 0) {
            total_violations += findings.count;
            std.debug.print("\n[!] INVARIANT VIOLATION DETECTED: {s}\n", .{filename});
            for (0..findings.count) |i| {
                const f = findings.items[i];
                std.debug.print("    -> Severity: {d} | {s}\n", .{ @intFromEnum(f.severity), f.getTitle() });
                std.debug.print("       Detail:   {s}\n", .{f.getDescription()});
            }
        }
    }

    std.debug.print("\n-----------------------------------------------------------------\n", .{});
    std.debug.print("Scan Complete: {d} traces evaluated | {d} invariant violations found\n", .{
        scanned_count,
        total_violations,
    });
    std.debug.print("-----------------------------------------------------------------\n\n", .{});
}
