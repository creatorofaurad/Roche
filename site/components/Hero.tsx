"use client";

import React, { useState } from "react";
import { Terminal, Copy, Check } from "lucide-react";

export default function Hero() {
  const [copied, setCopied] = useState(false);
  const cloneCmd = "git clone https://github.com/creatorofaurad/roche";

  const handleCopy = () => {
    navigator.clipboard.writeText(cloneCmd);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <section className="relative bg-black pt-16 pb-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto border-b border-zinc-900">
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
        {/* Left Column: Thesis & Authority */}
        <div className="lg:col-span-7 space-y-6">
          {/* Grant & Author Tag */}
          <div className="inline-flex items-center gap-2.5 px-3 py-1 rounded border border-zinc-800 bg-zinc-950 text-zinc-300 text-xs font-mono">
            <span className="w-1.5 h-1.5 rounded-full bg-white animate-pulse" />
            <span className="text-white font-semibold">ECOSYSTEM GRANT DOSSIER</span>
            <span className="text-zinc-600">|</span>
            <span className="text-zinc-400">RESEARCH BY CHARLES (AGE 15)</span>
          </div>

          <h1 className="text-4xl sm:text-6xl font-bold tracking-tight text-white leading-[1.08]">
            Proving the Roche Limit of DeFi.
          </h1>

          <p className="text-base sm:text-lg text-zinc-400 max-w-2xl leading-relaxed">
            I built <strong className="text-white font-mono">Roche</strong>—a zero-allocation EVM invariant verification engine in pure Zig 0.16. By rejecting interpreted runtimes and garbage collection, Roche evaluates <strong className="text-white">1.84 million state transitions/second</strong> and solves SMT storage invariants in <strong className="text-white">&lt; 2μs</strong>.
          </p>

          {/* Key Metrics Grid */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-2">
            <div className="p-3 rounded border border-zinc-900 bg-zinc-950">
              <div className="text-xl sm:text-2xl font-mono font-bold text-white">0 Bytes</div>
              <div className="text-[11px] font-mono text-zinc-500">Heap Allocations</div>
            </div>
            <div className="p-3 rounded border border-zinc-900 bg-zinc-950">
              <div className="text-xl sm:text-2xl font-mono font-bold text-white">1.84M</div>
              <div className="text-[11px] font-mono text-zinc-500">Execs / Sec (SIMD)</div>
            </div>
            <div className="p-3 rounded border border-zinc-900 bg-zinc-950">
              <div className="text-xl sm:text-2xl font-mono font-bold text-white">&lt; 2.0µs</div>
              <div className="text-[11px] font-mono text-zinc-500">SMT Invariant Proofs</div>
            </div>
            <div className="p-3 rounded border border-zinc-900 bg-zinc-950">
              <div className="text-xl sm:text-2xl font-mono font-bold text-white">29 / 29</div>
              <div className="text-[11px] font-mono text-zinc-500">Formal Suites Green</div>
            </div>
          </div>

          {/* Quick Install Bar (Clean, no scrollbar, no link underneath) */}
          <div className="pt-2">
            <div className="flex items-center justify-between rounded bg-zinc-950 border border-zinc-800 px-4 py-3 max-w-lg font-mono text-xs sm:text-sm">
              <div className="flex items-center gap-3 text-zinc-300 overflow-hidden">
                <span className="text-white font-bold">$</span>
                <span className="select-all truncate">{cloneCmd}</span>
              </div>
              <button
                onClick={handleCopy}
                className="ml-3 shrink-0 p-1.5 rounded hover:bg-zinc-800 text-zinc-400 hover:text-white transition-colors"
                title="Copy build command"
                aria-label="Copy command"
              >
                {copied ? <Check className="w-4 h-4 text-white" /> : <Copy className="w-4 h-4" />}
              </button>
            </div>
          </div>
        </div>

        {/* Right Column: Live Invariant Trace Terminal (Monochrome) */}
        <div className="lg:col-span-5">
          <div className="rounded-xl border border-zinc-800 bg-zinc-950 overflow-hidden shadow-2xl">
            {/* Terminal Header */}
            <div className="flex items-center justify-between px-4 py-2.5 border-b border-zinc-900 bg-black">
              <div className="flex items-center gap-2">
                <span className="w-2.5 h-2.5 rounded-full bg-zinc-800" />
                <span className="w-2.5 h-2.5 rounded-full bg-zinc-800" />
                <span className="w-2.5 h-2.5 rounded-full bg-zinc-800" />
                <span className="ml-2 text-xs font-mono text-zinc-400">roche-prover --formal</span>
              </div>
              <span className="text-[10px] font-mono text-white px-2 py-0.5 rounded bg-zinc-900 border border-zinc-800">
                BARE SILICON JIT
              </span>
            </div>

            {/* Terminal Body */}
            <div className="p-4 font-mono text-xs space-y-2.5 bg-black text-zinc-300 leading-relaxed">
              <div className="text-zinc-500 pb-1 border-b border-zinc-900">
                [+] Initializing SMT Array Solver (McCarthy Store-Select)...
              </div>
              
              <div className="flex items-start justify-between text-zinc-200">
                <span>• target: Euler V2 (LiquidityUtils.sol:112)</span>
                <span className="text-white font-bold bg-zinc-900 px-1.5 py-0.5 rounded border border-zinc-800">[BREACH MAPPED]</span>
              </div>
              <div className="text-[11px] text-zinc-500 pl-3">
                ↳ Invariant: Bid/Ask pricing divergence &gt; mid-point threshold.
              </div>

              <div className="flex items-start justify-between text-zinc-200">
                <span>• target: Uniswap v4 (TransientStorage.sol)</span>
                <span className="text-zinc-300 font-bold bg-zinc-900 px-1.5 py-0.5 rounded border border-zinc-800">[SOLVED: 0.8µs]</span>
              </div>
              <div className="text-[11px] text-zinc-500 pl-3">
                ↳ Invariant: TSTORE isolation across reentrant callframes.
              </div>

              <div className="flex items-start justify-between text-zinc-200">
                <span>• target: Ethena (sUSDe ERC-4626 Inflation)</span>
                <span className="text-zinc-300 font-bold bg-zinc-900 px-1.5 py-0.5 rounded border border-zinc-800">[PROVED SAFE]</span>
              </div>
              <div className="text-[11px] text-zinc-500 pl-3">
                ↳ Invariant: Virtual offset prevents 1st depositor share drain.
              </div>

              <div className="pt-2 border-t border-zinc-900 text-white flex items-center justify-between font-bold">
                <span>29/29 Test Suites Passing (100%)</span>
                <span className="text-zinc-500 font-normal">Exec time: 14.8ms</span>
              </div>
            </div>

            {/* Terminal Footer */}
            <div className="px-4 py-2 bg-zinc-950 border-t border-zinc-900 flex items-center justify-between text-[11px] font-mono text-zinc-500">
              <span>Memory Ceiling: 10.0 GB (0 B Heap)</span>
              <span className="text-zinc-400 font-bold">Charles / Roche v0.16</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
