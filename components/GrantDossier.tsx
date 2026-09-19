"use client";

import React from "react";
import { CheckCircle2, Coins } from "lucide-react";

export default function GrantDossier() {
  const grants = [
    {
      foundation: "Uniswap Foundation",
      target: "Uniswap v4 Hook Formal Verification",
      ask: "$75,000",
      timeline: "4–6 Weeks",
      scope: [
        "Formal invariant proofs for Uniswap v4 transient storage (TSTORE/TLOAD) cross-hook isolation.",
        "Constant-product monotonicity prover (x * y >= k) with zero false-positive rate.",
        "Automated Foundry invariant harness generator for v4 custom hook developers.",
      ],
      deliverable: "roche-uniswap-verifier CLI + Automated Hook CI Gate",
    },
    {
      foundation: "Base Ecosystem",
      target: "Sub-Millisecond L2 Sequencer Invariant Prover",
      ask: "$100,000",
      timeline: "4–6 Weeks",
      scope: [
        "Real-time pre-sequencer invariant validation evaluating 1.84M state transitions/second.",
        "Cross-contract reentrancy & flash-loan drain prevention before transaction batch inclusion.",
        "Zero-allocation native binary integration for OP Stack rollup nodes.",
      ],
      deliverable: "OP Stack Native Invariant Filter Plugin",
    },
    {
      foundation: "Arbitrum Builders",
      target: "Stylus & EVM Multi-VM Invariant Prover",
      ask: "$50,000",
      timeline: "4–6 Weeks",
      scope: [
        "Cross-VM state synchronization prover between Solidity (EVM) and Rust/C++ (Stylus).",
        "Deterministic memory invariant verification across Stylus host I/O boundaries.",
        "Shared sequencer atomicity testing for Orbit chains.",
      ],
      deliverable: "Arbitrum Stylus Invariant Engine",
    },
    {
      foundation: "Ethereum Foundation ESP",
      target: "McCarthy SMT Array Theory Prover for EVM Core",
      ask: "$50,000",
      timeline: "6–8 Weeks",
      scope: [
        "Open-source SMT array theory solver specialized for EVM storage slot taints.",
        "Formal mathematical verification of ERC-4626, ERC-7540, and ERC-721 token invariants.",
        "Zero-dependency stand-alone C/Zig static library for Ethereum client architectures.",
      ],
      deliverable: "EVM Invariant Formal Specification & Reference Prover",
    },
  ];

  return (
    <section id="dossier" className="py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto border-b border-zinc-900 bg-black">
      {/* Section Header */}
      <div className="max-w-3xl mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded border border-zinc-800 bg-zinc-950 text-zinc-300 text-xs font-mono uppercase tracking-widest mb-4">
          <Coins className="w-3.5 h-3.5" />
          Targeted Ecosystem Deliverables
        </div>
        <h2 className="text-3xl sm:text-5xl font-bold tracking-tight text-white mb-4">
          Foundation Grant Proposals
        </h2>
        <p className="text-zinc-400 text-base sm:text-lg leading-relaxed">
          Roche is actively seeking targeted foundation grants to deploy zero-allocation invariant provers directly into core DeFi ecosystems. Here is our exact milestone breakdown.
        </p>
      </div>

      {/* Grant Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {grants.map((grant, idx) => (
          <div
            key={idx}
            className="p-7 rounded border border-zinc-900 bg-zinc-950/70 hover:border-zinc-800 transition-all flex flex-col justify-between"
          >
            <div>
              {/* Header row */}
              <div className="flex items-center justify-between mb-4">
                <span className="text-xs font-mono text-white bg-zinc-900 px-2.5 py-1 rounded border border-zinc-800 font-bold">
                  {grant.foundation}
                </span>
                <span className="text-xs font-mono text-zinc-500">
                  Ask: <strong className="text-white">{grant.ask}</strong> ({grant.timeline})
                </span>
              </div>

              <h3 className="text-xl font-bold text-white mb-3">
                {grant.target}
              </h3>

              {/* Scope */}
              <ul className="space-y-2.5 mb-6 text-sm text-zinc-400">
                {grant.scope.map((item, sIdx) => (
                  <li key={sIdx} className="flex items-start gap-2.5">
                    <CheckCircle2 className="w-4 h-4 text-white shrink-0 mt-0.5" />
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </div>

            {/* Deliverable Box */}
            <div className="pt-4 border-t border-zinc-900 flex items-center justify-between text-xs font-mono">
              <span className="text-zinc-500">Deliverable:</span>
              <span className="text-zinc-200 font-medium">{grant.deliverable}</span>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
