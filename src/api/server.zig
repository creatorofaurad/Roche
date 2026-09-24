//! Roche EVM Security Engine - API Server
//! Zero-alloc / Fixed-buffer HTTP REST & WebSocket Server in Zig 0.16.0

const std = @import("std");
const request_handler = @import("request_handler.zig");
const response_format = @import("response_format.zig");

pub const Route = enum {
    AuditBytecode,
    InvariantVault,
    RiskScore,
    CompileCustomDetector,
    MainnetStreamWS,
    NotFound,
};

pub const ApiServer = struct {
    host: []const u8 = "0.0.0.0",
    port: u16 = 8080,
    running: bool = false,

    pub fn init(host: []const u8, port: u16) ApiServer {
        return .{
            .host = host,
            .port = port,
            .running = false,
        };
    }

    pub fn parseRoute(method: []const u8, path: []const u8) Route {
        if (std.mem.eql(u8, method, "POST") and std.mem.eql(u8, path, "/api/v2/audit/bytecode")) {
            return .AuditBytecode;
        }
        if (std.mem.eql(u8, method, "GET") and std.mem.startsWith(u8, path, "/api/v2/invariant-vault/")) {
            return .InvariantVault;
        }
        if (std.mem.eql(u8, method, "GET") and std.mem.startsWith(u8, path, "/api/v2/risk-score/")) {
            return .RiskScore;
        }
        if (std.mem.eql(u8, method, "POST") and std.mem.eql(u8, path, "/api/v2/custom-detector/compile")) {
            return .CompileCustomDetector;
        }
        if (std.mem.startsWith(u8, path, "/api/v2/mainnet-stream")) {
            return .MainnetStreamWS;
        }
        return .NotFound;
    }

    pub fn handleRawRequest(req_buf: []const u8, resp_buf: []u8) usize {
        var lines = std.mem.splitSequence(u8, req_buf, "\r\n");
        const first_line = lines.next() orelse return response_format.formatError(400, "Bad Request", resp_buf);

        var parts = std.mem.splitScalar(u8, first_line, ' ');
        const method = parts.next() orelse return response_format.formatError(400, "Bad Request", resp_buf);
        const path = parts.next() orelse return response_format.formatError(400, "Bad Request", resp_buf);

        const route = parseRoute(method, path);
        switch (route) {
            .AuditBytecode => {
                var handler = request_handler.RequestHandler.init();
                const req_data = handler.parseAuditRequest(req_buf) catch {
                    return response_format.formatError(400, "Invalid JSON Audit Payload", resp_buf);
                };
                return response_format.formatAuditResponse(&req_data, resp_buf);
            },
            .InvariantVault => {
                const protocol = path["/api/v2/invariant-vault/".len..];
                return response_format.formatInvariantVaultResponse(protocol, resp_buf);
            },
            .RiskScore => {
                const protocol = path["/api/v2/risk-score/".len..];
                return response_format.formatRiskScoreResponse(protocol, resp_buf);
            },
            .CompileCustomDetector => {
                return response_format.formatCompileResponse(resp_buf);
            },
            .MainnetStreamWS => {
                return response_format.formatWSHandshakeResponse(resp_buf);
            },
            .NotFound => {
                return response_format.formatError(404, "Route Not Found", resp_buf);
            },
        }
    }

    pub fn listenAndServe(self: *ApiServer) !void {
        const address = std.net.Address.parseIp4(self.host, self.port) catch unreachable;
        var server = try address.listen(.{ .reuse_address = true });
        defer server.deinit();

        self.running = true;

        var read_buf: [16384]u8 = undefined;
        var write_buf: [16384]u8 = undefined;

        while (self.running) {
            const conn = try server.accept();
            defer conn.stream.close();

            const n = conn.stream.read(&read_buf) catch continue;
            if (n == 0) continue;

            const resp_len = handleRawRequest(read_buf[0..n], &write_buf);
            _ = conn.stream.writeAll(write_buf[0..resp_len]) catch continue;
        }
    }
};

test "parseRoute matching" {
    try std.testing.expectEqual(Route.AuditBytecode, ApiServer.parseRoute("POST", "/api/v2/audit/bytecode"));
    try std.testing.expectEqual(Route.InvariantVault, ApiServer.parseRoute("GET", "/api/v2/invariant-vault/aave"));
    try std.testing.expectEqual(Route.RiskScore, ApiServer.parseRoute("GET", "/api/v2/risk-score/uniswap"));
    try std.testing.expectEqual(Route.CompileCustomDetector, ApiServer.parseRoute("POST", "/api/v2/custom-detector/compile"));
    try std.testing.expectEqual(Route.MainnetStreamWS, ApiServer.parseRoute("GET", "/api/v2/mainnet-stream"));
    try std.testing.expectEqual(Route.NotFound, ApiServer.parseRoute("GET", "/unknown"));
}
