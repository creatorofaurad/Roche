"use client";

import React, { useState } from "react";
import { Terminal, CheckCircle2, XCircle, Zap, Shield, Cpu, Layers } from "lucide-react";

export default function ComparisonSection() {
  const [activeTab, setActiveTab] = useState<"foundry" | "next" | "vite" | "hardhat">("foundry");

  const tabData = {
    foundry: {
      framework: "Foundry / Anvil",
      leftCmd: "forge test --fuzz-runs 100000",
      leftOutput: [
        { text: "[*] Compiling 42 Solidity contracts...", type: "info" },
        { text: "[*] Running 12 test suites with EVM interpreter...", type: "info" },
        { text: "[!] Memory usage: 1.42 GB (Node/Rust heap)", type: "warn" },
        { text: "[!] Invariant test fuzzing: 4,200 exec/sec", type: "warn" },
        { text: "[!] SMT Solver timeout on Euler V2 donate()", type: "error" },
        { text: "[x] Total runtime: 23.84s (High latency)", type: "error" },
      ],
      rightCmd: "roche test --simd --smt --formal",
      rightOutput: [
        { text: "[⚡] Native Bare Silicon JIT initialized (AVX-512/AVX2)", type: "success" },
        { text: "[⚡] 0 Bytes dynamic heap allocation (Strict Invariant)", type: "success" },
        { text: "[✓] SMT McCarthy array theory prover: 12/12 theorems valid", type: "success" },
        { text: "[✓] Invariant fuzzing: 1,840,000 exec/sec (SIMD vectorized)", type: "success" },
        { text: "[★] Roche Limit breach mapped: LiquidityUtils.sol:112", type: "highlight" },
        { text: "[✓] Total runtime: 12.4ms (1920x faster)", type: "highlight" },
      ],
    },
    next: {
      framework: "Next.js 16 (App Router)",
      leftCmd: "next dev --turbopack",
      leftOutput: [
        { text: "▲ Next.js 16.3.5 (Turbopack)", type: "info" },
        { text: "- Local: http://localhost:3000", type: "info" },
        { text: "⚠ RPC WebSocket socket collision on :8545", type: "warn" },
        { text: "⚠ Contract ABI hot-reloading: 840ms delay", type: "warn" },
        { text: "⚠ WebAssembly EVM memory exhaustion warning", type: "error" },
      ],
      rightCmd: "roche next dev",
      rightOutput: [
        { text: "✦ Roche Native Dev Tunnel active (roche-rpc://127.0.0.1:8545)", type: "success" },
        { text: "✦ Direct Win32 / POSIX kernel handles mapped", type: "success" },
        { text: "✦ Instant ABI hot-sync: 0.18ms latency", type: "success" },
        { text: "✦ Real-time invariant telemetry widget injected", type: "highlight" },
      ],
    },
    vite: {
      framework: "Vite + Wagmi",
      leftCmd: "vite",
      leftOutput: [
        { text: "VITE v6.0.0 ready in 420 ms", type: "info" },
        { text: "➜ Local: http://localhost:5173/", type: "info" },
        { text: "⚠ Forked state desynchronization detected", type: "warn" },
        { text: "⚠ Mock wallet signer dropped nonce sequence", type: "error" },
      ],
      rightCmd: "roche vite --sync-state",
      rightOutput: [
        { text: "✦ Zero-Latency local anvil state mirror locked", type: "success" },
        { text: "✦ Deterministic EIP-712 auto-signing engine active", type: "success" },
        { text: "✦ Replay & edit timeline enabled on port 5173", type: "highlight" },
      ],
    },
    hardhat: {
      framework: "Hardhat / Node",
      leftCmd: "npx hardhat test",
      leftOutput: [
        { text: "Compiling 18 Solidity files with solc 0.8.24...", type: "info" },
        { text: "Generating typings for TypeScript...", type: "info" },
        { text: "⚠ V8 garbage collector pause: 140ms", type: "warn" },
        { text: "⚠ Stack too deep error during symbolic simulation", type: "error" },
      ],
      rightCmd: "roche hardhat test",
      rightOutput: [
        { text: "✦ Native U256 stack machine bypasses V8 overhead", type: "success" },
        { text: "✦ McCarthy storage rollback ring buffer: O(1) resets", type: "success" },
        { text: "✦ 100% Green test suite in 18.2ms", type: "highlight" },
      ],
    },
  };

  const current = tabData[activeTab];

  return (
    <section className="py-24 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto border-t border-white/[0.05]">
      {/* Section Header */}
      <div className="text-center max-w-3xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-emerald-500/30 bg-emerald-500/10 text-emerald-400 text-xs font-mono uppercase tracking-widest mb-4">
          <Zap className="w-3 h-3" />
          The Roche Difference
        </div>
        <h2 className="text-3xl sm:text-5xl font-extrabold tracking-tight text-white mb-4">
          Bare Silicon vs. Legacy Overhead
        </h2>
        <p className="text-zinc-400 text-base sm:text-lg">
          Zero garbage collection. 0 Bytes dynamic heap allocation. Watch your invariant tests and local dev servers run at the physical speed of the CPU memory bus.
        </p>

        {/* Framework Selector Tabs */}
        <div className="flex flex-wrap items-center justify-center gap-2 mt-8">
          {(["foundry", "next", "vite", "hardhat"] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-4 py-2 rounded-xl text-xs sm:text-sm font-mono font-medium transition-all ${
                activeTab === tab
                  ? "bg-emerald-500/20 text-emerald-400 border border-emerald-500/40 shadow-[0_0_15px_rgba(34,197,94,0.15)]"
                  : "bg-white/[0.03] text-zinc-400 border border-white/[0.06] hover:bg-white/[0.06] hover:text-white"
              }`}
            >
              {tabData[tab].framework}
            </button>
          ))}
        </div>
      </div>

      {/* Side-by-Side Terminals */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Left: Legacy Terminal */}
        <div className="rounded-2xl border border-red-500/20 bg-zinc-950/80 backdrop-blur-md overflow-hidden flex flex-col">
          <div className="flex items-center justify-between px-4 py-3 border-b border-white/[0.06] bg-black/40">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-red-500/80" />
              <span className="w-2.5 h-2.5 rounded-full bg-amber-500/80" />
              <span className="w-2.5 h-2.5 rounded-full bg-zinc-600" />
              <span className="ml-2 text-xs font-mono text-zinc-400">Without Roche ({current.framework})</span>
            </div>
            <span className="text-[11px] font-mono text-red-400/80 bg-red-500/10 px-2 py-0.5 rounded border border-red-500/20">
              Legacy Toolchain
            </span>
          </div>

          <div className="p-5 font-mono text-xs sm:text-sm flex-1 space-y-2.5 bg-black/60">
            <div className="text-zinc-500 pb-2 border-b border-white/[0.04] flex items-center gap-2">
              <span className="text-red-400">$</span> {current.leftCmd}
            </div>
            {current.leftOutput.map((line, i) => (
              <div
                key={i}
                className={`leading-relaxed ${
                  line.type === "error"
                    ? "text-red-400 font-semibold"
                    : line.type === "warn"
                    ? "text-amber-400/90"
                    : "text-zinc-400"
                }`}
              >
                {line.text}
              </div>
            ))}
          </div>

          <div className="px-5 py-3 border-t border-white/[0.06] bg-red-950/20 flex items-center justify-between text-xs font-mono text-red-400">
            <span className="flex items-center gap-1.5">
              <XCircle className="w-4 h-4" /> Heavy CPU Overhead & GC Pauses
            </span>
            <span className="text-zinc-500">Node/V8/Wasm</span>
          </div>
        </div>

        {/* Right: Roche Terminal */}
        <div className="rounded-2xl border border-emerald-500/30 bg-zinc-950/80 backdrop-blur-md overflow-hidden flex flex-col shadow-[0_0_30px_rgba(34,197,94,0.1)]">
          <div className="flex items-center justify-between px-4 py-3 border-b border-emerald-500/20 bg-emerald-950/30">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-500" />
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-500/60" />
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-500/30" />
              <span className="ml-2 text-xs font-mono text-emerald-300 font-semibold">With Roche (Bare Silicon)</span>
            </div>
            <span className="text-[11px] font-mono text-emerald-400 bg-emerald-500/20 px-2 py-0.5 rounded border border-emerald-500/40">
              AVX-512 / Zero-Heap
            </span>
          </div>

          <div className="p-5 font-mono text-xs sm:text-sm flex-1 space-y-2.5 bg-black/60">
            <div className="text-zinc-400 pb-2 border-b border-emerald-500/10 flex items-center gap-2">
              <span className="text-emerald-400">$</span> {current.rightCmd}
            </div>
            {current.rightOutput.map((line, i) => (
              <div
                key={i}
                className={`leading-relaxed ${
                  line.type === "highlight"
                    ? "text-emerald-300 font-bold bg-emerald-500/10 px-2 py-1 rounded border border-emerald-500/20"
                    : line.type === "success"
                    ? "text-emerald-400"
                    : "text-zinc-300"
                }`}
              >
                {line.text}
              </div>
            ))}
          </div>

          <div className="px-5 py-3 border-t border-emerald-500/20 bg-emerald-950/40 flex items-center justify-between text-xs font-mono text-emerald-300">
            <span className="flex items-center gap-1.5 font-semibold">
              <CheckCircle2 className="w-4 h-4 text-emerald-400" /> Sub-Millisecond Formal Invariant Proofs
            </span>
            <span className="text-emerald-400/80 font-bold">1920x Speedup</span>
          </div>
        </div>
      </div>
    </section>
  );
}
