//! Roche EVM Security Engine - Pierre Vault HTTP Server
//! Immutable Pierre ground-truth fact HTTP lookup endpoint.

const std = @import("std");
const fact_query = @import("fact_query.zig");

pub const VaultHttpServer = struct {
    host: []const u8 = "0.0.0.0",
    port: u16 = 8082,
    query_engine: fact_query.FactQueryEngine = fact_query.FactQueryEngine.init(),

    pub fn init(host: []const u8, port: u16) VaultHttpServer {
        return .{
            .host = host,
            .port = port,
        };
    }

    pub fn handleFactLookup(self: *const VaultHttpServer, path: []const u8, resp_buf: []u8) usize {
        const prefix = "/api/v2/pierre/fact/";
        if (!std.mem.startsWith(u8, path, prefix)) {
            return std.fmt.bufPrint(resp_buf,
                "HTTP/1.1 404 Not Found\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n{{\"error\":\"Fact route not found\"}}"
            ) catch 0;
        }

        const fact_id_str = path[prefix.len..];
        const fact_id = std.fmt.parseInt(u32, fact_id_str, 10) catch {
            return std.fmt.bufPrint(resp_buf,
                "HTTP/1.1 400 Bad Request\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n{{\"error\":\"Invalid fact ID\"}}"
            ) catch 0;
        };

        if (self.query_engine.lookupFact(fact_id)) |fact| {
            var body_buf: [512]u8 = undefined;
            const body = std.fmt.bufPrint(&body_buf,
                \\{{"status":"success","fact_id":{d},"protocol":"{s}","key":"{s}","value":{d}}}
            , .{ fact.id, fact.getProtocol(), fact.getKey(), fact.value }) catch return 0;

            return std.fmt.bufPrint(resp_buf,
                "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n{s}",
                .{ body.len, body }
            ) catch 0;
        } else {
            return std.fmt.bufPrint(resp_buf,
                "HTTP/1.1 444 Fact Not Found\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n{{\"error\":\"Fact not present in Pierre vault\"}}"
            ) catch 0;
        }
    }
};

test "VaultHttpServer lookup" {
    var v = VaultHttpServer.init("0.0.0.0", 8082);
    _ = try v.query_engine.insertFact("aave", "total_borrows", 1000000);

    var resp: [1024]u8 = undefined;
    const len = v.handleFactLookup("/api/v2/pierre/fact/1", &resp);
    try std.testing.expect(len > 0);
    try std.testing.expect(std.mem.indexOf(u8, resp[0..len], "200 OK") != null);
}
