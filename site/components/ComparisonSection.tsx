"use client";

import React, { useState } from "react";
import { CheckCircle2, XCircle, Zap } from "lucide-react";

export default function ComparisonSection() {
  const [activeTab, setActiveTab] = useState<"foundry" | "smt" | "simd" | "hardhat">("foundry");

  const tabData = {
    foundry: {
      framework: "Foundry / Forge Fuzzing",
      leftCmd: "forge test --fuzz-runs 100000",
      leftOutput: [
        { text: "[*] Compiling 42 Solidity contracts with solc...", type: "info" },
        { text: "[*] Initializing EVM interpreter (Rust heap)...", type: "info" },
        { text: "[!] Memory consumption: 1.42 GB (Dynamic allocations)", type: "warn" },
        { text: "[!] Property fuzzing throughput: 4,200 exec/sec", type: "warn" },
        { text: "[!] Missed edge case in LiquidityUtils.sol:112", type: "error" },
        { text: "[x] Total wall-clock time: 23.84s", type: "error" },
      ],
      rightCmd: "roche test --simd --smt --formal",
      rightOutput: [
        { text: "[+] Initializing Bare Silicon JIT (AVX-512 / AVX2)", type: "success" },
        { text: "[+] 0 Bytes dynamic heap allocations (Strict Invariant)", type: "success" },
        { text: "[✓] McCarthy SMT Array Theory Prover: 12/12 theorems verified", type: "success" },
        { text: "[✓] Vectorized invariant throughput: 1,840,000 exec/sec", type: "success" },
        { text: "[★] Roche Limit breach mapped: LiquidityUtils.sol:112", type: "highlight" },
        { text: "[✓] Total wall-clock time: 12.4ms (1920x faster)", type: "highlight" },
      ],
    },
    smt: {
      framework: "SMT Formal Solvency Prover",
      leftCmd: "z3 -smt2 input.smt2 (External process)",
      leftOutput: [
        { text: "Spawning external Z3 / CVC5 solver subprocess...", type: "info" },
        { text: "Serializing 50,000 AST nodes over standard pipe...", type: "info" },
        { text: "⚠ High context-switch latency: 480ms per query", type: "warn" },
        { text: "⚠ Timeout on non-linear storage multiplication", type: "error" },
      ],
      rightCmd: "roche verify --solver=mccarthy-native",
      rightOutput: [
        { text: "✦ Embedded McCarthy store-select solver on stack registers", type: "success" },
        { text: "✦ Direct Win32/POSIX kernel handles (0 IPC overhead)", type: "success" },
        { text: "✦ Solves AMM k_monotonicity in 0.8µs", type: "success" },
        { text: "✦ 100% Deterministic formal convergence", type: "highlight" },
      ],
    },
    simd: {
      framework: "256-Bit AVX2 Vectorization",
      leftCmd: "sequential-evm --threads=8",
      leftOutput: [
        { text: "Sequential EVM opcode loop across 8 OS threads...", type: "info" },
        { text: "⚠ OS thread synchronization lock contention", type: "warn" },
        { text: "⚠ Cache line invalidations on shared state", type: "error" },
        { text: "Throughput ceiling: 65,000 exec/sec", type: "warn" },
      ],
      rightCmd: "roche fuzz --vectorize-avx2",
      rightOutput: [
        { text: "✦ 8 EVM state transitions per AVX2 @Vector(8, f32) register", type: "success" },
        { text: "✦ 64-byte hardware cache line alignment", type: "success" },
        { text: "✦ 0 Locks, 0 Mutexes, Lock-free ring buffer", type: "success" },
        { text: "✦ Throughput: 1,840,000 exec/sec", type: "highlight" },
      ],
    },
    hardhat: {
      framework: "Hardhat / Node.js Engine",
      leftCmd: "npx hardhat test",
      leftOutput: [
        { text: "Compiling 18 Solidity files with solc 0.8.24...", type: "info" },
        { text: "Generating TypeScript bindings...", type: "info" },
        { text: "⚠ V8 JavaScript garbage collector pause: 140ms", type: "warn" },
        { text: "⚠ Out of memory crash on 500,000 state permutations", type: "error" },
      ],
      rightCmd: "roche test --native-u256",
      rightOutput: [
        { text: "✦ Pure Zig native U256 stack machine", type: "success" },
        { text: "✦ O(1) McCarthy rollback journal ring resets", type: "success" },
        { text: "✦ 100% Green test suite in 18.2ms", type: "highlight" },
      ],
    },
  };

  const current = tabData[activeTab];

  return (
    <section id="benchmarks" className="py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto border-b border-zinc-900 bg-black">
      {/* Section Header */}
      <div className="max-w-3xl mb-12">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded border border-zinc-800 bg-zinc-950 text-zinc-300 text-xs font-mono uppercase tracking-widest mb-4">
          <Zap className="w-3.5 h-3.5" />
          Hardware & Invariant Benchmarks
        </div>
        <h2 className="text-3xl sm:text-5xl font-bold tracking-tight text-white mb-4">
          Bare Silicon vs. Legacy Overhead
        </h2>
        <p className="text-zinc-400 text-base sm:text-lg leading-relaxed">
          Zero garbage collection. 0 Bytes dynamic heap allocation. Watch your invariant tests and formal proofs execute at the physical memory bus clock speed.
        </p>

        {/* Framework Selector Tabs */}
        <div className="flex flex-wrap items-center gap-2 mt-8">
          {(["foundry", "smt", "simd", "hardhat"] as const).map((tab) => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-3.5 py-1.5 rounded text-xs font-mono transition-all ${
                activeTab === tab
                  ? "bg-zinc-900 text-white border border-zinc-700 font-semibold"
                  : "bg-black text-zinc-500 border border-zinc-900 hover:border-zinc-800 hover:text-zinc-300"
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
        <div className="rounded border border-zinc-800 bg-zinc-950 overflow-hidden flex flex-col">
          <div className="flex items-center justify-between px-4 py-2.5 border-b border-zinc-900 bg-black">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-zinc-800" />
              <span className="w-2.5 h-2.5 rounded-full bg-zinc-800" />
              <span className="w-2.5 h-2.5 rounded-full bg-zinc-800" />
              <span className="ml-2 text-xs font-mono text-zinc-500">Legacy Toolchain ({current.framework})</span>
            </div>
            <span className="text-[10px] font-mono text-zinc-400 bg-zinc-900 px-2 py-0.5 rounded border border-zinc-800">
              V8 / Rust Heap
            </span>
          </div>

          <div className="p-4 font-mono text-xs flex-1 space-y-2 bg-black text-zinc-400">
            <div className="text-zinc-500 pb-2 border-b border-zinc-900 flex items-center gap-2">
              <span className="text-zinc-400">$</span> {current.leftCmd}
            </div>
            {current.leftOutput.map((line, i) => (
              <div
                key={i}
                className={`leading-relaxed ${
                  line.type === "error"
                    ? "text-zinc-300 font-medium"
                    : line.type === "warn"
                    ? "text-zinc-400"
                    : "text-zinc-500"
                }`}
              >
                {line.text}
              </div>
            ))}
          </div>

          <div className="px-4 py-2.5 border-t border-zinc-900 bg-zinc-950 flex items-center justify-between text-xs font-mono text-zinc-400">
            <span className="flex items-center gap-1.5">
              <XCircle className="w-3.5 h-3.5" /> High CPU Latency & GC Stalls
            </span>
            <span className="text-zinc-600">Interpreted Overhead</span>
          </div>
        </div>

        {/* Right: Charles's Roche Terminal */}
        <div className="rounded border border-zinc-800 bg-zinc-950 overflow-hidden flex flex-col shadow-2xl">
          <div className="flex items-center justify-between px-4 py-2.5 border-b border-zinc-900 bg-black">
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-white" />
              <span className="w-2.5 h-2.5 rounded-full bg-zinc-800" />
              <span className="w-2.5 h-2.5 rounded-full bg-zinc-800" />
              <span className="ml-2 text-xs font-mono text-white font-bold">Charles / Roche (Bare Silicon)</span>
            </div>
            <span className="text-[10px] font-mono text-white bg-zinc-900 px-2 py-0.5 rounded border border-zinc-800">
              AVX2 / Zero-Heap
            </span>
          </div>

          <div className="p-4 font-mono text-xs flex-1 space-y-2 bg-black text-zinc-300">
            <div className="text-zinc-400 pb-2 border-b border-zinc-900 flex items-center gap-2">
              <span className="text-white">$</span> {current.rightCmd}
            </div>
            {current.rightOutput.map((line, i) => (
              <div
                key={i}
                className={`leading-relaxed ${
                  line.type === "highlight"
                    ? "text-white font-bold bg-zinc-900 px-2 py-0.5 rounded border border-zinc-800"
                    : line.type === "success"
                    ? "text-zinc-200"
                    : "text-zinc-400"
                }`}
              >
                {line.text}
              </div>
            ))}
          </div>

          <div className="px-4 py-2.5 border-t border-zinc-900 bg-zinc-950 flex items-center justify-between text-xs font-mono text-white font-bold">
            <span className="flex items-center gap-1.5">
              <CheckCircle2 className="w-3.5 h-3.5" /> Sub-Millisecond Formal Proofs
            </span>
            <span className="text-zinc-400 font-mono">1920x Speedup</span>
          </div>
        </div>
      </div>
    </section>
  );
}
