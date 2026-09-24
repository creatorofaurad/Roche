//! Roche EVM Security Engine - Dashboard Server
//! WebSocket server streaming protocol state & solvency alerts.

const std = @import("std");

pub const DashboardServer = struct {
    host: []const u8 = "0.0.0.0",
    port: u16 = 8081,
    client_count: usize = 0,
    running: bool = false,

    pub fn init(host: []const u8, port: u16) DashboardServer {
        return .{
            .host = host,
            .port = port,
        };
    }

    pub fn formatSolvencyAlertFrame(protocol: []const u8, solvency_ratio: f64, out_buf: []u8) usize {
        var json_buf: [512]u8 = undefined;
        const msg = std.fmt.bufPrint(&json_buf,
            \\{{"event":"solvency_alert","protocol":"{s}","solvency_ratio":{d:.4},"alert":{s}}}
        , .{ protocol, solvency_ratio, if (solvency_ratio < 1.0) "true" else "false" }) catch return 0;

        return formatWSFrame(msg, out_buf);
    }

    pub fn formatWSFrame(payload: []const u8, out_buf: []u8) usize {
        if (payload.len > 125) return 0; // Short text frame for dashboard simplicity

        out_buf[0] = 0x81; // FIN + Text frame
        out_buf[1] = @intCast(payload.len);
        @memcpy(out_buf[2 .. 2 + payload.len], payload);
        return 2 + payload.len;
    }

    pub fn start(self: *DashboardServer) !void {
        const address = std.net.Address.parseIp4(self.host, self.port) catch unreachable;
        var server = try address.listen(.{ .reuse_address = true });
        defer server.deinit();

        self.running = true;

        var buf: [2048]u8 = undefined;
        var frame_buf: [2048]u8 = undefined;

        while (self.running) {
            const conn = try server.accept();
            defer conn.stream.close();

            self.client_count += 1;
            const len = formatSolvencyAlertFrame("aave_v3", 0.9821, &frame_buf);
            _ = conn.stream.writeAll(frame_buf[0..len]) catch continue;
            _ = try conn.stream.read(&buf);
        }
    }
};

test "formatSolvencyAlertFrame WS frame" {
    var out: [1024]u8 = undefined;
    const len = DashboardServer.formatSolvencyAlertFrame("aave", 0.95, &out);
    try std.testing.expect(len > 2);
    try std.testing.expectEqual(@as(u8, 0x81), out[0]);
}
