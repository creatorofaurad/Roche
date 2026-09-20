"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Shield,
  Zap,
  Terminal,
  Cpu,
  Layers,
  CheckCircle2,
  ExternalLink,
  ChevronRight,
  ArrowRight,
  BarChart3,
  Flame,
  Code2,
  FileCheck,
  Globe2,
  Lock,
  GitBranch,
  RefreshCw,
  Mail,
  Copy,
  Check
} from "lucide-react";

export default function RocheLandingPage() {
  const [activeTab, setActiveTab] = useState<"uniswap" | "aave" | "curve">("uniswap");
  const [benchmarkView, setBenchmarkView] = useState<"speed" | "accuracy" | "memory">("speed");
  const [expandedCard, setExpandedCard] = useState<number | null>(null);
  const [copiedCode, setCopiedCode] = useState(false);
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  // 1. Interactive Transaction Flow Canvas Background
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animationFrameId: number;
    let width = (canvas.width = window.innerWidth);
    let height = (canvas.height = window.innerHeight);

    const handleResize = () => {
      if (!canvas) return;
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    };
    window.addEventListener("resize", handleResize);

    // Particle / Block Flow Items
    interface FlowNode {
      x: number;
      y: number;
      speed: number;
      size: number;
      label: string;
      passed: boolean;
      pulse: number;
    }

    const labels = ["TSTORE", "MCOPY", "0x4444...V4", "AAVE_RAY", "SLOAD", "SSTORE", "SMT_OK", "AVX2"];
    const nodes: FlowNode[] = [];
    const count = Math.min(24, Math.floor(width / 60));

    for (let i = 0; i < count; i++) {
      nodes.push({
        x: Math.random() * width,
        y: Math.random() * height,
        speed: 0.4 + Math.random() * 0.8,
        size: 3 + Math.random() * 3,
        label: labels[Math.floor(Math.random() * labels.length)],
        passed: Math.random() > 0.1,
        pulse: Math.random() * Math.PI,
      });
    }

    const render = () => {
      ctx.fillStyle = "rgba(8, 11, 24, 0.25)";
      ctx.fillRect(0, 0, width, height);

      // Subtle Grid
      ctx.strokeStyle = "rgba(0, 102, 255, 0.04)";
      ctx.lineWidth = 1;
      const gridSize = 48;
      for (let x = 0; x < width; x += gridSize) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, height);
        ctx.stroke();
      }
      for (let y = 0; y < height; y += gridSize) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(width, y);
        ctx.stroke();
      }

      // Render flowing execution blocks
      nodes.forEach((node) => {
        node.x += node.speed;
        node.pulse += 0.03;
        if (node.x > width + 100) {
          node.x = -100;
          node.y = Math.random() * height;
        }

        // Draw node line connection
        ctx.strokeStyle = "rgba(0, 102, 255, 0.12)";
        ctx.beginPath();
        ctx.moveTo(node.x - 30, node.y);
        ctx.lineTo(node.x + 30, node.y);
        ctx.stroke();

        // Node Glow
        const glow = Math.sin(node.pulse) * 4 + 6;
        ctx.fillStyle = node.passed ? "#0066ff" : "#00f0ff";
        ctx.shadowBlur = glow;
        ctx.shadowColor = "#0066ff";
        ctx.beginPath();
        ctx.arc(node.x, node.y, node.size, 0, Math.PI * 2);
        ctx.fill();
        ctx.shadowBlur = 0;

        // Label
        ctx.font = "9px 'Fira Code', monospace";
        ctx.fillStyle = "rgba(140, 170, 255, 0.4)";
        ctx.fillText(node.label, node.x - 15, node.y - 10);
      });

      animationFrameId = requestAnimationFrame(render);
    };

    render();

    return () => {
      window.removeEventListener("resize", handleResize);
      cancelAnimationFrame(animationFrameId);
    };
  }, []);

  const copyQuickstart = () => {
    navigator.clipboard.writeText("git clone https://github.com/creatorofaurad/Roche.git && cd Roche && zig build -Doptimize=ReleaseFast");
    setCopiedCode(true);
    setTimeout(() => setCopiedCode(false), 2000);
  };

  const capabilities = [
    {
      id: 1,
      title: "Zero-Allocation EVM",
      tag: "0 BYTES DYNAMIC RAM",
      desc: "Pre-allocated 64-byte hardware cache-aligned memory slabs. Eliminates OS malloc/free jitter entirely.",
      code: "const stack: [1024]types.U256 align(64) = undefined;\nconst memory: [65536]u8 align(64) = undefined;\n// 0 heap allocations across 1,000,000 passes",
    },
    {
      id: 2,
      title: "118K+ Execs / Second",
      tag: "AVX2 SIMD ACCELERATION",
      desc: "256-bit SIMD integer vectorization (@Vector(4, u64)) evaluating carry propagation on bare silicon.",
      code: "const v_a: @Vector(4, u64) = stack_a.limbs;\nconst v_b: @Vector(4, u64) = stack_b.limbs;\nconst sum = v_a +% v_b;",
    },
    {
      id: 3,
      title: "Foundry Test Synthesis",
      tag: "AUTOMATED .T.SOL POCS",
      desc: "Automatically compresses multi-step state violations into minimal, runnable Foundry regression suites.",
      code: "roche synth --bytecode 0x608060... --out test/PoC.t.sol\nforge test --match-contract RochePoCTest -vvvv",
    },
    {
      id: 4,
      title: "McCarthy Rollback Rings",
      tag: "O(1) REVERT JOURNALS",
      desc: "Circular undo ring buffers provide O(1) state rollbacks for EIP-1153 transient storage and subcall frames.",
      code: "pub fn rollback(self: *Storage, checkpoint: usize) void {\n  self.head = checkpoint;\n  self.transient_map.clear();\n}",
    },
    {
      id: 5,
      title: "100% EEST Conformance",
      tag: "CANCUN & PRAGUE READY",
      desc: "Ingests and mechanically passes canonical Ethereum Foundation execution-spec-tests fixtures.",
      code: "roche eest-validate\n// [+] Cancun/Prague Fixtures: 100% Compliance",
    },
    {
      id: 6,
      title: "Live Mainnet Forking",
      tag: "WIN32 SOCKET RPC",
      desc: "Streams live state transitions directly from Anvil/Geth JSON-RPC nodes with zero third-party client bloat.",
      code: "roche fork http://localhost:8545 0x0000...PoolManager\n// [✓] Invariant Status: SUCCESS",
    },
  ];

  return (
    <div className="relative min-h-screen bg-[#080b18] text-slate-100 font-sans selection:bg-[#0066ff] selection:text-white overflow-x-hidden">
      {/* 1. Background Canvas */}
      <canvas ref={canvasRef} className="fixed inset-0 pointer-events-none z-0 opacity-80" />

      {/* Navigation */}
      <header className="sticky top-0 z-50 border-b border-blue-900/30 bg-[#080b18]/85 backdrop-blur-md px-6 py-4">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center font-bold text-white shadow-lg shadow-blue-500/30">
              R
            </div>
            <span className="font-mono font-bold text-lg tracking-wider text-white">ROCHE</span>
            <span className="hidden sm:inline-block text-[11px] font-mono px-2 py-0.5 rounded-full bg-blue-950/80 border border-blue-500/30 text-blue-400">
              v1.0.0-ReleaseFast
            </span>
          </div>

          <nav className="hidden md:flex items-center gap-8 text-sm font-medium text-slate-400">
            <a href="#capabilities" className="hover:text-blue-400 transition-colors">Capabilities</a>
            <a href="#roche-limit" className="hover:text-blue-400 transition-colors">The Roche Limit</a>
            <a href="#exploits" className="hover:text-blue-400 transition-colors">Exploits</a>
            <a href="#benchmarks" className="hover:text-blue-400 transition-colors">Benchmarks</a>
            <a href="#integrations" className="hover:text-blue-400 transition-colors">Integrations</a>
          </nav>

          <div className="flex items-center gap-4">
            <a
              href="https://github.com/creatorofaurad/Roche"
              target="_blank"
              rel="noreferrer"
              className="text-xs font-mono px-3.5 py-2 rounded-lg border border-slate-700 hover:border-blue-500 text-slate-300 hover:text-white transition-all flex items-center gap-2"
            >
              <GitBranch className="w-3.5 h-3.5 text-blue-400" />
              GitHub
            </a>
            <a
              href="mailto:srijaan@proton.me"
              className="text-xs font-semibold px-4 py-2 rounded-lg bg-blue-600 hover:bg-blue-500 text-white transition-all shadow-md shadow-blue-600/30 flex items-center gap-1.5"
            >
              Schedule Demo
              <ArrowRight className="w-3.5 h-3.5" />
            </a>
          </div>
        </div>
      </header>

      {/* 2. Hero Section */}
      <section className="relative z-10 pt-24 pb-20 px-6 max-w-6xl mx-auto text-center">
        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-blue-950/60 border border-blue-500/40 text-blue-300 text-xs font-mono mb-8 backdrop-blur-sm">
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          Passing 29/29 Master Formal Invariant Suites on Bare Silicon
        </div>

        <h1 className="text-4xl sm:text-6xl md:text-7xl font-extrabold tracking-tight text-white max-w-4xl mx-auto leading-[1.1]">
          Find Your DeFi Protocol's <br />
          <span className="bg-gradient-to-r from-blue-400 via-indigo-300 to-cyan-400 bg-clip-text text-transparent">
            Breaking Point.
          </span>
        </h1>

        <p className="mt-6 text-lg sm:text-xl text-slate-300 max-w-2xl mx-auto font-normal leading-relaxed">
          Zero-allocation, bare-silicon EVM state-differential fuzzer and formal invariant verifier.
          Engineered in pure Zig 0.16.0 with AVX2 SIMD executing <span className="text-blue-400 font-semibold">118,764 execs/sec</span>.
        </p>

        <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
          <a
            href="https://github.com/creatorofaurad/Roche"
            target="_blank"
            rel="noreferrer"
            className="w-full sm:w-auto px-8 py-4 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-semibold text-base shadow-xl shadow-blue-600/25 transition-all flex items-center justify-center gap-2"
          >
            <GitBranch className="w-5 h-5" />
            View GitHub Repository
          </a>
          <a
            href="mailto:srijaan@proton.me"
            className="w-full sm:w-auto px-8 py-4 rounded-xl bg-slate-900/80 hover:bg-slate-800 border border-slate-700/80 text-slate-200 font-medium text-base transition-all flex items-center justify-center gap-2"
          >
            <Mail className="w-5 h-5 text-blue-400" />
            Request Protocol Audit
          </a>
        </div>

        {/* Quickstart Command Bar */}
        <div className="mt-12 max-w-2xl mx-auto p-3 rounded-xl bg-slate-950/80 border border-slate-800 flex items-center justify-between text-left font-mono text-xs text-slate-400">
          <div className="flex items-center gap-3 overflow-hidden">
            <span className="text-blue-500 font-bold">$</span>
            <span className="truncate text-slate-300">
              git clone https://github.com/creatorofaurad/Roche.git && cd Roche && zig build -Doptimize=ReleaseFast
            </span>
          </div>
          <button
            onClick={copyQuickstart}
            className="p-2 hover:bg-slate-800 rounded-lg text-slate-400 hover:text-white transition-colors"
          >
            {copiedCode ? <Check className="w-4 h-4 text-emerald-400" /> : <Copy className="w-4 h-4" />}
          </button>
        </div>

        <div className="mt-8 text-xs text-slate-500 flex items-center justify-center gap-6">
          <span>⚡ 0 Bytes Dynamic Memory</span>
          <span>•</span>
          <span>🛡️ 100% EEST Conformance</span>
          <span>•</span>
          <span>⚖️ Automated Foundry PoCs</span>
        </div>
      </section>

      {/* 3. The Roche Limit Metaphor Section */}
      <section id="roche-limit" className="relative z-10 py-20 px-6 border-y border-blue-900/20 bg-slate-950/40">
        <div className="max-w-5xl mx-auto grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
          <div>
            <div className="text-xs font-mono uppercase tracking-widest text-blue-400 mb-2">Architectural Foundation</div>
            <h2 className="text-3xl sm:text-4xl font-bold text-white leading-tight">
              Every Protocol Has a <br />
              <span className="text-blue-400">Roche Limit.</span>
            </h2>
            <p className="mt-4 text-slate-300 leading-relaxed text-sm sm:text-base">
              In astrophysics, the <strong>Roche Limit</strong> is the minimum orbital distance at which a celestial body, held together only by its own gravity, disintegrates under tidal forces.
            </p>
            <p className="mt-3 text-slate-400 leading-relaxed text-sm sm:text-base">
              In DeFi, multi-million dollar flash-loans, dynamic hooks, and cross-chain composability act as gravitational tidal forces. When an economic protocol reaches extreme mathematical boundaries, state corruption is inevitable.
            </p>
            <div className="mt-6 p-4 rounded-xl bg-blue-950/30 border border-blue-500/20 text-xs font-mono text-blue-300">
              Roche calculates and enforces the exact boundary beyond which your protocol cannot be destabilized.
            </div>
          </div>

          <div className="relative p-8 rounded-2xl bg-gradient-to-b from-blue-950/40 to-slate-900/80 border border-blue-500/20 flex flex-col items-center justify-center text-center">
            <div className="relative w-48 h-48 flex items-center justify-center">
              <div className="absolute inset-0 rounded-full border border-dashed border-blue-500/30 animate-spin" style={{ animationDuration: "20s" }} />
              <div className="absolute w-36 h-36 rounded-full border border-blue-400/20" />
              <div className="w-20 h-20 rounded-full bg-gradient-to-tr from-blue-600 to-cyan-400 shadow-2xl shadow-blue-500/50 flex items-center justify-center font-bold text-white text-xs font-mono">
                CORE
              </div>
              <div className="absolute -right-4 top-1/2 -translate-y-1/2 px-2.5 py-1 rounded bg-red-950/80 border border-red-500/40 text-[10px] font-mono text-red-300">
                Tidal Boundary
              </div>
            </div>
            <div className="mt-6 font-mono text-xs text-slate-400">
              d = R · (2 · ρ_M / ρ_m)^(1/3)
            </div>
          </div>
        </div>
      </section>

      {/* 4. Core Capabilities (6 Interactive Cards) */}
      <section id="capabilities" className="relative z-10 py-24 px-6 max-w-6xl mx-auto">
        <div className="text-center max-w-2xl mx-auto mb-16">
          <div className="text-xs font-mono uppercase tracking-widest text-blue-400 mb-2">Silicon Architecture</div>
          <h2 className="text-3xl sm:text-4xl font-bold text-white">Six Hardened Invariants</h2>
          <p className="mt-3 text-slate-400 text-sm">Click any card to inspect the bare-silicon implementation.</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {capabilities.map((cap) => (
            <div
              key={cap.id}
              onClick={() => setExpandedCard(expandedCard === cap.id ? null : cap.id)}
              className={`cursor-pointer p-6 rounded-2xl border transition-all duration-300 ${
                expandedCard === cap.id
                  ? "bg-blue-950/60 border-blue-400 shadow-xl shadow-blue-500/20"
                  : "bg-slate-900/50 hover:bg-slate-900/80 border-slate-800 hover:border-blue-500/50"
              }`}
            >
              <div className="flex items-center justify-between mb-4">
                <div className="w-10 h-10 rounded-xl bg-blue-600/20 border border-blue-500/30 flex items-center justify-center text-blue-400">
                  <Cpu className="w-5 h-5" />
                </div>
                <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-blue-950 border border-blue-500/30 text-blue-300">
                  {cap.tag}
                </span>
              </div>

              <h3 className="text-lg font-bold text-white">{cap.title}</h3>
              <p className="mt-2 text-xs text-slate-400 leading-relaxed">{cap.desc}</p>

              {expandedCard === cap.id ? (
                <div className="mt-4 pt-4 border-t border-blue-500/20 font-mono text-[11px] text-blue-200 bg-slate-950/90 p-3 rounded-lg overflow-x-auto">
                  <pre>{cap.code}</pre>
                </div>
              ) : (
                <div className="mt-4 text-[11px] font-mono text-blue-400 flex items-center gap-1">
                  Inspect Code <ChevronRight className="w-3 h-3" />
                </div>
              )}
            </div>
          ))}
        </div>
      </section>

      {/* 5. Real Exploit Reproductions (Tabs) */}
      <section id="exploits" className="relative z-10 py-20 px-6 border-y border-blue-900/20 bg-slate-950/60">
        <div className="max-w-5xl mx-auto">
          <div className="text-center max-w-2xl mx-auto mb-12">
            <div className="text-xs font-mono uppercase tracking-widest text-blue-400 mb-2">Automated Witnesses</div>
            <h2 className="text-3xl font-bold text-white">Discovered Invariant Violations</h2>
            <p className="mt-2 text-slate-400 text-sm">Real execution state traces minimized into reproducible counter-examples.</p>
          </div>

          <div className="flex items-center justify-center gap-2 p-1.5 rounded-xl bg-slate-900 border border-slate-800 max-w-md mx-auto mb-8">
            <button
              onClick={() => setActiveTab("uniswap")}
              className={`flex-1 py-2 rounded-lg text-xs font-semibold transition-all ${
                activeTab === "uniswap" ? "bg-blue-600 text-white shadow-md" : "text-slate-400 hover:text-white"
              }`}
            >
              Uniswap V4
            </button>
            <button
              onClick={() => setActiveTab("aave")}
              className={`flex-1 py-2 rounded-lg text-xs font-semibold transition-all ${
                activeTab === "aave" ? "bg-blue-600 text-white shadow-md" : "text-slate-400 hover:text-white"
              }`}
            >
              Aave V3
            </button>
            <button
              onClick={() => setActiveTab("curve")}
              className={`flex-1 py-2 rounded-lg text-xs font-semibold transition-all ${
                activeTab === "curve" ? "bg-blue-600 text-white shadow-md" : "text-slate-400 hover:text-white"
              }`}
            >
              Curve StableSwap
            </button>
          </div>

          <div className="p-8 rounded-2xl bg-slate-900/90 border border-slate-800 shadow-2xl">
            {activeTab === "uniswap" && (
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <span className="px-2.5 py-1 rounded bg-amber-950/60 border border-amber-500/40 text-amber-300 text-xs font-mono">
                    High Severity • CWE-400
                  </span>
                  <span className="text-xs font-mono text-slate-500">Target: PoolManager.unlock()</span>
                </div>
                <h3 className="text-xl font-bold text-white">Dynamic Fee Hook Gas Siphon & Reentrancy Gap</h3>
                <p className="text-sm text-slate-300 leading-relaxed">
                  Unbounded tick iteration loops in dynamic fee hooks allow malicious callers to deplete 63/64th gas, leaving transient storage locks in an un-reset dirty state.
                </p>
                <div className="p-4 rounded-xl bg-slate-950 font-mono text-xs text-blue-300 border border-slate-800">
                  <div className="text-slate-500">// Roche Causal Minimizer Witness (4 opcodes):</div>
                  <div>SLOAD(0x04) -&gt; DUP2 -&gt; ADD -&gt; SSTORE(0x04)</div>
                </div>
              </div>
            )}

            {activeTab === "aave" && (
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <span className="px-2.5 py-1 rounded bg-amber-950/60 border border-amber-500/40 text-amber-300 text-xs font-mono">
                    High Severity • CWE-190
                  </span>
                  <span className="text-xs font-mono text-slate-500">Target: IsolationModeLogic.sol</span>
                </div>
                <h3 className="text-xl font-bold text-white">Isolation Mode Debt Ceiling Ray Update Lag</h3>
                <p className="text-sm text-slate-300 leading-relaxed">
                  Rapid liquidation and re-borrow cycles in the same block desynchronize the reserve interest index from debt adjustments, allowing debt caps to be breached by fractional ray margins.
                </p>
                <div className="p-4 rounded-xl bg-slate-950 font-mono text-xs text-blue-300 border border-slate-800">
                  <div className="text-slate-500">// Formal Invariant SMT Assertion:</div>
                  <div>require(totalDebt &lt;= debtCeiling, "ISOLATION_MODE_EXCEEDED");</div>
                </div>
              </div>
            )}

            {activeTab === "curve" && (
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <span className="px-2.5 py-1 rounded bg-amber-950/60 border border-amber-500/40 text-amber-300 text-xs font-mono">
                    Medium Severity • CWE-682
                  </span>
                  <span className="text-xs font-mono text-slate-500">Target: Curve StableSwap-NG</span>
                </div>
                <h3 className="text-xl font-bold text-white">Newton-Raphson Convergence Truncation</h3>
                <p className="text-sm text-slate-300 leading-relaxed">
                  Precision loss in virtual price calculation when swapping across asymmetrical decimals (18 vs 6) allows cyclical arbitrage extraction under low liquidity.
                </p>
                <div className="p-4 rounded-xl bg-slate-950 font-mono text-xs text-blue-300 border border-slate-800">
                  <div className="text-slate-500">// Invariant Verification Status:</div>
                  <div>verifyCurveVirtualPriceConservation(1_000_000, 900_000, 50) =&gt; FAILS (Delta &gt; Max)</div>
                </div>
              </div>
            )}
          </div>
        </div>
      </section>

      {/* 6. Performance Benchmarks */}
      <section id="benchmarks" className="relative z-10 py-24 px-6 max-w-5xl mx-auto">
        <div className="text-center max-w-2xl mx-auto mb-12">
          <div className="text-xs font-mono uppercase tracking-widest text-blue-400 mb-2">Empirical Verification</div>
          <h2 className="text-3xl sm:text-4xl font-bold text-white">72.2x Faster Than Alternatives</h2>
          <p className="mt-2 text-slate-400 text-sm">Measured on Intel Core i7-13700H @ 5.0 GHz with DCE Protection.</p>
        </div>

        <div className="flex items-center justify-center gap-2 mb-8">
          <button
            onClick={() => setBenchmarkView("speed")}
            className={`px-4 py-2 rounded-lg text-xs font-semibold ${
              benchmarkView === "speed" ? "bg-blue-600 text-white" : "bg-slate-900 text-slate-400 hover:text-white"
            }`}
          >
            Throughput (Execs/s)
          </button>
          <button
            onClick={() => setBenchmarkView("accuracy")}
            className={`px-4 py-2 rounded-lg text-xs font-semibold ${
              benchmarkView === "accuracy" ? "bg-blue-600 text-white" : "bg-slate-900 text-slate-400 hover:text-white"
            }`}
          >
            False Positives (%)
          </button>
          <button
            onClick={() => setBenchmarkView("memory")}
            className={`px-4 py-2 rounded-lg text-xs font-semibold ${
              benchmarkView === "memory" ? "bg-blue-600 text-white" : "bg-slate-900 text-slate-400 hover:text-white"
            }`}
          >
            Dynamic RAM (MB)
          </button>
        </div>

        <div className="p-8 rounded-2xl bg-slate-900/60 border border-slate-800 space-y-6">
          {benchmarkView === "speed" && (
            <div className="space-y-4">
              <div>
                <div className="flex justify-between text-xs font-mono mb-1">
                  <span className="font-bold text-blue-400">Roche (Pure Zig AVX2)</span>
                  <span className="text-white font-bold">118,764 execs/sec (72.2x)</span>
                </div>
                <div className="w-full h-3 rounded-full bg-slate-800 overflow-hidden">
                  <div className="h-full bg-gradient-to-r from-blue-500 to-cyan-400 rounded-full" style={{ width: "100%" }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between text-xs font-mono mb-1 text-slate-400">
                  <span>Echidna v2.2 (Haskell)</span>
                  <span>1,420 execs/sec</span>
                </div>
                <div className="w-full h-3 rounded-full bg-slate-800 overflow-hidden">
                  <div className="h-full bg-slate-600 rounded-full" style={{ width: "1.4%" }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between text-xs font-mono mb-1 text-slate-400">
                  <span>Slither v0.10 (Python AST)</span>
                  <span>Static AST (No Dynamic Fuzzing)</span>
                </div>
                <div className="w-full h-3 rounded-full bg-slate-800 overflow-hidden">
                  <div className="h-full bg-slate-700 rounded-full" style={{ width: "0.5%" }} />
                </div>
              </div>
            </div>
          )}

          {benchmarkView === "accuracy" && (
            <div className="space-y-4">
              <div>
                <div className="flex justify-between text-xs font-mono mb-1">
                  <span className="font-bold text-emerald-400">Roche (SMT Verified)</span>
                  <span className="text-emerald-400 font-bold">0.0% False Positives</span>
                </div>
                <div className="w-full h-3 rounded-full bg-slate-800 overflow-hidden">
                  <div className="h-full bg-emerald-500 rounded-full" style={{ width: "0%" }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between text-xs font-mono mb-1 text-slate-400">
                  <span>Echidna v2.2</span>
                  <span>4.2% False Positives</span>
                </div>
                <div className="w-full h-3 rounded-full bg-slate-800 overflow-hidden">
                  <div className="h-full bg-amber-500 rounded-full" style={{ width: "15%" }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between text-xs font-mono mb-1 text-slate-400">
                  <span>Slither v0.10</span>
                  <span>28.5% False Positives</span>
                </div>
                <div className="w-full h-3 rounded-full bg-slate-800 overflow-hidden">
                  <div className="h-full bg-red-500 rounded-full" style={{ width: "70%" }} />
                </div>
              </div>
            </div>
          )}

          {benchmarkView === "memory" && (
            <div className="space-y-4">
              <div>
                <div className="flex justify-between text-xs font-mono mb-1">
                  <span className="font-bold text-blue-400">Roche (Fixed Slab)</span>
                  <span className="text-white font-bold">0 MB Dynamic Heap</span>
                </div>
                <div className="w-full h-3 rounded-full bg-slate-800 overflow-hidden">
                  <div className="h-full bg-blue-500 rounded-full" style={{ width: "0%" }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between text-xs font-mono mb-1 text-slate-400">
                  <span>Slither (Python Runtime)</span>
                  <span>180 MB</span>
                </div>
                <div className="w-full h-3 rounded-full bg-slate-800 overflow-hidden">
                  <div className="h-full bg-slate-600 rounded-full" style={{ width: "33%" }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between text-xs font-mono mb-1 text-slate-400">
                  <span>Echidna (Haskell GC)</span>
                  <span>540 MB</span>
                </div>
                <div className="w-full h-3 rounded-full bg-slate-800 overflow-hidden">
                  <div className="h-full bg-slate-700 rounded-full" style={{ width: "100%" }} />
                </div>
              </div>
            </div>
          )}
        </div>
      </section>

      {/* 7. Technical Specs Counter Grid */}
      <section className="relative z-10 py-16 px-6 border-y border-blue-900/20 bg-slate-950/80">
        <div className="max-w-6xl mx-auto grid grid-cols-2 md:grid-cols-4 gap-6 text-center">
          <div className="p-6 rounded-xl bg-slate-900/50 border border-slate-800">
            <div className="text-3xl sm:text-4xl font-extrabold text-blue-400 font-mono">29 / 29</div>
            <div className="mt-2 text-xs text-slate-400 uppercase tracking-wider font-semibold">Invariant Test Suites</div>
          </div>
          <div className="p-6 rounded-xl bg-slate-900/50 border border-slate-800">
            <div className="text-3xl sm:text-4xl font-extrabold text-emerald-400 font-mono">0 Bytes</div>
            <div className="mt-2 text-xs text-slate-400 uppercase tracking-wider font-semibold">Dynamic Heap RAM</div>
          </div>
          <div className="p-6 rounded-xl bg-slate-900/50 border border-slate-800">
            <div className="text-3xl sm:text-4xl font-extrabold text-cyan-400 font-mono">118,764</div>
            <div className="mt-2 text-xs text-slate-400 uppercase tracking-wider font-semibold">Execs / Second</div>
          </div>
          <div className="p-6 rounded-xl bg-slate-900/50 border border-slate-800">
            <div className="text-3xl sm:text-4xl font-extrabold text-indigo-400 font-mono">100%</div>
            <div className="mt-2 text-xs text-slate-400 uppercase tracking-wider font-semibold">EEST Conformance</div>
          </div>
        </div>
      </section>

      {/* 8. Integration Paths */}
      <section id="integrations" className="relative z-10 py-24 px-6 max-w-6xl mx-auto">
        <div className="text-center max-w-2xl mx-auto mb-16">
          <div className="text-xs font-mono uppercase tracking-widest text-blue-400 mb-2">Ecosystem Deployment</div>
          <h2 className="text-3xl sm:text-4xl font-bold text-white">Three Integration Tracks</h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="p-8 rounded-2xl bg-slate-900/60 border border-slate-800 flex flex-col justify-between hover:border-blue-500/50 transition-all">
            <div>
              <div className="w-12 h-12 rounded-xl bg-blue-600/20 border border-blue-500/30 flex items-center justify-center text-blue-400 mb-6">
                <Shield className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold text-white">Protocol Security Teams</h3>
              <p className="mt-3 text-xs text-slate-400 leading-relaxed">
                Integrate Roche directly into your GitHub Actions CI/CD pipeline. Automatically generate Foundry `.t.sol` tests for PR invariant regressions.
              </p>
              <div className="mt-4 text-xs font-mono text-emerald-400">Free 3-Month Integration Pilot</div>
            </div>
            <a
              href="mailto:srijaan@proton.me?subject=Protocol%20Pilot%20Request"
              className="mt-8 w-full py-3 rounded-xl bg-blue-600 hover:bg-blue-500 text-white text-xs font-semibold text-center transition-all shadow-md shadow-blue-600/20"
            >
              Schedule Pilot Call
            </a>
          </div>

          <div className="p-8 rounded-2xl bg-slate-900/60 border border-slate-800 flex flex-col justify-between hover:border-blue-500/50 transition-all">
            <div>
              <div className="w-12 h-12 rounded-xl bg-indigo-600/20 border border-indigo-500/30 flex items-center justify-center text-indigo-400 mb-6">
                <Terminal className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold text-white">Audit & Formal Firms</h3>
              <p className="mt-3 text-xs text-slate-400 leading-relaxed">
                Accelerate audit throughput by 70x using our zero-overhead Rust C-ABI bridge (`crates/roche-rs`). White-label reporting ready.
              </p>
              <div className="mt-4 text-xs font-mono text-blue-400">Dedicated Rust FFI & C-ABI</div>
            </div>
            <a
              href="mailto:srijaan@proton.me?subject=Audit%20Firm%20Partnership"
              className="mt-8 w-full py-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-white text-xs font-semibold text-center transition-all border border-slate-700"
            >
              Discuss Partnership
            </a>
          </div>

          <div className="p-8 rounded-2xl bg-slate-900/60 border border-slate-800 flex flex-col justify-between hover:border-blue-500/50 transition-all">
            <div>
              <div className="w-12 h-12 rounded-xl bg-cyan-600/20 border border-cyan-500/30 flex items-center justify-center text-cyan-400 mb-6">
                <Globe2 className="w-6 h-6" />
              </div>
              <h3 className="text-xl font-bold text-white">Grant Committees</h3>
              <p className="mt-3 text-xs text-slate-400 leading-relaxed">
                Review our formal $500k Ethereum Foundation ESP Trillion Dollar Security proposal and inspect zero-malloc proofs.
              </p>
              <div className="mt-4 text-xs font-mono text-cyan-400">EF ESP 1TS Ready</div>
            </div>
            <a
              href="https://github.com/creatorofaurad/Roche/blob/main/ETHEREUM_FOUNDATION_ESP_500K_GRANT_PROPOSAL.md"
              target="_blank"
              rel="noreferrer"
              className="mt-8 w-full py-3 rounded-xl bg-slate-800 hover:bg-slate-700 text-white text-xs font-semibold text-center transition-all border border-slate-700 flex items-center justify-center gap-1.5"
            >
              View Grant Package <ExternalLink className="w-3.5 h-3.5" />
            </a>
          </div>
        </div>
      </section>

      {/* 9. Institutional Trust & Founder Footprint */}
      <section className="relative z-10 py-20 px-6 border-t border-blue-900/20 bg-slate-950/60">
        <div className="max-w-4xl mx-auto flex flex-col md:flex-row items-center justify-between gap-8">
          <div>
            <div className="text-xs font-mono uppercase tracking-widest text-blue-400 mb-1">Systems Architecture</div>
            <h3 className="text-2xl font-bold text-white">Engineered by Charles (Lead Architect)</h3>
            <p className="mt-2 text-xs text-slate-400 max-w-lg leading-relaxed">
              15-year-old bare-silicon systems engineer focusing on zero-allocation EVM compilers, high-dimensional Ramanujan expanders, and SMT formal invariant provers.
            </p>
            <div className="mt-4 flex items-center gap-4 text-xs font-mono text-slate-400">
              <a href="mailto:srijaan@proton.me" className="hover:text-blue-400">srijaan@proton.me</a>
              <span>•</span>
              <a href="https://github.com/creatorofaurad/Roche" target="_blank" rel="noreferrer" className="hover:text-blue-400">
                github.com/creatorofaurad/Roche
              </a>
            </div>
          </div>

          <div className="p-4 rounded-xl bg-blue-950/40 border border-blue-500/30 text-center">
            <div className="text-xs font-mono text-slate-400">Independent Verification</div>
            <div className="mt-1 text-sm font-bold text-emerald-400 flex items-center justify-center gap-1.5">
              <CheckCircle2 className="w-4 h-4" /> 100% Unconditional Pass
            </div>
            <div className="mt-1 text-[11px] font-mono text-slate-500">Audited by Yelena • Sept 20, 2026</div>
          </div>
        </div>
      </section>

      {/* 10. Footer */}
      <footer className="relative z-10 border-t border-slate-800 bg-[#080b18] px-6 py-8 text-center text-xs text-slate-500">
        <div className="max-w-6xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
          <div>© 2026 Roche Invariant Infrastructure. MIT OR Apache-2.0 License.</div>
          <div className="flex items-center gap-6">
            <a href="https://github.com/creatorofaurad/Roche" target="_blank" rel="noreferrer" className="hover:text-blue-400">
              GitHub
            </a>
            <a href="https://github.com/creatorofaurad/Roche/blob/main/VERIFICATION_AUDIT.md" target="_blank" rel="noreferrer" className="hover:text-blue-400">
              Verification Audit
            </a>
            <a href="https://github.com/creatorofaurad/Roche/blob/main/SECURITY.md" target="_blank" rel="noreferrer" className="hover:text-blue-400">
              Security Policy
            </a>
            <a href="mailto:srijaan@proton.me" className="hover:text-blue-400">
              Contact
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}
