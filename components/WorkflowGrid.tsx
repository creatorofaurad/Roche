"use client";

import React from "react";
import {
  ShieldAlert,
  Share2,
  RefreshCw,
  GitBranch,
  Cpu,
  Lock,
  ArrowUpRight,
  Terminal,
  Activity,
  Layers,
} from "lucide-react";

export default function WorkflowGrid() {
  const cards = [
    {
      icon: ShieldAlert,
      tag: "Verification Engine",
      title: "Debug EVM Invariants in Real Time",
      description:
        "McCarthy store-select SMT solvers map invariant violations down to exact bytecode offsets before code reaches testnets.",
      badge: "SMT Formal Prover",
    },
    {
      icon: Share2,
      tag: "Collaboration",
      title: "Share PoC Exploit Tunnels Instantly",
      description:
        "Generate secure, zero-dependency reproducible execution snapshots. Share complete state forks with security teams in 1-click.",
      badge: "Zero-Latency Tunnels",
    },
    {
      icon: RefreshCw,
      tag: "State Machine",
      title: "Replay, Patch & Mutate Storage Slots",
      description:
        "Directly mutate storage slots in memory without re-running entire deployments. O(1) rollback ring buffer handles 10,000 deep state trees.",
      badge: "O(1) Ring Journal",
    },
    {
      icon: GitBranch,
      tag: "Cross-Rollup Sync",
      title: "Multi-Chain Shared Sequencer Proving",
      description:
        "Simulate atomic cross-chain arbitrage, LayerZero OFT packets, and bridge messaging in a unified local deterministic clock.",
      badge: "Cross-L2 Atomicity",
    },
    {
      icon: Cpu,
      tag: "Vectorized Silicon",
      title: "1.84M Invariant Execs / Second",
      description:
        "AVX-512 & AVX2 256-bit SIMD vectorized property fuzzing eliminates Node and Rust runtime heap overhead entirely.",
      badge: "AVX2 SIMD Core",
    },
    {
      icon: Lock,
      tag: "CI/CD Gate",
      title: "Zero-Trust Pre-Commit Guardrails",
      description:
        "Block precision rounding drains, donation share inflation, and flash-loan vulnerability commits in your CI pipeline automatically.",
      badge: "GitHub Actions / CI",
    },
  ];

  return (
    <section id="features" className="py-24 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto border-t border-white/[0.05]">
      {/* Header */}
      <div className="text-center max-w-3xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-emerald-500/30 bg-emerald-500/10 text-emerald-400 text-xs font-mono uppercase tracking-widest mb-4">
          <Activity className="w-3 h-3" />
          End-to-End Capabilities
        </div>
        <h2 className="text-3xl sm:text-5xl font-extrabold tracking-tight text-white mb-4">
          Built for High-Stakes Protocols
        </h2>
        <p className="text-zinc-400 text-base sm:text-lg">
          Every tool you need to formally prove protocol solvency, eliminate zero-day exploit vectors, and accelerate EVM development.
        </p>
      </div>

      {/* Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {cards.map((card, idx) => {
          const Icon = card.icon;
          return (
            <div
              key={idx}
              className="group relative rounded-2xl border border-white/[0.08] bg-zinc-950/60 p-7 hover:border-emerald-500/40 transition-all duration-300 hover:shadow-[0_0_25px_rgba(34,197,94,0.1)] flex flex-col justify-between overflow-hidden"
            >
              {/* Subtle background glow on hover */}
              <div className="absolute -right-12 -top-12 w-32 h-32 bg-emerald-500/5 rounded-full blur-2xl group-hover:bg-emerald-500/15 transition-all duration-500 pointer-events-none" />

              <div>
                {/* Header row with icon & tag */}
                <div className="flex items-center justify-between mb-6">
                  <div className="p-3 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 group-hover:scale-110 transition-transform duration-300">
                    <Icon className="w-6 h-6" />
                  </div>
                  <span className="text-[11px] font-mono uppercase tracking-wider text-zinc-500 bg-white/[0.03] px-2.5 py-1 rounded-full border border-white/[0.05]">
                    {card.tag}
                  </span>
                </div>

                {/* Title */}
                <h3 className="text-xl font-bold text-white mb-3 group-hover:text-emerald-300 transition-colors">
                  {card.title}
                </h3>

                {/* Description */}
                <p className="text-sm text-zinc-400 leading-relaxed mb-6">
                  {card.description}
                </p>
              </div>

              {/* Footer badge */}
              <div className="pt-4 border-t border-white/[0.04] flex items-center justify-between">
                <span className="text-xs font-mono text-emerald-400/90 font-medium">
                  {card.badge}
                </span>
                <ArrowUpRight className="w-4 h-4 text-zinc-600 group-hover:text-emerald-400 transition-colors" />
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
}
