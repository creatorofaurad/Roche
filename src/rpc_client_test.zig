//! rpc_client_test.zig: Unit tests for Roche Win32 JSON-RPC Client

const std = @import("std");
const rpc = @import("rpc_client.zig");

test "rpc_client json parsing hex result" {
    const json_sample = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"jsonrpc\":\"2.0\",\"id\":1,\"result\":\"0x608060405234\"}";
    var out_buf: [256]u8 = undefined;

    const len = rpc.RpcClient.parseJsonResult(json_sample, &out_buf);
    try std.testing.expect(len != null);
    try std.testing.expectEqual(@as(usize, 6), len.?);
    try std.testing.expectEqual(@as(u8, 0x60), out_buf[0]);
    try std.testing.expectEqual(@as(u8, 0x80), out_buf[1]);
    try std.testing.expectEqual(@as(u8, 0x52), out_buf[4]);
    try std.testing.expectEqual(@as(u8, 0x34), out_buf[5]);
}

test "rpc_client mock fetch fork state" {
    var client = rpc.RpcClient.init(8545);
    const state = client.mock_fetch_state("0x000000000004444c5dc75cB358380D2e3dE08A90", 20850000);

    try std.testing.expect(state.bytecode_len > 0);
    try std.testing.expectEqual(@as(u64, 20850000), state.block_number);
    try std.testing.expectEqual(@as(u8, 0x60), state.bytecode_buffer[0]);
}
