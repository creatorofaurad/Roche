//! audit_coinbase_tier0_live.zig: Live Target Invariant Evaluator for Coinbase Tier 0 Contracts
//! Zero Dynamic Heap Allocation | Zig 0.16.0 | Direct Win32 File IO

const std = @import("std");
const types = @import("types.zig");
const cfg_mod = @import("cfg.zig");
const vm_mod = @import("vm.zig");
const cb = @import("detectors_coinbase_tier0.zig");
const cli_mod = @import("cli.zig");

var global_vm: vm_mod.VM = undefined;

pub fn main() !void {
    global_vm = vm_mod.VM.init();
    std.debug.print(
        \\=============================================================================
        \\   ROCHE v2: COINBASE TIER 0 ($5M BOUNTY SCOPE) LIVE INVARIANT SCANNER
        \\=============================================================================
        \\
    , .{});

    var handler = cli_mod.CliHandler.init();

    // 1. Target: cbETH Implementation (0x31724ca0c982a31fbb5c57f4217ab585271fc9a5)
    std.debug.print("\n[*] SCANNING TARGET 1/3: cbETH Implementation (Ethereum Mainnet)...\n", .{});
    if (handler.readFile("corpus/cbeth_impl.hex")) {
        const code = handler.bytecode_buffer[0..handler.bytecode_len];
        var cfg = cfg_mod.ControlFlowGraph.build(code);
        
        // Execute dynamic state scan
        _ = global_vm.execute(code);

        std.debug.print("  [+] CFG Basic Blocks: {d}\n", .{cfg.block_count});
        std.debug.print("  [+] Bytecode Length:  {d} bytes\n", .{code.len});

        const res_cb01 = cb.detectCB01(&global_vm, &cfg);
        const res_cb05 = cb.detectCB05(&global_vm, &cfg);

        std.debug.print("  [+] CB-01 (ExchangeRate Discrete Jump) : {s} (Severity: {d})\n", .{ if (res_cb01.found) "VIOLATION FOUND" else "CLEAN / BOUNDED", res_cb01.severity });
        std.debug.print("  [+] CB-05 (Oracle Heartbeat Staleness) : {s} (Severity: {d})\n", .{ if (res_cb05.found) "VIOLATION FOUND" else "CLEAN / BOUNDED", res_cb05.severity });
    } else {
        std.debug.print("  [!] Could not load corpus/cbeth_impl.hex\n", .{});
    }

    // 2. Target: Base L1CrossDomainMessenger (0x866E82a600A1414e583f7F13623F1aC5d58b0Afa)
    std.debug.print("\n[*] SCANNING TARGET 2/3: Base L1CrossDomainMessenger (Ethereum Mainnet)...\n", .{});
    if (handler.readFile("corpus/base_l1_messenger.hex")) {
        const code = handler.bytecode_buffer[0..handler.bytecode_len];
        var cfg = cfg_mod.ControlFlowGraph.build(code);
        _ = global_vm.execute(code);

        std.debug.print("  [+] CFG Basic Blocks: {d}\n", .{cfg.block_count});
        std.debug.print("  [+] Bytecode Length:  {d} bytes\n", .{code.len});

        const res_cb02 = cb.detectCB02(&global_vm, &cfg);
        const res_cb04 = cb.detectCB04(&global_vm, &cfg);

        std.debug.print("  [+] CB-02 (Cross-Chain Replay Hash)   : {s} (Severity: {d})\n", .{ if (res_cb02.found) "VIOLATION FOUND" else "CLEAN / BOUNDED", res_cb02.severity });
        std.debug.print("  [+] CB-04 (Sequencer Freshness Grace) : {s} (Severity: {d})\n", .{ if (res_cb04.found) "VIOLATION FOUND" else "CLEAN / BOUNDED", res_cb04.severity });
    }

    // 3. Target: cbBTC Token & Wrapper (0xcbB7C0000aB88B473b1f5aFd9ef808440eed33Bf)
    std.debug.print("\n[*] SCANNING TARGET 3/3: cbBTC Token & Minter (Ethereum Mainnet)...\n", .{});
    if (handler.readFile("corpus/cbbtc_eth.hex")) {
        const code = handler.bytecode_buffer[0..handler.bytecode_len];
        var cfg = cfg_mod.ControlFlowGraph.build(code);
        _ = global_vm.execute(code);

        std.debug.print("  [+] CFG Basic Blocks: {d}\n", .{cfg.block_count});
        std.debug.print("  [+] Bytecode Length:  {d} bytes\n", .{code.len});

        const res_cb03 = cb.detectCB03(&global_vm, &cfg);
        const res_cb02 = cb.detectCB02(&global_vm, &cfg);

        std.debug.print("  [+] CB-03 (Custodial Share Inflation) : {s} (Severity: {d})\n", .{ if (res_cb03.found) "VIOLATION FOUND" else "CLEAN / BOUNDED", res_cb03.severity });
        std.debug.print("  [+] CB-02 (Cross-Chain Replay Hash)   : {s} (Severity: {d})\n", .{ if (res_cb02.found) "VIOLATION FOUND" else "CLEAN / BOUNDED", res_cb02.severity });
    }
}
