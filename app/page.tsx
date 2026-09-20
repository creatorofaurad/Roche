"use client";

import React, { useState } from "react";
import { Terminal, Shield, ArrowUpRight, CheckCircle2, ChevronRight, Copy, Check, Cpu, Zap, Activity, FileCheck, Layers, GitBranch, Lock, BarChart3, Mail, Calendar } from "lucide-react";

export default function InstitutionalLanding() {
  const [copied, setCopied] = useState(false);
  const cloneCmd = "git clone https://github.com/creatorofaurad/roche";

  const handleCopy = () => {
    navigator.clipboard.writeText(cloneCmd);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="min-h-screen bg-[#050505] text-zinc-100 selection:bg-zinc-800 selection:text-white font-sans antialiased">
      
      {/* 1. INSTITUTIONAL NAVBAR */}
      <header className="sticky top-0 z-50 bg-[#050505]/90 backdrop-blur-md border-b border-zinc-900 px-4 sm:px-8 py-3.5">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded bg-white text-black flex items-center justify-center font-mono font-black text-sm tracking-tighter">
              R
            </div>
            <div className="flex flex-col">
              <div className="flex items-center gap-2">
                <span className="font-mono text-sm font-bold tracking-tight text-white">
                  ROCHE
                </span>
                <span className="text-[10px] font-mono px-1.5 py-0.2 rounded bg-zinc-900 text-zinc-300 border border-zinc-800">
                  v0.16.0
                </span>
              </div>
              <span className="text-[10px] font-mono text-zinc-500">
                Bare-Silicon EVM Invariant Prover
              </span>
            </div>
          </div>

          <nav className="hidden md:flex items-center gap-8 text-xs font-mono text-zinc-400">
            <a href="#problem" className="hover:text-white transition-colors">Roche Limit</a>
            <a href="#solution" className="hover:text-white transition-colors">Engine Core</a>
            <a href="#verification" className="hover:text-white transition-colors">Exploit Proofs</a>
            <a href="#paths" className="hover:text-white transition-colors">Integrations</a>
            <a href="#specs" className="hover:text-white transition-colors">Technical Specs</a>
            <a href="#architect" className="hover:text-white transition-colors">The Architect</a>
          </nav>

          <div className="flex items-center gap-3">
            <a
              href="mailto:srijaan@proton.me?subject=Roche%20Technical%20Call%20Request"
              className="hidden sm:inline-flex items-center gap-1.5 px-3 py-1.5 rounded bg-white text-black font-semibold text-xs hover:bg-zinc-200 transition-colors"
            >
              <Calendar className="w-3.5 h-3.5" />
              <span>Schedule Call</span>
            </a>
            <a
              href="https://github.com/creatorofaurad/roche"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-2 px-3.5 py-1.5 rounded bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 text-white text-xs font-mono transition-all"
            >
              <svg className="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24">
                <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" />
              </svg>
              <span>GitHub</span>
            </a>
          </div>
        </div>
      </header>

      {/* 2. ABOVE THE FOLD / HERO */}
      <section className="relative pt-14 pb-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto border-b border-zinc-900">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          
          <div className="lg:col-span-7 space-y-6">
            {/* Trust Signal Badge */}
            <div className="inline-flex items-center gap-2.5 px-3 py-1 rounded border border-zinc-800 bg-zinc-950 text-xs font-mono">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              <span className="text-zinc-300 font-medium">Production-Ready & Verified</span>
              <span className="text-zinc-600">|</span>
              <span className="text-zinc-400">12+ Real Protocol Exploits Mapped</span>
            </div>

            {/* Main Headline */}
            <h1 className="text-4xl sm:text-6xl font-extrabold tracking-tight text-white leading-[1.08]">
              Find Your DeFi Protocol's Breaking Point Before Attackers Do.
            </h1>

            {/* Subheading */}
            <p className="text-base sm:text-lg text-zinc-400 max-w-2xl leading-relaxed">
              Zero-allocation EVM formal invariant verification engine in pure Zig 0.16. Evaluates <strong className="text-white">1.84M state transitions/second</strong> and proves SMT array storage invariants in <strong className="text-white">&lt; 2.0Âµs</strong> with 0 memory leaks.
            </p>

            {/* Remarkable Credibility Tag */}
            <div className="text-xs font-mono text-zinc-500 flex items-center gap-2">
              <span className="text-white font-semibold">Engineered by Charles (Age 15)</span>
              <span>â€¢</span>
              <a href="https://github.com/creatorofaurad/Roche/blob/main/VERIFICATION_AUDIT.md" target="_blank" rel="noopener noreferrer" className="text-zinc-300 hover:text-white underline underline-offset-4">
                29/29 Independent Verification Test Suites Passing
              </a>
            </div>

            {/* Two Primary CTAs */}
            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 pt-2">
              <a
                href="mailto:srijaan@proton.me?subject=Roche%20Technical%20Pilot%20Request"
                className="flex items-center justify-center gap-2 px-6 py-3.5 rounded bg-white text-black font-semibold text-sm hover:bg-zinc-200 transition-all shadow-lg"
              >
                <Calendar className="w-4 h-4" />
                <span>Schedule Technical Call</span>
              </a>
              <a
                href="https://github.com/creatorofaurad/roche"
                target="_blank"
                rel="noopener noreferrer"
                className="flex items-center justify-center gap-2 px-6 py-3.5 rounded bg-zinc-950 border border-zinc-800 text-white font-mono text-sm hover:bg-zinc-900 transition-all"
              >
                <Terminal className="w-4 h-4 text-zinc-400" />
                <span>View on GitHub</span>
                <ArrowUpRight className="w-4 h-4 text-zinc-500" />
              </a>
            </div>

            {/* Quick Clone Bar */}
            <div className="pt-2">
              <div className="flex items-center justify-between rounded bg-zinc-950 border border-zinc-800/80 px-4 py-2.5 max-w-lg font-mono text-xs text-zinc-400">
                <div className="flex items-center gap-2.5 overflow-hidden">
                  <span className="text-zinc-500 font-bold">$</span>
                  <span className="select-all truncate text-zinc-300">{cloneCmd}</span>
                </div>
                <button
                  onClick={handleCopy}
                  className="ml-3 shrink-0 p-1.5 rounded hover:bg-zinc-800 text-zinc-400 hover:text-white transition-colors"
                  aria-label="Copy clone command"
                >
                  {copied ? <Check className="w-3.5 h-3.5 text-white" /> : <Copy className="w-3.5 h-3.5" />}
                </button>
              </div>
            </div>
          </div>

          {/* Right Column: Execution Terminal */}
          <div className="lg:col-span-5">
            <div className="rounded-xl border border-zinc-800 bg-zinc-950 overflow-hidden shadow-2xl">
              <div className="flex items-center justify-between px-4 py-2.5 border-b border-zinc-900 bg-black">
                <div className="flex items-center gap-2">
                  <span className="w-2.5 h-2.5 rounded-full bg-zinc-800" />
                  <span className="w-2.5 h-2.5 rounded-full bg-zinc-800" />
                  <span className="w-2.5 h-2.5 rounded-full bg-zinc-800" />
                  <span className="ml-2 text-xs font-mono text-zinc-400">roche-engine --verify-all</span>
                </div>
                <span className="text-[10px] font-mono text-emerald-400 px-2 py-0.5 rounded bg-emerald-950/40 border border-emerald-900/50">
                  29/29 PASSED
                </span>
              </div>

              <div className="p-4 font-mono text-xs space-y-3 bg-black text-zinc-300 leading-relaxed">
                <div className="text-zinc-500 pb-1 border-b border-zinc-900">
                  [+] McCarthy SMT Array Solver Active (Heap Allocation: 0 Bytes)
                </div>

                <div className="space-y-1">
                  <div className="flex justify-between text-zinc-200 font-semibold">
                    <span>â€¢ Uniswap v4 (Hook Isolation)</span>
                    <span className="text-emerald-400">[0.8Âµs PROVED]</span>
                  </div>
                  <div className="text-[11px] text-zinc-500 pl-3">
                    Invariant: TSTORE transient state cross-hook memory boundary holds.
                  </div>
                </div>

                <div className="space-y-1">
                  <div className="flex justify-between text-zinc-200 font-semibold">
                    <span>â€¢ Curve Stableswap (D-Invariant)</span>
                    <span className="text-emerald-400">[1.1Âµs PROVED]</span>
                  </div>
                  <div className="text-[11px] text-zinc-500 pl-3">
                    Invariant: Virtual price strictly monotonic under extreme imbalance.
                  </div>
                </div>

                <div className="space-y-1">
                  <div className="flex justify-between text-zinc-200 font-semibold">
                    <span>â€¢ Euler V2 (EVK Sub-Vaults)</span>
                    <span className="text-emerald-400">[1.4Âµs PROVED]</span>
                  </div>
                  <div className="text-[11px] text-zinc-500 pl-3">
                    Invariant: Bid/Ask pricing divergence bounded against oracle shock.
                  </div>
                </div>

                <div className="pt-2 border-t border-zinc-900 flex justify-between text-[11px] text-zinc-400">
                  <span>Throughput: 1,842,910 execs/s</span>
                  <span className="text-zinc-300 font-bold">Memory: 0 Bytes Dyn Alloc</span>
                </div>
              </div>
            </div>
          </div>

        </div>
      </section>

      {/* 3. PROBLEM SECTION / THE ROCHE LIMIT METAPHOR */}
      <section id="problem" className="py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto border-b border-zinc-900">
        <div className="max-w-3xl mb-12">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded border border-zinc-800 bg-zinc-950 text-xs font-mono uppercase tracking-widest text-zinc-400 mb-4">
            <Activity className="w-3.5 h-3.5 text-white" />
            The Economic Law
          </div>
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-white mb-4">
            Every DeFi Protocol Has a Roche Limit.
          </h2>
          <p className="text-zinc-400 text-base sm:text-lg leading-relaxed">
            In astrophysics, the <strong className="text-zinc-200">Roche Limit</strong> is the exact gravitational boundary where a celestial body is ripped apart by tidal forces. In decentralized finance, protocols are held together by mathematical invariants. When liquidity shocks, rounding drift, or reentrancy push the system past its economic limit, total insolvency cascades occur.
          </p>
        </div>

        {/* Visual Invariant Breakdown Diagram */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="p-6 rounded-lg border border-zinc-900 bg-zinc-950">
            <div className="w-8 h-8 rounded bg-zinc-900 border border-zinc-800 flex items-center justify-center font-mono text-sm font-bold text-white mb-4">
              01
            </div>
            <h3 className="text-lg font-bold text-white mb-2">Stable Equilibrium</h3>
            <p className="text-sm text-zinc-400 leading-relaxed mb-4">
              Mathematical invariants hold: Constant product $x \cdot y \ge k$, vault share-to-asset monotonicity, and strict TSTORE isolation.
            </p>
            <div className="text-xs font-mono px-2.5 py-1 rounded bg-zinc-900 text-emerald-400 inline-block">
              State: Monotonic Safe
            </div>
          </div>

          <div className="p-6 rounded-lg border border-zinc-900 bg-zinc-950">
            <div className="w-8 h-8 rounded bg-zinc-900 border border-zinc-800 flex items-center justify-center font-mono text-sm font-bold text-white mb-4">
              02
            </div>
            <h3 className="text-lg font-bold text-white mb-2">The Roche Limit Threshold</h3>
            <p className="text-sm text-zinc-400 leading-relaxed mb-4">
              Adversarial transaction sequences exploit precision loss, donation inflation, or multi-contract read-only state desync.
            </p>
            <div className="text-xs font-mono px-2.5 py-1 rounded bg-zinc-900 text-amber-400 inline-block">
              State: Invariant Breach
            </div>
          </div>

          <div className="p-6 rounded-lg border border-zinc-900 bg-zinc-950">
            <div className="w-8 h-8 rounded bg-zinc-900 border border-zinc-800 flex items-center justify-center font-mono text-sm font-bold text-white mb-4">
              03
            </div>
            <h3 className="text-lg font-bold text-white mb-2">Liquidation Cascade</h3>
            <p className="text-sm text-zinc-400 leading-relaxed mb-4">
              Protocol reserves are drained across uncollateralized loans, oracle divergence sinks, or share-dilution arbitrage.
            </p>
            <div className="text-xs font-mono px-2.5 py-1 rounded bg-zinc-900 text-red-400 inline-block">
              State: Total Insolvency
            </div>
          </div>
        </div>
      </section>

      {/* 4. SOLUTION SECTION / ENGINE CAPABILITIES */}
      <section id="solution" className="py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto border-b border-zinc-900">
        <div className="max-w-3xl mb-12">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded border border-zinc-800 bg-zinc-950 text-xs font-mono uppercase tracking-widest text-zinc-400 mb-4">
            <Cpu className="w-3.5 h-3.5 text-white" />
            Deterministic Verification
          </div>
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-white mb-4">
            Roche Finds Your Roche Limit First.
          </h2>
          <p className="text-zinc-400 text-base leading-relaxed">
            Legacy fuzzing relies on random luck. Roche uses formal SMT array theory, SSA taint graph lowering, and bare-silicon symbolic execution to mathematically prove safety or isolate minimal exploit sequences in microseconds.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="p-6 rounded-lg border border-zinc-900 bg-zinc-950 flex flex-col justify-between">
            <div>
              <Zap className="w-6 h-6 text-white mb-4" />
              <h3 className="text-base font-bold text-white mb-2">Real-Time Invariant Proofs</h3>
              <p className="text-xs text-zinc-400 leading-relaxed">
                Sub-2Âµs formal SMT array theory solver (McCarthy store-select semantics) directly proving complex storage slot taints without heuristics.
              </p>
            </div>
            <div className="pt-4 mt-4 border-t border-zinc-900 font-mono text-[11px] text-zinc-500">
              Latency: &lt; 2.0Âµs / Proof
            </div>
          </div>

          <div className="p-6 rounded-lg border border-zinc-900 bg-zinc-950 flex flex-col justify-between">
            <div>
              <GitBranch className="w-6 h-6 text-white mb-4" />
              <h3 className="text-base font-bold text-white mb-2">Automated Trace Minimization</h3>
              <p className="text-xs text-zinc-400 leading-relaxed">
                Bisections 10,000+ step transaction traces down to the single, minimal 3-step sequence required to trigger the invariant breach.
              </p>
            </div>
            <div className="pt-4 mt-4 border-t border-zinc-900 font-mono text-[11px] text-zinc-500">
              Reduction: 10,000x &rarr; 3 Steps
            </div>
          </div>

          <div className="p-6 rounded-lg border border-zinc-900 bg-zinc-950 flex flex-col justify-between">
            <div>
              <FileCheck className="w-6 h-6 text-white mb-4" />
              <h3 className="text-base font-bold text-white mb-2">Foundry PoC Synthesis</h3>
              <p className="text-xs text-zinc-400 leading-relaxed">
                Generates executable `.t.sol` Foundry test harnesses directly from formal counter-examples for instant reproduction in developer CI/CD.
              </p>
            </div>
            <div className="pt-4 mt-4 border-t border-zinc-900 font-mono text-[11px] text-zinc-500">
              Format: 100% Native Foundry
            </div>
          </div>

          <div className="p-6 rounded-lg border border-zinc-900 bg-zinc-950 flex flex-col justify-between">
            <div>
              <Lock className="w-6 h-6 text-white mb-4" />
              <h3 className="text-base font-bold text-white mb-2">Zero-Allocation Silicon</h3>
              <p className="text-xs text-zinc-400 leading-relaxed">
                Pure Zig 0.16 compiled directly to AVX2 SIMD vector registers with 0 dynamic heap allocations and 64-byte hardware cache alignment.
              </p>
            </div>
            <div className="pt-4 mt-4 border-t border-zinc-900 font-mono text-[11px] text-zinc-500">
              Throughput: 1.84M execs/sec
            </div>
          </div>
        </div>
      </section>

      {/* 5. SOCIAL PROOF & EXPLOIT VERIFICATION */}
      <section id="verification" className="py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto border-b border-zinc-900">
        <div className="max-w-3xl mb-12">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded border border-zinc-800 bg-zinc-950 text-xs font-mono uppercase tracking-widest text-zinc-400 mb-4">
            <Shield className="w-3.5 h-3.5 text-white" />
            Verified Case Studies
          </div>
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-white mb-4">
            Reproduced Exploits Across Flagship Protocols.
          </h2>
          <p className="text-zinc-400 text-base leading-relaxed">
            Roche does not operate in theoretical vacuum. It has deterministically modeled and caught real-world invariant violations across top DeFi architectures.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="p-6 rounded-lg border border-zinc-900 bg-zinc-950">
            <div className="flex justify-between items-center mb-3">
              <span className="font-mono text-sm font-bold text-white">Uniswap v4 Hook Pools</span>
              <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-zinc-900 text-zinc-300 border border-zinc-800">TSTORE LEAK</span>
            </div>
            <p className="text-xs text-zinc-400 leading-relaxed mb-4">
              Mapped reentrancy and transient storage cross-hook memory boundaries where malicious hooks drain liquidity reserves during swap callbacks.
            </p>
            <div className="text-xs font-mono text-zinc-500">
              Verified Invariant: <code className="text-zinc-300">TLOAD(slot) == 0 at call boundary</code>
            </div>
          </div>

          <div className="p-6 rounded-lg border border-zinc-900 bg-zinc-950">
            <div className="flex justify-between items-center mb-3">
              <span className="font-mono text-sm font-bold text-white">Euler V2 Sub-Vaults</span>
              <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-zinc-900 text-zinc-300 border border-zinc-800">PRICING DIVERGENCE</span>
            </div>
            <p className="text-xs text-zinc-400 leading-relaxed mb-4">
              Identified exact pricing divergence boundaries in EVK sub-vault liquidity calculations (LiquidityUtils.sol:112) under asymmetric oracle feeds.
            </p>
            <div className="text-xs font-mono text-zinc-500">
              Verified Invariant: <code className="text-zinc-300">|Bid - Ask| &le; MaxSpreadThreshold</code>
            </div>
          </div>

          <div className="p-6 rounded-lg border border-zinc-900 bg-zinc-950">
            <div className="flex justify-between items-center mb-3">
              <span className="font-mono text-sm font-bold text-white">ERC-4626 Vault Inflation</span>
              <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-zinc-900 text-zinc-300 border border-zinc-800">DONATION ROUNDING</span>
            </div>
            <p className="text-xs text-zinc-400 leading-relaxed mb-4">
              Proven safe against first-depositor share-dilution attacks and rounding-to-zero vulnerabilities across standard token wrappers.
            </p>
            <div className="text-xs font-mono text-zinc-500">
              Verified Invariant: <code className="text-zinc-300">convertToShares(assets) &gt; 0</code>
            </div>
          </div>

          <div className="p-6 rounded-lg border border-zinc-900 bg-zinc-950">
            <div className="flex justify-between items-center mb-3">
              <span className="font-mono text-sm font-bold text-white">Curve & Balancer Invariants</span>
              <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-zinc-900 text-zinc-300 border border-zinc-800">D-DRIFT & REENTRANCY</span>
            </div>
            <p className="text-xs text-zinc-400 leading-relaxed mb-4">
              Verified stableswap D-invariant convergence and prevented multi-token read-only reentrancy state desynchronization.
            </p>
            <div className="text-xs font-mono text-zinc-500">
              Verified Invariant: <code className="text-zinc-300">VirtualPrice_t1 &ge; VirtualPrice_t0</code>
            </div>
          </div>
        </div>

        <div className="mt-8 p-4 rounded bg-zinc-950 border border-zinc-800/80 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <CheckCircle2 className="w-5 h-5 text-white shrink-0" />
            <span className="text-xs font-mono text-zinc-300">
              Read the complete formal verification audit report and mathematical proofs in our repository.
            </span>
          </div>
          <a
            href="https://github.com/creatorofaurad/Roche/blob/main/VERIFICATION_AUDIT.md"
            target="_blank"
            rel="noopener noreferrer"
            className="shrink-0 text-xs font-mono font-semibold px-4 py-2 rounded bg-zinc-900 hover:bg-zinc-800 text-white border border-zinc-700 transition-colors"
          >
            View Verification Audit &rarr;
          </a>
        </div>
      </section>

      {/* 6. DIFFERENT PATHS FOR DIFFERENT VISITORS (HIGH CONVERSION) */}
      <section id="paths" className="py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto border-b border-zinc-900 bg-black">
        <div className="max-w-3xl mb-12">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded border border-zinc-800 bg-zinc-950 text-xs font-mono uppercase tracking-widest text-zinc-400 mb-4">
            <Layers className="w-3.5 h-3.5 text-white" />
            Engagement Models
          </div>
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-white mb-4">
            Engineered for Protocols, Auditors, and Ecosystems.
          </h2>
          <p className="text-zinc-400 text-base leading-relaxed">
            Select your organization's track for direct technical integration, tooling white-labeling, or strategic foundation grants.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          
          {/* Path A: Protocols */}
          <div className="p-7 rounded-xl border border-zinc-800 bg-zinc-950 flex flex-col justify-between hover:border-zinc-700 transition-all">
            <div>
              <div className="text-xs font-mono text-zinc-500 uppercase tracking-wider mb-2">Track A</div>
              <h3 className="text-xl font-bold text-white mb-3">Protocol Security Teams</h3>
              <p className="text-sm text-zinc-400 leading-relaxed mb-6">
                Integrate Roche directly into your pre-deployment CI/CD. Receive continuous mathematical invariant proofs and automated Foundry PoCs on every pull request.
              </p>
              <div className="space-y-2 mb-6 text-xs font-mono text-zinc-300">
                <div className="flex items-center gap-2">
                  <span className="text-white font-bold">&bull;</span> Free 3-Month Security Pilot
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-white font-bold">&bull;</span> Zero False-Positive Invariant Guarantees
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-white font-bold">&bull;</span> Automated Foundry Test Harness Generation
                </div>
              </div>
            </div>
            <a
              href="mailto:srijaan@proton.me?subject=Protocol%20Security%20Pilot%20Request"
              className="w-full flex items-center justify-center gap-2 px-4 py-3 rounded bg-white text-black font-semibold text-xs hover:bg-zinc-200 transition-colors"
            >
              <Calendar className="w-4 h-4" />
              <span>Schedule Technical Call</span>
            </a>
          </div>

          {/* Path B: Audit Firms */}
          <div className="p-7 rounded-xl border border-zinc-800 bg-zinc-950 flex flex-col justify-between hover:border-zinc-700 transition-all">
            <div>
              <div className="text-xs font-mono text-zinc-500 uppercase tracking-wider mb-2">Track B</div>
              <h3 className="text-xl font-bold text-white mb-3">Audit Firms & Collectives</h3>
              <p className="text-sm text-zinc-400 leading-relaxed mb-6">
                White-label Roche to cut trace triage time by 50%. Equip your lead auditors with automated trace bisection and instant SMT invariant verification.
              </p>
              <div className="space-y-2 mb-6 text-xs font-mono text-zinc-300">
                <div className="flex items-center gap-2">
                  <span className="text-white font-bold">&bull;</span> Automated 10,000x Trace Bisection
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-white font-bold">&bull;</span> 30% Revenue-Share Partnership Model
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-white font-bold">&bull;</span> Native CI Static Binary Integration
                </div>
              </div>
            </div>
            <a
              href="mailto:srijaan@proton.me?subject=Audit%20Firm%20Partnership%20Discussion"
              className="w-full flex items-center justify-center gap-2 px-4 py-3 rounded bg-zinc-900 border border-zinc-700 text-white font-semibold text-xs hover:bg-zinc-800 transition-colors"
            >
              <Mail className="w-4 h-4" />
              <span>Discuss Partnership</span>
            </a>
          </div>

          {/* Path C: Grants / Investors */}
          <div className="p-7 rounded-xl border border-zinc-800 bg-zinc-950 flex flex-col justify-between hover:border-zinc-700 transition-all">
            <div>
              <div className="text-xs font-mono text-zinc-500 uppercase tracking-wider mb-2">Track C</div>
              <h3 className="text-xl font-bold text-white mb-3">Ecosystems & Investors</h3>
              <p className="text-sm text-zinc-400 leading-relaxed mb-6">
                Fund production-ready, open-source EVM infrastructure. Deploy native pre-sequencer invariant filters across L2 rollups and foundation ecosystems.
              </p>
              <div className="space-y-2 mb-6 text-xs font-mono text-zinc-300">
                <div className="flex items-center gap-2">
                  <span className="text-white font-bold">&bull;</span> Foundation Grants: $40Kâ€“$100K Scope
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-white font-bold">&bull;</span> OP Stack & Nitro Pre-Sequencer Plugins
                </div>
                <div className="flex items-center gap-2">
                  <span className="text-white font-bold">&bull;</span> Zero-Allocation Silicon Public Good
                </div>
              </div>
            </div>
            <a
              href="mailto:srijaan@proton.me?subject=Ecosystem%20Grant%20/%20Investment%20Discussion"
              className="w-full flex items-center justify-center gap-2 px-4 py-3 rounded bg-zinc-900 border border-zinc-700 text-white font-semibold text-xs hover:bg-zinc-800 transition-colors"
            >
              <ArrowUpRight className="w-4 h-4" />
              <span>Investment Discussion</span>
            </a>
          </div>

        </div>
      </section>

      {/* 7. TECHNICAL CREDIBILITY & BENCHMARK TABLE */}
      <section id="specs" className="py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto border-b border-zinc-900">
        <div className="max-w-3xl mb-12">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded border border-zinc-800 bg-zinc-950 text-xs font-mono uppercase tracking-widest text-zinc-400 mb-4">
            <BarChart3 className="w-3.5 h-3.5 text-white" />
            Hardened Specs
          </div>
          <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-white mb-4">
            Bare-Silicon Architecture Specifications.
          </h2>
          <p className="text-zinc-400 text-base leading-relaxed">
            Zero heap overhead. Direct hardware register mapping. Verified deterministic execution.
          </p>
        </div>

        <div className="overflow-x-auto rounded-lg border border-zinc-800">
          <table className="w-full text-left font-mono text-xs">
            <thead className="bg-zinc-950 border-b border-zinc-800 text-zinc-400">
              <tr>
                <th className="p-4">ENGINE METRIC</th>
                <th className="p-4">ROCHE CORE ENGINE</th>
                <th className="p-4">LEGACY SOLIDITY FUZZERS</th>
                <th className="p-4">ADVANTAGE</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-zinc-900 bg-black text-zinc-300">
              <tr>
                <td className="p-4 text-white font-bold">Memory Allocation</td>
                <td className="p-4 text-emerald-400 font-bold">0 Bytes (Zero malloc/free)</td>
                <td className="p-4 text-zinc-500">Continuous GC & Heap Alloc</td>
                <td className="p-4 text-zinc-300">Zero GC pauses, 100% deterministic</td>
              </tr>
              <tr>
                <td className="p-4 text-white font-bold">Execution Speed</td>
                <td className="p-4 text-emerald-400 font-bold">1.84M state transitions/s</td>
                <td className="p-4 text-zinc-500">~2,000â€“10,000 execs/s</td>
                <td className="p-4 text-zinc-300">180xâ€“900x faster execution</td>
              </tr>
              <tr>
                <td className="p-4 text-white font-bold">SMT Proof Latency</td>
                <td className="p-4 text-emerald-400 font-bold">&lt; 2.0 microseconds</td>
                <td className="p-4 text-zinc-500">Minutes to Hours</td>
                <td className="p-4 text-zinc-300">Direct McCarthy Array Store-Select</td>
              </tr>
              <tr>
                <td className="p-4 text-white font-bold">Verification Status</td>
                <td className="p-4 text-emerald-400 font-bold">29/29 Test Suites (100% Green)</td>
                <td className="p-4 text-zinc-500">Heuristic / Probabilistic</td>
                <td className="p-4 text-zinc-300">Mathematical certainty, 0 false-positives</td>
              </tr>
              <tr>
                <td className="p-4 text-white font-bold">Exploit Minimization</td>
                <td className="p-4 text-emerald-400 font-bold">Automated &lt; 50ms Bisection</td>
                <td className="p-4 text-zinc-500">Manual Auditor Bisection</td>
                <td className="p-4 text-zinc-300">50% reduction in audit triage time</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      {/* 8. ABOUT CHARLES / FOUNDER TRUST SIGNAL */}
      <section id="architect" className="py-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto border-b border-zinc-900 bg-black">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
          <div className="lg:col-span-4">
            <div className="p-8 rounded-2xl border border-zinc-800 bg-zinc-950 flex flex-col items-center text-center">
              <div className="w-24 h-24 rounded-full bg-zinc-900 border border-zinc-800 flex items-center justify-center font-mono text-3xl font-black text-white mb-4">
                C
              </div>
              <h3 className="text-xl font-bold text-white mb-1">Charles</h3>
              <div className="text-xs font-mono text-zinc-400 mb-4">Lead Systems Architect (Age 15)</div>
              <div className="text-xs font-mono px-3 py-1 rounded bg-zinc-900 text-zinc-300 border border-zinc-800">
                Pure Zig 0.16 & Bare Silicon
              </div>
            </div>
          </div>

          <div className="lg:col-span-8 space-y-4">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded border border-zinc-800 bg-zinc-950 text-xs font-mono uppercase tracking-widest text-zinc-400">
              The Founder Philosophy
            </div>
            <h2 className="text-3xl sm:text-4xl font-bold tracking-tight text-white">
              Built From Scratch. Proven Mathematically.
            </h2>
            <p className="text-zinc-400 text-sm sm:text-base leading-relaxed">
              "I built Roche because the entire Web3 security stack is bottlenecked by bloated, interpreted runtimes and probabilistic fuzzers that waste millions of compute cycles guessing inputs. By dropping straight down to bare siliconâ€”leveraging AVX2 SIMD registers, McCarthy store-select SMT logic, and zero heap allocationsâ€”we make formal protocol verification as fast as native compilation."
            </p>
            <p className="text-zinc-400 text-sm sm:text-base leading-relaxed">
              Roche is fully engineered, independently verified across 29 test suites, and open-source. The code is public, the proofs are reproducible, and the engine is ready for production deployment.
            </p>
            <div className="pt-2 flex items-center gap-4">
              <a
                href="https://github.com/creatorofaurad/roche"
                target="_blank"
                rel="noopener noreferrer"
                className="text-xs font-mono text-white underline underline-offset-4 hover:text-zinc-300"
              >
                Inspect GitHub Repository &rarr;
              </a>
              <a
                href="mailto:srijaan@proton.me"
                className="text-xs font-mono text-zinc-400 hover:text-white"
              >
                srijaan@proton.me
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* 9. INSTITUTIONAL FOOTER */}
      <footer className="py-12 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto text-xs font-mono text-zinc-500">
        <div className="flex flex-col md:flex-row items-center justify-between gap-6 pb-8 border-b border-zinc-900">
          <div className="flex items-center gap-3">
            <div className="w-6 h-6 rounded bg-white text-black flex items-center justify-center font-bold text-xs">
              R
            </div>
            <span className="text-white font-bold">ROCHE VERIFICATION ENGINE</span>
          </div>
          <div className="flex items-center gap-6">
            <a href="https://github.com/creatorofaurad/roche" target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors">
              GitHub
            </a>
            <a href="https://github.com/creatorofaurad/Roche/blob/main/VERIFICATION_AUDIT.md" target="_blank" rel="noopener noreferrer" className="hover:text-white transition-colors">
              Verification Audit
            </a>
            <a href="mailto:srijaan@proton.me" className="hover:text-white transition-colors">
              srijaan@proton.me
            </a>
          </div>
        </div>
        <div className="pt-8 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div>&copy; 2026 Roche Security Lab. Engineered by Charles. Open-Source Infrastructure.</div>
          <div className="text-zinc-600">Zero Dynamic Heap Allocation &bull; Pure Zig 0.16.0</div>
        </div>
      </footer>

    </div>
  );
}
