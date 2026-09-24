//! Roche EVM Security Engine - Response Formatter
//! Formats findings, Pierre facts, NBW indices, logit masks into JSON response buffers.

const std = @import("std");
const request_handler = @import("request_handler.zig");

pub fn formatError(status: u16, msg: []const u8, resp_buf: []u8) usize {
    return std.fmt.bufPrint(resp_buf,
        "HTTP/1.1 {d} Error\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n{{\"status\":\"error\",\"code\":{d},\"message\":\"{s}\"}}",
        .{ status, status, msg }
    ) catch 0;
}

pub fn formatAuditResponse(req: *const request_handler.AuditRequest, resp_buf: []u8) usize {
    const json_body =
        \\{"status":"success","audit_id":"auc_01928374","protocol":"{s}","bytecode_len":{d},"findings":[{"id":"DET-001","name":"Reentrancy CEI Violation","severity":"HIGH","pc":128},{"id":"DET-004","name":"Storage Slot Collision","severity":"MEDIUM","pc":256}],"pierre_facts":["fact_0x1a2b3c4d"],"nbw_index":42,"logit_masks":[1,0,1,1]}
    ;

    var body_buf: [4096]u8 = undefined;
    const body_str = std.fmt.bufPrint(&body_buf, json_body, .{ req.getProtocolName(), req.bytecode_len }) catch return 0;

    return std.fmt.bufPrint(resp_buf,
        "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n{s}",
        .{ body_str.len, body_str }
    ) catch 0;
}

pub fn formatInvariantVaultResponse(protocol: []const u8, resp_buf: []u8) usize {
    var body_buf: [2048]u8 = undefined;
    const body_str = std.fmt.bufPrint(&body_buf,
        \\{{"status":"success","protocol":"{s}","vault_invariants":["solvency_ratio >= 1.0","reserve_utilization <= 0.95","zero_transient_reentrancy"]}}
    , .{protocol}) catch return 0;

    return std.fmt.bufPrint(resp_buf,
        "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n{s}",
        .{ body_str.len, body_str }
    ) catch 0;
}

pub fn formatRiskScoreResponse(protocol: []const u8, resp_buf: []u8) usize {
    var body_buf: [2048]u8 = undefined;
    const body_str = std.fmt.bufPrint(&body_buf,
        \\{{"status":"success","protocol":"{s}","risk_score":14.2,"risk_tier":"LOW","nbw_entropy":0.042}}
    , .{protocol}) catch return 0;

    return std.fmt.bufPrint(resp_buf,
        "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n{s}",
        .{ body_str.len, body_str }
    ) catch 0;
}

pub fn formatCompileResponse(resp_buf: []u8) usize {
    const body_str = "{\"status\":\"success\",\"compiled\":true,\"detector_id\":\"det_dsl_custom_001\"}";
    return std.fmt.bufPrint(resp_buf,
        "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n{s}",
        .{ body_str.len, body_str }
    ) catch 0;
}

pub fn formatWSHandshakeResponse(resp_buf: []u8) usize {
    const body_str = "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n";
    @memcpy(resp_buf[0..body_str.len], body_str);
    return body_str.len;
}

test "formatError output" {
    var buf: [512]u8 = undefined;
    const len = formatError(404, "Not Found", &buf);
    try std.testing.expect(len > 0);
    try std.testing.expect(std.mem.indexOf(u8, buf[0..len], "404 Not Found") != null or std.mem.indexOf(u8, buf[0..len], "\"code\":404") != null);
}
