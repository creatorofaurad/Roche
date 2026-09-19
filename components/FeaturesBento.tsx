"use client";

import React from "react";
import { Globe, Shield, Terminal, ArrowRight, Box, Radio, Zap } from "lucide-react";

export default function FeaturesBento() {
  return (
    <section id="features" className="py-20 border-t border-[#1c1c20] relative">
      <div className="mx-auto max-w-7xl px-6 space-y-12">
        
        {/* Section Header */}
        <div className="space-y-3 max-w-2xl">
          <h2 className="text-2xl sm:text-4xl font-bold tracking-tight text-white">
            One window for everything you verify locally.
          </h2>
          <p className="text-zinc-400 text-sm sm:text-base leading-relaxed">
            Name it, share it, and watch every EVM state transition and opcode flow through — without touching your contract bytecode.
          </p>
        </div>

        {/* Bento Grid */}
        <div className="grid grid-cols-1 md:grid-cols-12 gap-6">

          {/* Top-Left Bento Item: Real-time Request Inspector (Span 8) */}
          <div className="md:col-span-8 rounded-2xl border border-[#222226] bg-[#101013] p-6 space-y-4 overflow-hidden relative group">
            <div className="space-y-1">
              <h3 className="text-base font-semibold text-white">See every state transition in real time</h3>
              <p className="text-xs text-zinc-400">Inspect storage slots, call frames, gas costs, and status codes as they flow through — no heavy node debuggers needed.</p>
            </div>

            {/* 3D Tilted Inspector Table */}
            <div className="rounded-xl border border-[#27272a] bg-[#0c0c0e] p-3 font-mono text-[11px] text-zinc-400 shadow-inner overflow-x-auto">
              <div className="flex items-center justify-between border-b border-zinc-800 pb-2 mb-2 text-zinc-500 text-[10px]">
                <span>METHOD · PATH</span>
                <span>STATUS</span>
                <span>LATENCY</span>
                <span>GAS</span>
              </div>
              <div className="space-y-2">
                <div className="flex items-center justify-between text-zinc-300 hover:bg-zinc-900/50 p-1 rounded">
                  <span className="text-emerald-400 font-bold">EXEC · /v4/swap_hook</span>
                  <span className="px-1.5 py-0.5 rounded bg-emerald-950 text-emerald-400 text-[9px]">200 OK</span>
                  <span>142 ns</span>
                  <span>21,000</span>
                </div>
                <div className="flex items-center justify-between text-zinc-300 hover:bg-zinc-900/50 p-1 rounded">
                  <span className="text-emerald-400 font-bold">READ · /storage/slot_0x0</span>
                  <span className="px-1.5 py-0.5 rounded bg-emerald-950 text-emerald-400 text-[9px]">200 OK</span>
                  <span>87 ns</span>
                  <span>2,100</span>
                </div>
                <div className="flex items-center justify-between text-zinc-300 hover:bg-zinc-900/50 p-1 rounded bg-red-950/20 border border-red-900/30">
                  <span className="text-red-400 font-bold">REVERT · /vault/donate</span>
                  <span className="px-1.5 py-0.5 rounded bg-red-950 text-red-400 text-[9px]">400 REVERT</span>
                  <span>310 ns</span>
                  <span>84,500</span>
                </div>
              </div>
            </div>
          </div>

          {/* Top-Right Bento Item: Named local URLs (Span 4) */}
          <div className="md:col-span-4 rounded-2xl border border-[#222226] bg-[#101013] p-6 flex flex-col justify-between space-y-6">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-zinc-900 border border-zinc-800 text-emerald-400">
              <Box className="h-6 w-6" />
            </div>
            <div className="space-y-2">
              <span className="text-xs font-mono text-emerald-400">roche.localhost</span>
              <h3 className="text-base font-semibold text-white">Named Local Invariants</h3>
              <p className="text-xs text-zinc-400">Works seamlessly with any smart contract framework, Foundry test suite, or Hardhat script.</p>
            </div>
          </div>

          {/* Bottom-Right Bento Item: Instant public links (Span 4) */}
          <div className="md:col-span-4 rounded-2xl border border-[#222226] bg-[#101013] p-6 flex flex-col justify-between space-y-6">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-zinc-900 border border-zinc-800 text-emerald-400">
              <Radio className="h-6 w-6 animate-pulse" />
            </div>
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <span className="h-2 w-2 rounded-full bg-emerald-400" />
                <span className="text-xs font-mono text-emerald-400">crimson-otter.roche.live</span>
              </div>
              <h3 className="text-base font-semibold text-white">Instant Exploit PoC Tunnels</h3>
              <p className="text-xs text-zinc-400">Share verifiable Foundry test harnesses over HTTPS in one click — demos, webhooks, audit reviews.</p>
            </div>
          </div>

          {/* Bottom-Left Bento Item: Pipeline in the middle (Span 8) */}
          <div className="md:col-span-8 rounded-2xl border border-[#222226] bg-[#101013] p-6 flex flex-col justify-between space-y-6">
            <div className="space-y-1">
              <h3 className="text-base font-semibold text-white">Roche sits at bare silicon</h3>
              <p className="text-xs text-zinc-400">It intercepts opcode transitions, records every storage slot delta, and enables sub-microsecond state rollbacks.</p>
            </div>

            {/* Architecture Pipeline Visual */}
            <div className="flex items-center justify-between rounded-xl bg-[#0c0c0e] border border-[#222226] p-4 text-xs font-mono">
              <div className="flex items-center gap-2 text-zinc-400">
                <Globe className="h-4 w-4 text-emerald-400" />
                <span>Sequencer / Fuzzer</span>
              </div>
              <div className="h-0.5 flex-1 mx-4 bg-gradient-to-r from-emerald-500/20 via-emerald-400 to-emerald-500/20" />
              <div className="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-emerald-950 border border-emerald-500 text-emerald-300 font-bold">
                <Shield className="h-4 w-4" />
                <span>Roche Engine</span>
              </div>
              <div className="h-0.5 flex-1 mx-4 bg-gradient-to-r from-emerald-500/20 via-emerald-400 to-emerald-500/20" />
              <div className="flex items-center gap-2 text-zinc-400">
                <Terminal className="h-4 w-4 text-zinc-500" />
                <span>Foundry .t.sol</span>
              </div>
            </div>
          </div>

        </div>

      </div>
    </section>
  );
}
