"use client";

import React from "react";
import { Cpu, Terminal, Shield, Award } from "lucide-react";

export default function FounderSection() {
  return (
    <section id="architect" className="py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto border-b border-zinc-900 bg-black">
      {/* Section Header */}
      <div className="max-w-3xl mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded border border-zinc-800 bg-zinc-950 text-zinc-300 text-xs font-mono uppercase tracking-widest mb-4">
          <Terminal className="w-3.5 h-3.5" />
          The Mind Behind Roche
        </div>
        <h2 className="text-3xl sm:text-5xl font-bold tracking-tight text-white mb-4">
          Engineered by Charles.
        </h2>
        <p className="text-zinc-400 text-base sm:text-lg leading-relaxed">
          I am 15 years old. I built Roche from scratch because I was tired of watching billion-dollar protocols get exploited while developers rely on slow, interpreted tooling that treats memory safety as an afterthought.
        </p>
      </div>

      {/* 3 Philosophy Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Card 1 */}
        <div className="p-6 rounded-xl border border-zinc-900 bg-zinc-950/60 flex flex-col justify-between">
          <div>
            <div className="w-10 h-10 rounded bg-zinc-900 border border-zinc-800 flex items-center justify-center text-white mb-6">
              <Cpu className="w-5 h-5" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2">
              Bare Silicon & Zero Allocations
            </h3>
            <p className="text-sm text-zinc-400 leading-relaxed mb-4">
              Modern smart contract dev tools run on Node.js/V8 or interpreted Rust runtimes that burn CPU cycles managing dynamic heap garbage. Roche uses <strong className="text-white">0 Bytes of dynamic heap allocation</strong>—running directly on CPU registers, 64-byte aligned cache lines, and 256-bit AVX2 SIMD vectors.
            </p>
          </div>
          <div className="pt-4 border-t border-zinc-900 text-xs font-mono text-zinc-500">
            Zig 0.16.0 • AVX-512 • Direct Win32/POSIX handles
          </div>
        </div>

        {/* Card 2 */}
        <div className="p-6 rounded-xl border border-zinc-900 bg-zinc-950/60 flex flex-col justify-between">
          <div>
            <div className="w-10 h-10 rounded bg-zinc-900 border border-zinc-800 flex items-center justify-center text-white mb-6">
              <Shield className="w-5 h-5" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2">
              Formal Solvency over Fuzzing
            </h3>
            <p className="text-sm text-zinc-400 leading-relaxed mb-4">
              Statistical fuzzing only tests the states it accidentally encounters. Roche lowers EVM bytecode into an Inter-procedural SSA Control Flow Graph (ICFG) and proves global protocol solvency invariants using McCarthy store-select SMT solvers in &lt; 2μs.
            </p>
          </div>
          <div className="pt-4 border-t border-zinc-900 text-xs font-mono text-zinc-500">
            SMT Array Theory • SSA Taint Analysis • O(1) Rollbacks
          </div>
        </div>

        {/* Card 3 */}
        <div className="p-6 rounded-xl border border-zinc-900 bg-zinc-950/60 flex flex-col justify-between">
          <div>
            <div className="w-10 h-10 rounded bg-zinc-900 border border-zinc-800 flex items-center justify-center text-white mb-6">
              <Award className="w-5 h-5" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2">
              Public-Good Ecosystem Infrastructure
            </h3>
            <p className="text-sm text-zinc-400 leading-relaxed mb-4">
              Roche is not another gated SaaS tool with subscription paywalls. It is engineered as foundational, open-source security infrastructure for the entire Ethereum, Base, Uniswap, and Arbitrum ecosystems to eliminate multi-million dollar zero-day drain vectors.
            </p>
          </div>
          <div className="pt-4 border-t border-zinc-900 text-xs font-mono text-zinc-500">
            Open Source • 100% Free Core • Grant-Funded
          </div>
        </div>
      </div>
    </section>
  );
}
