//! ingestion_tier1_anvil.zig: High-Throughput Anvil Local Fork State Ingestion Engine
//! Written in Pure Zig 0.16.0 with 0 Dynamic Heap Allocations.

const std = @import("std");
const rpc = @import("rpc_client.zig");
const types = @import("types.zig");

pub const AnvilForkClient = struct {
    client: rpc.RpcClient,
    fork_block: u64,
    state: rpc.ForkState,

    pub fn init(ip_addr: u32, port: u16, fork_block: u64, target_addr: [20]u8) AnvilForkClient {
        var client = rpc.RpcClient.init(port);
        client.endpoint_ip = ip_addr;
        return .{
            .client = client,
            .fork_block = fork_block,
            .state = rpc.ForkState.init(target_addr, fork_block),
        };
    }

    /// Fetch bytecode via eth_getCode with 0 heap allocations
    pub fn fetchCode(self: *AnvilForkClient) ![]const u8 {
        var req_buf: [512]u8 = undefined;
        var addr_hex: [42]u8 = undefined;
        _ = std.fmt.bufPrint(&addr_hex, "0x{x:0>40}", .{std.fmt.fmtSliceHexLower(&self.state.address)}) catch return error.FormatError;

        const req_len = (std.fmt.bufPrint(&req_buf,
            \\{{"jsonrpc":"2.0","method":"eth_getCode","params":["{s}","latest"],"id":1}}
        , .{addr_hex}) catch return error.FormatError).len;

        const resp = try self.client.sendRpcRequest(req_buf[0..req_len]);
        if (self.client.parseBytecodeResponse(resp, &self.state)) {
            return self.state.bytecode_buffer[0..self.state.bytecode_len];
        }
        return error.InvalidBytecodeResponse;
    }

    /// Fetch single storage slot via eth_getStorageAt
    pub fn fetchStorageSlot(self: *AnvilForkClient, slot: types.U256) !types.U256 {
        var req_buf: [512]u8 = undefined;
        var addr_hex: [42]u8 = undefined;
        _ = std.fmt.bufPrint(&addr_hex, "0x{x:0>40}", .{std.fmt.fmtSliceHexLower(&self.state.address)}) catch return error.FormatError;

        var slot_bytes: [32]u8 = undefined;
        slot.toBytesBig(&slot_bytes);

        const req_len = (std.fmt.bufPrint(&req_buf,
            \\{{"jsonrpc":"2.0","method":"eth_getStorageAt","params":["{s}","0x{x:0>64}","latest"],"id":2}}
        , .{ addr_hex, std.fmt.fmtSliceHexLower(&slot_bytes) }) catch return error.FormatError).len;

        const resp = try self.client.sendRpcRequest(req_buf[0..req_len]);
        var out_val = types.U256.zero();
        if (self.client.parseStorageResponse(resp, &out_val)) {
            return out_val;
        }
        return error.InvalidStorageResponse;
    }
};

test "Anvil Fork Client: Ingestion Struct & State Setup" {
    const dummy_addr = [_]u8{0x11} ** 20;
    const fork = AnvilForkClient.init(0x0100007F, 8545, 19500000, dummy_addr);
    try std.testing.expectEqual(@as(u64, 19500000), fork.fork_block);
    try std.testing.expectEqual(dummy_addr, fork.state.address);
}
