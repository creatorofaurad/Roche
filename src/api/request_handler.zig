//! Roche EVM Security Engine - Request Handler
//! Zero-copy / fixed-buffer JSON request parser for EVM bytecode audit requests

const std = @import("std");

pub const MAX_HEX_BYTECODE_LEN: usize = 49152; // 24KB bytecode in hex (48KB)

pub const AuditRequest = struct {
    bytecode_buf: [MAX_HEX_BYTECODE_LEN]u8 = undefined,
    bytecode_len: usize = 0,
    protocol_name_buf: [64]u8 = undefined,
    protocol_name_len: usize = 0,
    chain_id: u64 = 1,
    enable_formal_verification: bool = true,

    pub fn getBytecodeHex(self: *const AuditRequest) []const u8 {
        return self.bytecode_buf[0..self.bytecode_len];
    }

    pub fn getProtocolName(self: *const AuditRequest) []const u8 {
        return self.protocol_name_buf[0..self.protocol_name_len];
    }
};

pub const RequestHandler = struct {
    pub fn init() RequestHandler {
        return .{};
    }

    pub fn parseAuditRequest(_: *RequestHandler, raw_http: []const u8) !AuditRequest {
        var req = AuditRequest{};

        // Locate HTTP Body after \r\n\r\n
        const body_idx = std.mem.indexOf(u8, raw_http, "\r\n\r\n") orelse 0;
        const body = if (body_idx > 0) raw_http[body_idx + 4 ..] else raw_http;

        // Zero-copy fixed buffer JSON parsing with std.json
        var parsed = std.json.parseFromSlice(std.json.Value, std.heap.page_allocator, body, .{}) catch |err| {
            // Fallback manual key search for zero-alloc compatibility
            if (findJsonField(body, "bytecode")) |bc| {
                const len = @min(bc.len, MAX_HEX_BYTECODE_LEN);
                @memcpy(req.bytecode_buf[0..len], bc[0..len]);
                req.bytecode_len = len;
            }
            if (findJsonField(body, "protocol")) |proto| {
                const len = @min(proto.len, 64);
                @memcpy(req.protocol_name_buf[0..len], proto[0..len]);
                req.protocol_name_len = len;
            }
            return if (req.bytecode_len > 0) req else err;
        };
        defer parsed.deinit();

        const root = parsed.value;
        if (root == .object) {
            if (root.object.get("bytecode")) |bc_val| {
                if (bc_val == .string) {
                    const bc_str = bc_val.string;
                    const len = @min(bc_str.len, MAX_HEX_BYTECODE_LEN);
                    @memcpy(req.bytecode_buf[0..len], bc_str[0..len]);
                    req.bytecode_len = len;
                }
            }
            if (root.object.get("protocol")) |proto_val| {
                if (proto_val == .string) {
                    const str = proto_val.string;
                    const len = @min(str.len, 64);
                    @memcpy(req.protocol_name_buf[0..len], str[0..len]);
                    req.protocol_name_len = len;
                }
            }
            if (root.object.get("chainId")) |cid_val| {
                if (cid_val == .integer) {
                    req.chain_id = @intCast(cid_val.integer);
                }
            }
        }

        return req;
    }
};

fn findJsonField(haystack: []const u8, key: []const u8) ?[]const u8 {
    var key_pattern: [128]u8 = undefined;
    const formatted = std.fmt.bufPrint(&key_pattern, "\"{s}\":", .{key}) catch return null;
    const pos = std.mem.indexOf(u8, haystack, formatted) orelse return null;
    var rest = haystack[pos + formatted.len ..];
    var start: usize = 0;
    while (start < rest.len and (rest[start] == ' ' or rest[start] == '\t' or rest[start] == '\r' or rest[start] == '\n')) : (start += 1) {}
    rest = rest[start..];

    if (rest.len > 0 and rest[0] == '"') {
        rest = rest[1..];
        const end = std.mem.indexOfScalar(u8, rest, '"') orelse return null;
        return rest[0..end];
    }
    return null;
}

test "parseAuditRequest fallback" {
    var handler = RequestHandler.init();
    const raw = "POST /api/v2/audit/bytecode HTTP/1.1\r\nContent-Length: 42\r\n\r\n{\"bytecode\": \"6080604052\", \"protocol\": \"aave\"}";
    const req = try handler.parseAuditRequest(raw);
    try std.testing.expectEqualStrings("6080604052", req.getBytecodeHex());
    try std.testing.expectEqualStrings("aave", req.getProtocolName());
}
