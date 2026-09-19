"use client";

import React, { useState } from "react";
import { Copy, Check, Search, Settings, ExternalLink, ChevronRight, Activity } from "lucide-react";

export default function Hero() {
  const [copied, setCopied] = useState(false);
  const [toggle1, setToggle1] = useState(true);
  const [toggle2, setToggle2] = useState(true);

  const copyCommand = () => {
    navigator.clipboard.writeText("curl -fsSL https://roche.dev/install.sh | sh");
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <section className="relative overflow-hidden pt-12 pb-24 md:pt-20 md:pb-32">
      {/* Background Radial Glow */}
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 -translate-y-1/2 h-[500px] w-[800px] rounded-full bg-emerald-500/10 blur-[120px] pointer-events-none" />

      <div className="mx-auto max-w-7xl px-6">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center">
          
          {/* Left Hero Column */}
          <div className="lg:col-span-6 space-y-6">
            <h1 className="text-4xl sm:text-6xl font-bold tracking-tight text-white leading-[1.08]">
              Give EVM security <br />
              <span className="text-white">a name</span>
              <span className="animate-pulse text-emerald-400 font-mono">_</span>
            </h1>

            <p className="text-base sm:text-lg text-zinc-400 max-w-xl leading-relaxed">
              Find the precise <strong className="text-zinc-200">Roche Limit</strong> of DeFi protocols — zero dynamic allocation. Inspect invariants, minimize traces to $\le 4$ steps, and synthesize Foundry PoCs in $<2\mu s$.
            </p>

            {/* Install Bar */}
            <div className="space-y-2 pt-2">
              <div className="flex items-center justify-between rounded-xl bg-[#121215] border border-[#222226] px-4 py-3 max-w-lg shadow-2xl group hover:border-emerald-500/50 transition-colors">
                <div className="flex items-center gap-3 font-mono text-xs sm:text-sm text-zinc-300">
                  <span className="text-emerald-400 font-bold">$</span>
                  <span className="select-all">curl -fsSL https://roche.dev/install.sh | sh</span>
                </div>
                <button
                  onClick={copyCommand}
                  className="p-1.5 rounded-lg text-zinc-400 hover:text-white hover:bg-zinc-800 transition-colors"
                  title="Copy command"
                >
                  {copied ? <Check className="h-4 w-4 text-emerald-400" /> : <Copy className="h-4 w-4" />}
                </button>
              </div>

              <div className="flex items-center justify-between text-[11px] text-zinc-500 max-w-lg px-1">
                <span>Paste this in terminal</span>
                <span>macOS · Linux · Windows x86_64</span>
              </div>
            </div>
          </div>

          {/* Right Hero Column: Native App Mockup */}
          <div className="lg:col-span-6 flex justify-center lg:justify-end">
            <div className="w-full max-w-md rounded-2xl border border-[#27272a] bg-[#101013] shadow-2xl overflow-hidden glow-emerald">
              
              {/* App Window Header */}
              <div className="flex items-center justify-between px-4 py-3 border-b border-[#222226] bg-[#141418]">
                <div className="flex items-center gap-2">
                  <span className="h-2 w-2 rounded-full bg-emerald-400 animate-ping" />
                  <span className="text-xs font-semibold text-white">Roche</span>
                  <span className="text-[10px] px-1.5 py-0.5 rounded bg-emerald-950 text-emerald-400 font-mono">Running</span>
                </div>
                <div className="flex items-center gap-3 text-zinc-400 text-xs">
                  <span className="text-[11px] font-mono text-zinc-400">2 routes · proxy :80</span>
                  <Settings className="h-3.5 w-3.5 hover:text-white cursor-pointer" />
                </div>
              </div>

              {/* Search Bar */}
              <div className="p-3 border-b border-[#1c1c20] bg-[#0c0c0e]">
                <div className="flex items-center gap-2 rounded-lg bg-[#16161a] border border-[#222226] px-3 py-1.5 text-xs text-zinc-400">
                  <Search className="h-3.5 w-3.5 text-zinc-500" />
                  <span>Search protocol invariants...</span>
                </div>
              </div>

              {/* Route Card 1: Uniswap v4 Invariant */}
              <div className="p-3.5 space-y-3 border-b border-[#1c1c20] hover:bg-[#141418] transition-colors">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="h-2 w-2 rounded-full bg-emerald-400" />
                    <span className="text-xs font-mono font-medium text-white">uniswap.v4</span>
                    <span className="text-[10px] text-zinc-500 font-mono">localhost:3000</span>
                  </div>
                  <button
                    onClick={() => setToggle1(!toggle1)}
                    className={`h-4 w-7 rounded-full transition-colors flex items-center p-0.5 ${toggle1 ? 'bg-emerald-500 justify-end' : 'bg-zinc-700 justify-start'}`}
                  >
                    <span className="h-3 w-3 rounded-full bg-white block" />
                  </button>
                </div>

                <div className="space-y-1.5 font-mono text-[11px] text-zinc-400 pl-4 border-l border-emerald-500/30">
                  <div className="flex items-center justify-between">
                    <span className="text-zinc-300">http://uniswap.roche.local</span>
                    <ExternalLink className="h-3 w-3 text-zinc-500 hover:text-white" />
                  </div>
                  <div className="flex items-center justify-between text-emerald-400">
                    <span className="flex items-center gap-1.5">
                      <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
                      https://crimson-otter.roche.live
                    </span>
                    <span className="text-[9px] uppercase px-1 py-0.2 rounded bg-emerald-950 text-emerald-300">LIVE</span>
                  </div>
                </div>

                <div className="flex items-center justify-between text-[11px] pt-1 text-zinc-500 font-mono">
                  <span className="flex items-center gap-1 text-emerald-400">
                    <Activity className="h-3 w-3" />
                    1,284 reqs · 0 err
                  </span>
                  <a href="#inspector" className="flex items-center gap-0.5 text-zinc-300 hover:text-white font-sans">
                    INSPECT <ChevronRight className="h-3 w-3" />
                  </a>
                </div>
              </div>

              {/* Route Card 2: Euler v2 Vault */}
              <div className="p-3.5 space-y-3 hover:bg-[#141418] transition-colors">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="h-2 w-2 rounded-full bg-emerald-400" />
                    <span className="text-xs font-mono font-medium text-white">euler.vault</span>
                    <span className="text-[10px] text-zinc-500 font-mono">localhost:4000</span>
                  </div>
                  <button
                    onClick={() => setToggle2(!toggle2)}
                    className={`h-4 w-7 rounded-full transition-colors flex items-center p-0.5 ${toggle2 ? 'bg-emerald-500 justify-end' : 'bg-zinc-700 justify-start'}`}
                  >
                    <span className="h-3 w-3 rounded-full bg-white block" />
                  </button>
                </div>

                <div className="space-y-1.5 font-mono text-[11px] text-zinc-400 pl-4 border-l border-zinc-700">
                  <div className="flex items-center justify-between">
                    <span className="text-zinc-300">http://euler.roche.local</span>
                    <ExternalLink className="h-3 w-3 text-zinc-500 hover:text-white" />
                  </div>
                </div>

                <div className="flex items-center justify-between text-[11px] pt-1 text-zinc-500 font-mono">
                  <span>412 reqs</span>
                  <button className="text-xs font-sans text-emerald-400 hover:underline">
                    PUBLIC URL
                  </button>
                </div>
              </div>

              {/* App Footer */}
              <div className="flex items-center justify-between px-4 py-2.5 border-t border-[#1c1c20] bg-[#0c0c0e] text-[11px] text-zinc-500 font-mono">
                <span>v1.0.0</span>
                <span className="hover:text-zinc-300 cursor-pointer">Quit</span>
              </div>

            </div>
          </div>

        </div>
      </div>
    </section>
  );
}
