"use client";

import React from "react";
import { Shield, Terminal, Cpu, Layers } from "lucide-react";

export default function FeaturesBento() {
  return (
    <section id="architecture" className="py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto border-b border-zinc-900 bg-black">
      {/* Section Header */}
      <div className="max-w-3xl mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded border border-zinc-800 bg-zinc-950 text-zinc-300 text-xs font-mono uppercase tracking-widest mb-4">
          <Layers className="w-3.5 h-3.5" />
          Silicon Subsystems
        </div>
        <h2 className="text-3xl sm:text-5xl font-bold tracking-tight text-white mb-4">
          Core Engine Architecture
        </h2>
        <p className="text-zinc-400 text-base sm:text-lg leading-relaxed">
          Zero heap allocations. 64-byte aligned SIMD memory layouts. McCarthy store-select SMT provers executing directly on native hardware registers.
        </p>
      </div>

      {/* Bento Grid */}
      <div className="grid grid-cols-1 md:grid-cols-12 gap-6">
        {/* Box 1: Real-time Invariant Inspector (Span 8) */}
        <div className="md:col-span-8 rounded border border-zinc-900 bg-zinc-950 p-6 space-y-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-lg font-bold text-white">
                Real-Time State & Invariant Inspector
              </h3>
              <span className="text-[11px] font-mono text-zinc-300 bg-zinc-900 px-2 py-0.5 rounded border border-zinc-800">
                0 Bytes Heap
              </span>
            </div>
            <p className="text-xs sm:text-sm text-zinc-400 mb-4">
              Inspect storage slots, McCarthy select/store taints, and opcode execution times with sub-microsecond precision.
            </p>

            {/* Table */}
            <div className="rounded border border-zinc-800 bg-black p-3 font-mono text-xs text-zinc-400 overflow-x-auto">
              <div className="flex items-center justify-between border-b border-zinc-800 pb-2 mb-2 text-zinc-500 text-[11px]">
                <span>OPCODE · TARGET</span>
                <span>STATE</span>
                <span>LATENCY</span>
                <span>INVARIANT STATUS</span>
              </div>
              <div className="space-y-2">
                <div className="flex items-center justify-between text-zinc-300 p-1 rounded">
                  <span className="text-white font-bold">TSTORE · slot_0x0 (Hook)</span>
                  <span className="px-1.5 py-0.5 rounded bg-zinc-900 text-zinc-300 text-[10px]">TRANSIENT</span>
                  <span>142 ns</span>
                  <span className="text-white font-semibold">VALIDATED</span>
                </div>
                <div className="flex items-center justify-between text-zinc-300 p-1 rounded">
                  <span className="text-white font-bold">SLOAD · reserves[0]</span>
                  <span className="px-1.5 py-0.5 rounded bg-zinc-900 text-zinc-300 text-[10px]">STORAGE</span>
                  <span>87 ns</span>
                  <span className="text-white font-semibold">x * y &gt;= k OK</span>
                </div>
                <div className="flex items-center justify-between text-zinc-300 p-1 rounded bg-zinc-900/40 border border-zinc-800">
                  <span className="text-white font-bold">MSTORE · donate(1 wei)</span>
                  <span className="px-1.5 py-0.5 rounded bg-zinc-900 text-zinc-300 text-[10px]">REVERT</span>
                  <span>310 ns</span>
                  <span className="text-white font-bold">[BREACH MAPPED]</span>
                </div>
              </div>
            </div>
          </div>

          <div className="text-xs font-mono text-zinc-500 pt-2 border-t border-zinc-900 flex items-center justify-between">
            <span>Direct Win32/POSIX system calls</span>
            <span className="text-zinc-400">ICFG SSA IR Engine</span>
          </div>
        </div>

        {/* Box 2: Named Local Invariants (Span 4) */}
        <div className="md:col-span-4 rounded border border-zinc-900 bg-zinc-950 p-6 space-y-4 flex flex-col justify-between">
          <div>
            <div className="w-10 h-10 rounded bg-zinc-900 border border-zinc-800 flex items-center justify-center text-white mb-4">
              <Shield className="w-5 h-5" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2">
              Formal Protocol Invariants
            </h3>
            <p className="text-xs sm:text-sm text-zinc-400 leading-relaxed">
              Define mathematical protocol invariants in simple declarative syntax. Proves pool solvency, oracle safety, and non-reentrancy automatically.
            </p>
          </div>

          <div className="p-3 rounded bg-black border border-zinc-800 font-mono text-[11px] text-zinc-400 space-y-1">
            <div className="text-white font-bold">invariant: k_monotonicity</div>
            <div className="text-zinc-500">assert: pool.x * pool.y &gt;= k_prev</div>
            <div className="text-zinc-500">solver: McCarthy Store-Select SMT</div>
          </div>
        </div>

        {/* Box 3: Automated Foundry PoC Tunnels (Span 4) */}
        <div className="md:col-span-4 rounded border border-zinc-900 bg-zinc-950 p-6 space-y-4 flex flex-col justify-between">
          <div>
            <div className="w-10 h-10 rounded bg-zinc-900 border border-zinc-800 flex items-center justify-center text-white mb-4">
              <Terminal className="w-5 h-5" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2">
              Automated Foundry PoC Synthesis
            </h3>
            <p className="text-xs sm:text-sm text-zinc-400 leading-relaxed">
              When an invariant violation is discovered, Roche compresses the counter-example into a ≤ 4 step minimal trace and emits executable Solidity Foundry tests.
            </p>
          </div>

          <div className="p-2.5 rounded bg-black border border-zinc-800 font-mono text-[11px] text-zinc-400">
            <span className="text-white">$ roche export-poc --forge</span>
            <div className="text-zinc-500 text-[10px] mt-1">↳ Generated test/ExploitPoC.t.sol</div>
          </div>
        </div>

        {/* Box 4: Bare Silicon AVX-512 SIMD (Span 8) */}
        <div className="md:col-span-8 rounded border border-zinc-900 bg-zinc-950 p-6 space-y-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-2">
              <h3 className="text-lg font-bold text-white">
                256-Bit AVX2 & AVX-512 Vectorized Fuzzing Core
              </h3>
              <span className="text-[11px] font-mono text-zinc-300 bg-zinc-900 px-2 py-0.5 rounded border border-zinc-800">
                1.84M Execs/sec
              </span>
            </div>
            <p className="text-xs sm:text-sm text-zinc-400 mb-4">
              Batch executes 8 to 32 parallel EVM contract states simultaneously in CPU vector registers (@Vector(8, f32) and @Vector(32, u8)).
            </p>

            <div className="p-4 rounded border border-zinc-800 bg-black font-mono text-xs flex flex-col sm:flex-row items-center justify-between gap-4">
              <div className="space-y-1">
                <div className="text-zinc-500 text-[11px]">Hardware Cache Line:</div>
                <div className="text-white font-bold">64-Byte Aligned</div>
              </div>
              <div className="space-y-1">
                <div className="text-zinc-500 text-[11px]">Dynamic Heap Memory:</div>
                <div className="text-white font-bold">0 Bytes (Zero malloc/free)</div>
              </div>
              <div className="space-y-1">
                <div className="text-zinc-500 text-[11px]">Rollback Complexity:</div>
                <div className="text-white font-bold">O(1) Ring Buffer Journal</div>
              </div>
            </div>
          </div>

          <div className="text-xs font-mono text-zinc-500 pt-2 border-t border-zinc-900 flex items-center justify-between">
            <span>Eliminates V8 garbage collector pauses</span>
            <span className="text-white font-medium">100% Native Silicon</span>
          </div>
        </div>
      </div>
    </section>
  );
}
