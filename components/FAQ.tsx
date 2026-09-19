"use client";

import React, { useState } from "react";
import { ChevronDown, HelpCircle } from "lucide-react";

export default function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(0);

  const faqs = [
    {
      q: "Who is Charles and why did he build Roche?",
      a: "Charles is a 15-year-old systems and complexity theorist. He built Roche from bare silicon in pure Zig 0.16 to solve the fundamental performance and mathematical limits of modern EVM security tooling. Rather than wrapping slow interpreted runtimes (Node.js/V8 or dynamic Rust heaps), Charles engineered Roche with zero heap allocations, 256-bit AVX2 SIMD vectorization, and embedded McCarthy SMT array theory solvers.",
    },
    {
      q: "What is the 'Roche Limit' of a smart contract?",
      a: "In celestial mechanics, the Roche Limit is the minimal orbital distance at which a celestial body, held together only by its own gravitational cohesion, disintegrates due to the tidal forces of a second body. In DeFi, Charles defines the Roche Limit as the exact mathematical boundary—in liquidity imbalance, rounding precision, or donation ratios—where protocol solvency invariants break down, causing catastrophic liquidation cascades or insolvency.",
    },
    {
      q: "How does Roche achieve 0 Bytes dynamic heap allocation?",
      a: "All memory in Roche (U256 execution stack machine, linear memory arenas, McCarthy store-select array rings, and rollback journals) is pre-allocated within a strict hardware memory ceiling (10.0 GB max) on 64-byte hardware cache-line boundaries. Roche issues direct Win32/POSIX system calls (CreateFileA, ReadFile, MapViewOfFile) and performs zero runtime malloc/free operations.",
    },
    {
      q: "How does Roche execute 1.84 million state transitions per second?",
      a: "By leveraging 256-bit AVX2 and AVX-512 SIMD vector registers (@Vector(8, f32) and @Vector(32, u8)), Roche executes up to 32 parallel EVM contract states simultaneously in CPU hardware registers. It eliminates thread contention and locks using an O(1) lock-free ring buffer for state rollback.",
    },
    {
      q: "How does the McCarthy store-select SMT solver eliminate false positives?",
      a: "Instead of unconstrained fuzzing that hallucinates unrealistic state reaches, Roche constructs an Inter-procedural Control Flow Graph (ICFG) in SSA form. It models EVM storage slots as formal McCarthy store-select arrays (select(store(a, i, v), j)), mathematically proving whether a tainted storage slot can lead to an invariant breach under valid transaction sequences.",
    },
    {
      q: "What zero-day invariant breaches has Roche already identified?",
      a: "During formal evaluation, Roche mapped the exact Roche Limit of Euler V2 in LiquidityUtils.sol:112-117, proving that bid/ask pricing divergence against mid-point oracle calculations creates an exploit gain sink under volatile market conditions. It also validated Ethena sUSDe ERC-4626 virtual share offsets and Uniswap v4 transient storage (TSTORE/TLOAD) cross-hook isolation.",
    },
    {
      q: "What are the primary grant targets for Fall 2026?",
      a: "Roche is targeting five core ecosystem grants: (1) Uniswap Foundation ($75K) for v4 hook formal verification, (2) Base Ecosystem ($100K) for sub-millisecond OP Stack sequencer invariant filters, (3) Arbitrum Builders ($50K) for Stylus/EVM multi-VM invariant proofs, (4) Ethereum Foundation ESP ($50K) for an open-source McCarthy SMT reference prover, and (5) Optimism RetroPGF ($40K) for public-good developer infrastructure.",
    },
    {
      q: "Does Roche replace Foundry and Hardhat or integrate with them?",
      a: "Roche integrates seamlessly with existing workflows. You can run Roche as a drop-in accelerator (`roche test`) to execute Foundry or Hardhat test suites up to 1,920x faster, or use the `roche export-poc --forge` command to synthesize automated Solidity exploit tests from minimal counter-example traces.",
    },
    {
      q: "Can Roche be deployed inside continuous integration (CI/CD) pipelines?",
      a: "Yes. Roche is distributed as a single, zero-dependency static binary for Windows, Linux, and macOS. The `roche-action` GitHub Action runs in under 2 seconds on pull requests, acting as a deterministic gate that blocks any commit introducing invariant regressions or precision rounding drains.",
    },
    {
      q: "What is the open-source license and availability?",
      a: "Roche's core engine, EVM interpreter, and SMT invariant provers are 100% open source under the MIT/Apache-2.0 licenses. The full repository is available at github.com/creatorofaurad/roche with 29/29 verified test suites passing.",
    },
    {
      q: "How can protocol security teams collaborate with Charles?",
      a: "Protocol teams, audit firms (Code4rena, Sherlock, Cantina), and foundation grant committees can review the open-source repository or contact Charles directly for custom mathematical invariant modeling, sequencer integration, or pre-audit formal reviews.",
    },
  ];

  return (
    <section id="faq" className="py-20 px-4 sm:px-6 lg:px-8 max-w-4xl mx-auto border-b border-zinc-900 bg-black">
      {/* Header */}
      <div className="text-center mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded border border-zinc-800 bg-zinc-950 text-zinc-300 text-xs font-mono uppercase tracking-widest mb-4">
          <HelpCircle className="w-3.5 h-3.5" />
          Technical & Grant FAQ
        </div>
        <h2 className="text-3xl sm:text-5xl font-bold tracking-tight text-white mb-4">
          Frequently Asked Questions
        </h2>
        <p className="text-zinc-400 text-base sm:text-lg leading-relaxed">
          Detailed technical answers on the architecture, mathematical proofs, and ecosystem grant roadmap.
        </p>
      </div>

      {/* Accordion */}
      <div className="space-y-3">
        {faqs.map((faq, idx) => {
          const isOpen = openIndex === idx;
          return (
            <div
              key={idx}
              className={`rounded border transition-all duration-200 overflow-hidden ${
                isOpen
                  ? "border-zinc-700 bg-zinc-950"
                  : "border-zinc-900 bg-black hover:border-zinc-800"
              }`}
            >
              <button
                onClick={() => setOpenIndex(isOpen ? null : idx)}
                className="w-full px-5 py-4 flex items-center justify-between text-left focus:outline-none"
              >
                <span className="text-sm sm:text-base font-semibold text-white pr-4">
                  {faq.q}
                </span>
                <ChevronDown
                  className={`w-4 h-4 text-zinc-500 shrink-0 transition-transform duration-200 ${
                    isOpen ? "rotate-180 text-white" : ""
                  }`}
                />
              </button>

              {isOpen && (
                <div className="px-5 pb-5 pt-1 text-xs sm:text-sm text-zinc-400 leading-relaxed border-t border-zinc-900">
                  {faq.a}
                </div>
              )}
            </div>
          );
        })}
      </div>
    </section>
  );
}
