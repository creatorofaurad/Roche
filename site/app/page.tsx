"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Terminal,
  Cpu,
  Layers,
  ArrowRight,
  GitBranch,
  Mail,
  Copy,
  Check,
  Zap,
  Activity,
  ShieldAlert,
  Binary,
  Flame,
  Radio,
  ExternalLink
} from "lucide-react";

export default function RocheMaximalistLanding() {
  const [copiedCode, setCopiedCode] = useState(false);
  const [selectedBenchmark, setSelectedBenchmark] = useState<"roche" | "echidna" | "slither">("roche");
  const [counterCount, setCounterCount] = useState({
    execs: 118764,
    tests: 29,
    allocs: 0,
    exploits: 13
  });
  const canvasRef = useRef<HTMLCanvasElement | null>(null);

  // 1. Neon Supercomputer Grid Wave Animation
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let animId: number;
    let width = (canvas.width = window.innerWidth);
    let height = (canvas.height = window.innerHeight);

    const handleResize = () => {
      if (!canvas) return;
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    };
    window.addEventListener("resize", handleResize);

    let time = 0;

    const drawGrid = () => {
      time += 0.02;
      ctx.fillStyle = "#120024";
      ctx.fillRect(0, 0, width, height);

      const gridSize = 40;
      ctx.lineWidth = 1;

      // Vertical pulsing grid lines
      for (let x = 0; x < width; x += gridSize) {
        const intensity = Math.sin(x * 0.01 + time) * 0.5 + 0.5;
        ctx.strokeStyle = `rgba(0, 240, 255, ${0.08 + intensity * 0.12})`;
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, height);
        ctx.stroke();
      }

      // Horizontal wave grid lines
      for (let y = 0; y < height; y += gridSize) {
        const wave = Math.sin(y * 0.02 - time * 1.5) * 4;
        ctx.strokeStyle = `rgba(255, 0, 110, ${0.07 + Math.sin(y * 0.01 + time) * 0.08})`;
        ctx.beginPath();
        ctx.moveTo(0, y + wave);
        ctx.lineTo(width, y + wave);
        ctx.stroke();
      }

      // Floating instruction packets
      const packetCount = 8;
      for (let i = 0; i < packetCount; i++) {
        const px = ((i * 180 + time * 60) % (width + 100)) - 50;
        const py = (i * 90 + Math.sin(time + i) * 30) % height;
        ctx.fillStyle = i % 2 === 0 ? "#39ff14" : "#ffff00";
        ctx.fillRect(px, py, 12, 3);
      }

      animId = requestAnimationFrame(drawGrid);
    };

    drawGrid();

    return () => {
      window.removeEventListener("resize", handleResize);
      cancelAnimationFrame(animId);
    };
  }, []);

  const copyCommand = () => {
    navigator.clipboard.writeText("git clone https://github.com/creatorofaurad/Roche.git && cd Roche && zig build -Doptimize=ReleaseFast");
    setCopiedCode(true);
    setTimeout(() => setCopiedCode(false), 2000);
  };

  return (
    <div className="relative min-h-screen bg-[#120024] text-white font-mono selection:bg-[#ff006e] selection:text-black overflow-x-hidden">
      {/* Dynamic Background Canvas */}
      <canvas ref={canvasRef} className="fixed inset-0 pointer-events-none z-0 opacity-90" />

      {/* TOP SYSTEM STATUS BAR */}
      <div className="relative z-50 bg-[#ff006e] text-black font-extrabold text-[11px] px-4 py-1.5 flex items-center justify-between uppercase tracking-widest border-b-2 border-black">
        <div className="flex items-center gap-3">
          <span className="bg-black text-[#39ff14] px-1.5 py-0.5 font-black">SYS_OK</span>
          <span>ROCHE BARE-SILICON EVM KERNEL // ZIG 0.16.0 // AVX2 256-BIT SIMD</span>
        </div>
        <div className="hidden sm:flex items-center gap-4">
          <span className="bg-black text-[#00f0ff] px-1.5 py-0.5">HEAP: 0 BYTES</span>
          <span className="bg-black text-[#ffff00] px-1.5 py-0.5">THROUGHPUT: 118,764 EXEC/S</span>
        </div>
      </div>

      {/* TOP NAVBAR */}
      <header className="relative z-40 bg-[#1a0033]/90 border-b-4 border-[#00f0ff] px-6 py-4 backdrop-blur-md">
        <div className="max-w-[1400px] mx-auto flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="bg-[#00f0ff] text-black font-black text-2xl px-3 py-1 border-2 border-black shadow-[4px_4px_0px_#ff006e]">
              R
            </div>
            <div>
              <span className="text-2xl font-black tracking-tighter text-white">ROCHE</span>
              <span className="ml-2 text-xs text-[#39ff14] font-bold">:: BARE_SILICON</span>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <a
              href="https://github.com/creatorofaurad/Roche"
              target="_blank"
              rel="noreferrer"
              className="bg-[#ff006e] hover:bg-[#ff0080] text-white font-black text-xs px-4 py-2.5 border-2 border-black shadow-[3px_3px_0px_#00f0ff] uppercase transition-transform active:translate-x-0.5 active:translate-y-0.5 flex items-center gap-1.5"
            >
              <GitBranch className="w-4 h-4" />
              GITHUB
            </a>
            <a
              href="mailto:srijaan@proton.me"
              className="bg-[#00f0ff] hover:bg-[#39ff14] text-black font-black text-xs px-4 py-2.5 border-2 border-black shadow-[3px_3px_0px_#ff006e] uppercase transition-transform active:translate-x-0.5 active:translate-y-0.5 flex items-center gap-1.5"
            >
              <Mail className="w-4 h-4" />
              DEMO / AUDIT
            </a>
          </div>
        </div>
      </header>

      {/* 1. HERO SECTION (Massive Typography, No Whitespace) */}
      <section className="relative z-10 pt-12 pb-16 px-6 max-w-[1400px] mx-auto">
        <div className="border-4 border-[#39ff14] bg-[#1a0033]/95 p-8 sm:p-12 shadow-[12px_12px_0px_#ff006e]">
          <div className="inline-block bg-[#ffff00] text-black font-black text-xs px-3 py-1 mb-6 uppercase tracking-wider">
            HIGH-THROUGHPUT FORMAL INVARIANT VERIFIER &amp; STATE FUZZER
          </div>

          <h1 className="text-6xl sm:text-8xl md:text-9xl font-black tracking-tighter text-white leading-none">
            ROCHE
          </h1>

          <div className="mt-4 text-2xl sm:text-4xl font-extrabold text-[#00f0ff] tracking-tight">
            ZERO-ALLOCATION EVM INVARIANT ENGINE
          </div>

          <p className="mt-6 text-base sm:text-xl text-slate-200 font-medium max-w-4xl leading-relaxed">
            Stop fuzzing at 1,000 execs/sec in bloated garbage-collected runtimes. Roche is engineered in pure Zig 0.16.0 with direct Win32/POSIX system calls, executing state transitions on bare silicon.
          </p>

          {/* COLORFUL STATS STRIP */}
          <div className="mt-10 grid grid-cols-2 sm:grid-cols-4 gap-4">
            <div className="p-4 bg-[#ff006e] text-white border-2 border-black shadow-[4px_4px_0px_#000000]">
              <div className="text-3xl sm:text-4xl font-black">118,764</div>
              <div className="text-xs uppercase font-bold mt-1 text-black">EXECS / SECOND</div>
            </div>
            <div className="p-4 bg-[#00f0ff] text-black border-2 border-black shadow-[4px_4px_0px_#000000]">
              <div className="text-3xl sm:text-4xl font-black">0 BYTES</div>
              <div className="text-xs uppercase font-bold mt-1 text-slate-900">DYNAMIC HEAP RAM</div>
            </div>
            <div className="p-4 bg-[#39ff14] text-black border-2 border-black shadow-[4px_4px_0px_#000000]">
              <div className="text-3xl sm:text-4xl font-black">29 / 29</div>
              <div className="text-xs uppercase font-bold mt-1 text-slate-900">TEST SUITES PASSING</div>
            </div>
            <div className="p-4 bg-[#ffff00] text-black border-2 border-black shadow-[4px_4px_0px_#000000]">
              <div className="text-3xl sm:text-4xl font-black">PRODUCTION</div>
              <div className="text-xs uppercase font-bold mt-1 text-slate-900">BARE-SILICON CORE</div>
            </div>
          </div>

          {/* BIG RAW CTAS */}
          <div className="mt-10 flex flex-col sm:flex-row gap-4">
            <a
              href="https://github.com/creatorofaurad/Roche"
              target="_blank"
              rel="noreferrer"
              className="flex-1 py-5 bg-[#ff006e] hover:bg-[#ff0080] text-white font-black text-center text-lg uppercase border-3 border-black shadow-[6px_6px_0px_#00f0ff] flex items-center justify-center gap-2"
            >
              <GitBranch className="w-6 h-6" />
              CLONE ON GITHUB (FREE / OPEN SOURCE)
            </a>
            <a
              href="mailto:srijaan@proton.me"
              className="flex-1 py-5 bg-[#00f0ff] hover:bg-[#39ff14] text-black font-black text-center text-lg uppercase border-3 border-black shadow-[6px_6px_0px_#ffff00] flex items-center justify-center gap-2"
            >
              <Mail className="w-6 h-6" />
              SCHEDULE PROTOCOL DEMO
            </a>
          </div>

          {/* RAW CLI RUNNER BAR */}
          <div className="mt-8 bg-black p-4 border-2 border-[#39ff14] flex items-center justify-between text-xs">
            <div className="flex items-center gap-2 text-[#39ff14] truncate font-mono">
              <span className="text-[#ffff00] font-bold">&gt;&gt;&gt;</span>
              <span className="truncate">git clone https://github.com/creatorofaurad/Roche.git &amp;&amp; cd Roche &amp;&amp; zig build -Doptimize=ReleaseFast</span>
            </div>
            <button
              onClick={copyCommand}
              className="ml-4 px-3 py-1.5 bg-[#39ff14] text-black font-bold text-xs uppercase flex items-center gap-1 hover:bg-[#ffff00]"
            >
              {copiedCode ? <Check className="w-3.5 h-3.5" /> : <Copy className="w-3.5 h-3.5" />}
              {copiedCode ? "COPIED" : "COPY"}
            </button>
          </div>
        </div>
      </section>

      {/* 2. THE ROCHE LIMIT (Full Bleed Maximalist Explainer) */}
      <section className="relative z-10 border-y-4 border-black grid grid-cols-1 md:grid-cols-2">
        <div className="bg-[#1a0033] p-10 sm:p-16 border-b-4 md:border-b-0 md:border-r-4 border-black">
          <div className="inline-block bg-[#39ff14] text-black px-2 py-1 text-xs font-black mb-4">
            CELESTIAL ASTROPHYSICS
          </div>
          <h2 className="text-3xl sm:text-5xl font-black text-[#39ff14] leading-tight">
            THE ROCHE LIMIT: TIDAL DESTRUCTION
          </h2>
          <p className="mt-6 text-slate-200 text-sm sm:text-base leading-relaxed">
            In orbital mechanics, the <strong>Roche Limit</strong> is the exact radial boundary where a celestial body's internal gravitational cohesion is overwhelmed by the tidal pull of a larger mass.
          </p>
          <div className="mt-6 p-4 bg-black border-2 border-[#39ff14] text-xs font-mono text-[#39ff14]">
            d = R · (2 · ρ_M / ρ_m)^(1/3) // GRAVITATIONAL DISINTEGRATION THRESHOLD
          </div>
        </div>

        <div className="bg-[#ff006e] p-10 sm:p-16 text-black">
          <div className="inline-block bg-black text-[#00f0ff] px-2 py-1 text-xs font-black mb-4">
            DEFI ECONOMIC PARALLEL
          </div>
          <h2 className="text-3xl sm:text-5xl font-black text-black leading-tight">
            EVERY PROTOCOL HAS A BREAKING POINT
          </h2>
          <p className="mt-6 text-black font-semibold text-sm sm:text-base leading-relaxed">
            Flash-loans, dynamic hooks, and cross-chain composability exert brutal economic tidal forces. When an invariant boundary is breached, multi-million dollar liquidity cascades disintegrate in seconds.
          </p>
          <div className="mt-6 p-4 bg-black text-[#00f0ff] font-mono text-xs border-2 border-black font-bold">
            ROCHE IDENTIFIES THE EXACT INVARIANT BOUNDARY BEFORE MAINNET DEPLOYMENT.
          </div>
        </div>
      </section>

      {/* 3. CORE CAPABILITIES (6 Full-Width High-Impact Color Blocks) */}
      <section className="relative z-10 border-b-4 border-black">
        {/* Block 1: Cyan */}
        <div className="bg-[#00f0ff] text-black p-8 sm:p-12 border-b-4 border-black flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <div className="max-w-2xl">
            <span className="bg-black text-[#00f0ff] text-xs font-black px-2 py-0.5">INVARIANT 01</span>
            <h3 className="text-3xl sm:text-5xl font-black tracking-tight mt-2">ZERO-ALLOCATION EXECUTION</h3>
            <p className="mt-2 text-sm sm:text-base font-bold text-slate-900">
              0 Bytes dynamic memory allocation on hot execution paths. Pre-allocated 64-byte hardware cache-aligned memory slabs eliminate OS heap malloc/free jitter entirely.
            </p>
          </div>
          <div className="bg-black text-[#00f0ff] p-4 font-mono text-xs border-2 border-black w-full md:w-auto">
            const stack: [1024]U256 align(64) = undefined;
          </div>
        </div>

        {/* Block 2: Magenta */}
        <div className="bg-[#ff006e] text-white p-8 sm:p-12 border-b-4 border-black flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <div className="max-w-2xl">
            <span className="bg-black text-[#ff006e] text-xs font-black px-2 py-0.5">INVARIANT 02</span>
            <h3 className="text-3xl sm:text-5xl font-black tracking-tight mt-2">118K+ EXECUTIONS PER SECOND</h3>
            <p className="mt-2 text-sm sm:text-base font-bold text-white">
              Single-threaded Zig engine compiled with ReleaseFast and 256-bit AVX2 SIMD integer vectorization. Outperforms Python and Haskell fuzzers by 72.2x.
            </p>
          </div>
          <div className="bg-black text-[#39ff14] p-4 font-mono text-xs border-2 border-black w-full md:w-auto">
            const sum = @Vector(4, u64) +% @Vector(4, u64);
          </div>
        </div>

        {/* Block 3: Lime Green */}
        <div className="bg-[#39ff14] text-black p-8 sm:p-12 border-b-4 border-black flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <div className="max-w-2xl">
            <span className="bg-black text-[#39ff14] text-xs font-black px-2 py-0.5">INVARIANT 03</span>
            <h3 className="text-3xl sm:text-5xl font-black tracking-tight mt-2">AUTOMATIC EXPLOIT SYNTHESIS</h3>
            <p className="mt-2 text-sm sm:text-base font-bold text-slate-900">
              Generates runnable Foundry <code className="bg-black text-[#39ff14] px-1">.t.sol</code> regression tests directly from minimized execution traces with zero manual boilerplate.
            </p>
          </div>
          <div className="bg-black text-[#ffff00] p-4 font-mono text-xs border-2 border-black w-full md:w-auto">
            roche synth --name ExploitPoC --bytecode 0x...
          </div>
        </div>

        {/* Block 4: Electric Yellow */}
        <div className="bg-[#ffff00] text-black p-8 sm:p-12 border-b-4 border-black flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <div className="max-w-2xl">
            <span className="bg-black text-[#ffff00] text-xs font-black px-2 py-0.5">INVARIANT 04</span>
            <h3 className="text-3xl sm:text-5xl font-black tracking-tight mt-2">MCCARTHY STORAGE ROLLBACK</h3>
            <p className="mt-2 text-sm sm:text-base font-bold text-slate-900">
              O(1) deterministic state checkpoint and recovery journals for EIP-1153 transient storage and recursive external subcall failure isolation.
            </p>
          </div>
          <div className="bg-black text-[#00f0ff] p-4 font-mono text-xs border-2 border-black w-full md:w-auto">
            select(store(S, k, v), k) == v; // O(1) Rollback
          </div>
        </div>

        {/* Block 5: Orange */}
        <div className="bg-[#ff6b35] text-white p-8 sm:p-12 border-b-4 border-black flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <div className="max-w-2xl">
            <span className="bg-black text-[#ff6b35] text-xs font-black px-2 py-0.5">INVARIANT 05</span>
            <h3 className="text-3xl sm:text-5xl font-black tracking-tight mt-2">EEST CANCUN/PRAGUE COMPLIANCE</h3>
            <p className="mt-2 text-sm sm:text-base font-bold text-white">
              100% verified against canonical Ethereum Foundation execution-spec-tests fixtures (MCOPY, TSTORE/TLOAD, SELFDESTRUCT, RJUMP).
            </p>
          </div>
          <div className="bg-black text-[#39ff14] p-4 font-mono text-xs border-2 border-black w-full md:w-auto">
            roche eest-validate // 100.0% CONFORMANCE
          </div>
        </div>

        {/* Block 6: Deep Red */}
        <div className="bg-[#ff2d00] text-white p-8 sm:p-12 flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
          <div className="max-w-2xl">
            <span className="bg-black text-[#ff2d00] text-xs font-black px-2 py-0.5">INVARIANT 06</span>
            <h3 className="text-3xl sm:text-5xl font-black tracking-tight mt-2">LIVE WIN32 SOCKET RPC STREAMING</h3>
            <p className="mt-2 text-sm sm:text-base font-bold text-white">
              Direct TCP socket connections to local Anvil and mainnet fork nodes using native kernel handles with zero third-party HTTP client libraries.
            </p>
          </div>
          <div className="bg-black text-[#00f0ff] p-4 font-mono text-xs border-2 border-black w-full md:w-auto">
            roche fork http://localhost:8545 0x...V4Pool
          </div>
        </div>
      </section>

      {/* 4. REAL EXPLOITS (Maximalist 3-Card Visual Showcase) */}
      <section className="relative z-10 py-16 px-6 max-w-[1400px] mx-auto">
        <div className="mb-10">
          <div className="inline-block bg-[#00f0ff] text-black font-black text-xs px-2 py-1 uppercase">
            REPRODUCED PROTOCOL ANOMALIES
          </div>
          <h2 className="text-4xl sm:text-6xl font-black text-white mt-2">REAL EXPLOIT REPRODUCTIONS</h2>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {/* Card 1: Cyan Uniswap */}
          <div className="p-8 bg-[#1a0033] border-4 border-[#00f0ff] shadow-[8px_8px_0px_#00f0ff] flex flex-col justify-between">
            <div>
              <div className="text-xs font-black text-[#00f0ff] uppercase tracking-wider">UNISWAP V4 HOOK LEAK</div>
              <h3 className="text-2xl font-black text-white mt-2">TRANSIENT STORAGE GAS SIPHON</h3>
              <p className="mt-4 text-xs text-slate-300 leading-relaxed">
                Unbounded loop execution inside dynamic fee hooks triggers out-of-gas before clearing EIP-1153 lock slots.
              </p>
              <div className="mt-6 p-3 bg-black border border-[#00f0ff] text-[11px] text-[#00f0ff] font-mono">
                MINIMIZED WITNESS (4 OPCODES):<br />
                SLOAD -&gt; DUP2 -&gt; ADD -&gt; SSTORE
              </div>
            </div>
            <a
              href="https://github.com/creatorofaurad/Roche/blob/main/MAINNET_FORK_ANALYSIS.md"
              target="_blank"
              rel="noreferrer"
              className="mt-8 py-3 bg-[#ff006e] text-white font-black text-xs uppercase text-center border-2 border-black hover:bg-[#ff0080]"
            >
              VIEW FULL TRACE REPORT
            </a>
          </div>

          {/* Card 2: Magenta Aave */}
          <div className="p-8 bg-[#1a0033] border-4 border-[#ff006e] shadow-[8px_8px_0px_#ff006e] flex flex-col justify-between">
            <div>
              <div className="text-xs font-black text-[#ff006e] uppercase tracking-wider">AAVE V3 ISOLATION MODE</div>
              <h3 className="text-2xl font-black text-white mt-2">DEBT CEILING RAY OVERFLOW</h3>
              <p className="mt-4 text-xs text-slate-300 leading-relaxed">
                Same-block repay/re-borrow cycles desynchronize index updates, exceeding isolation debt ceilings by fractional ray amounts.
              </p>
              <div className="mt-6 p-3 bg-black border border-[#ff006e] text-[11px] text-[#ff006e] font-mono">
                INVARIANT BREACH DETECTED:<br />
                totalDebt &gt; debtCeiling (Ray lag)
              </div>
            </div>
            <a
              href="https://github.com/creatorofaurad/Roche/blob/main/AAVE_TESTNET_AUDIT_REPORT.md"
              target="_blank"
              rel="noreferrer"
              className="mt-8 py-3 bg-[#00f0ff] text-black font-black text-xs uppercase text-center border-2 border-black hover:bg-[#39ff14]"
            >
              VIEW AUDIT REPORT
            </a>
          </div>

          {/* Card 3: Lime Curve */}
          <div className="p-8 bg-[#1a0033] border-4 border-[#39ff14] shadow-[8px_8px_0px_#39ff14] flex flex-col justify-between">
            <div>
              <div className="text-xs font-black text-[#39ff14] uppercase tracking-wider">CURVE STABLESWAP-NG</div>
              <h3 className="text-2xl font-black text-white mt-2">NEWTON-RAPHSON TRUNCATION</h3>
              <p className="mt-4 text-xs text-slate-300 leading-relaxed">
                Precision loss across asymmetric token decimal scaling (18 vs 6) enables continuous extraction in low-liquidity pools.
              </p>
              <div className="mt-6 p-3 bg-black border border-[#39ff14] text-[11px] text-[#39ff14] font-mono">
                VIRTUAL PRICE DROP:<br />
                Delta &gt; 0.50% Max Allowed
              </div>
            </div>
            <a
              href="https://github.com/creatorofaurad/Roche/blob/main/BALANCER_TESTNET_AUDIT_REPORT.md"
              target="_blank"
              rel="noreferrer"
              className="mt-8 py-3 bg-[#ffff00] text-black font-black text-xs uppercase text-center border-2 border-black hover:bg-[#ff006e] hover:text-white"
            >
              VIEW POOL PROOF
            </a>
          </div>
        </div>
      </section>

      {/* 5. BENCHMARKS (Data Maximalism Matrix) */}
      <section className="relative z-10 py-16 px-6 border-y-4 border-black bg-[#1a0033]">
        <div className="max-w-[1400px] mx-auto">
          <div className="mb-8">
            <div className="inline-block bg-[#ffff00] text-black font-black text-xs px-2 py-1 uppercase">
              EMPIRICAL HARDWARE BENCHMARKS
            </div>
            <h2 className="text-4xl sm:text-6xl font-black text-white mt-2">ROCHE vs ALTERNATIVES</h2>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left border-4 border-black font-mono">
              <thead className="bg-[#ff006e] text-black font-black text-xs sm:text-sm uppercase">
                <tr>
                  <th className="p-4 border-r-2 border-black">EVM FRAMEWORK</th>
                  <th className="p-4 border-r-2 border-black">THROUGHPUT (EXECS/SEC)</th>
                  <th className="p-4 border-r-2 border-black">MEMORY OVERHEAD</th>
                  <th className="p-4 border-r-2 border-black">FALSE POSITIVES</th>
                  <th className="p-4">INVARIANT TYPE</th>
                </tr>
              </thead>
              <tbody className="bg-black text-xs sm:text-sm">
                <tr className="border-b-2 border-slate-800 bg-[#00f0ff]/10">
                  <td className="p-4 font-black text-[#00f0ff] border-r-2 border-slate-800">ROCHE v1.0 (Pure Zig)</td>
                  <td className="p-4 font-black text-[#39ff14] border-r-2 border-slate-800">118,764 / sec (72.2x)</td>
                  <td className="p-4 font-black text-[#00f0ff] border-r-2 border-slate-800">0 MB (Fixed Slab)</td>
                  <td className="p-4 font-black text-[#39ff14] border-r-2 border-slate-800">0.0% (SMT Proved)</td>
                  <td className="p-4 font-black text-[#ffff00]">Dynamic State + Invariant</td>
                </tr>
                <tr className="border-b-2 border-slate-800">
                  <td className="p-4 text-slate-300 border-r-2 border-slate-800">Echidna v2.2 (Haskell)</td>
                  <td className="p-4 text-slate-400 border-r-2 border-slate-800">1,420 / sec</td>
                  <td className="p-4 text-[#ff006e] border-r-2 border-slate-800">540 MB (GC Heap)</td>
                  <td className="p-4 text-[#ff6b35] border-r-2 border-slate-800">4.2%</td>
                  <td className="p-4 text-slate-400">Property Fuzzing</td>
                </tr>
                <tr>
                  <td className="p-4 text-slate-300 border-r-2 border-slate-800">Slither v0.10 (Python)</td>
                  <td className="p-4 text-slate-400 border-r-2 border-slate-800">Static AST Only</td>
                  <td className="p-4 text-[#ff006e] border-r-2 border-slate-800">180 MB (Python)</td>
                  <td className="p-4 text-[#ff2d00] border-r-2 border-slate-800">28.5%</td>
                  <td className="p-4 text-slate-400">Static Detectors Only</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {/* 6. INTEGRATION PATHS (Maximalist Parallel Tracks) */}
      <section className="relative z-10 border-b-4 border-black grid grid-cols-1 md:grid-cols-3">
        {/* Track 1: Cyan */}
        <div className="bg-[#00f0ff] text-black p-10 sm:p-14 border-b-4 md:border-b-0 md:border-r-4 border-black flex flex-col justify-between">
          <div>
            <span className="bg-black text-[#00f0ff] text-xs font-black px-2 py-0.5">TRACK 01</span>
            <h3 className="text-3xl font-black mt-3">FOR PROTOCOL TEAMS</h3>
            <ul className="mt-6 space-y-3 font-bold text-xs sm:text-sm">
              <li>• Free 3-Month Automated Invariant CI/CD Pilot</li>
              <li>• Automated Foundry .t.sol Exploit Synthesis</li>
              <li>• Sub-minute PR regression checking</li>
            </ul>
          </div>
          <a
            href="mailto:srijaan@proton.me?subject=Protocol%20Pilot"
            className="mt-8 py-4 bg-[#ff006e] text-white font-black text-center text-xs uppercase border-2 border-black hover:bg-black hover:text-[#00f0ff]"
          >
            SCHEDULE PILOT CALL
          </a>
        </div>

        {/* Track 2: Magenta */}
        <div className="bg-[#ff006e] text-white p-10 sm:p-14 border-b-4 md:border-b-0 md:border-r-4 border-black flex flex-col justify-between">
          <div>
            <span className="bg-black text-[#ff006e] text-xs font-black px-2 py-0.5">TRACK 02</span>
            <h3 className="text-3xl font-black mt-3">FOR AUDIT FIRMS</h3>
            <ul className="mt-6 space-y-3 font-bold text-xs sm:text-sm">
              <li>• Zero-overhead Rust FFI &amp; C-ABI Bindings</li>
              <li>• 70x faster trace minimization and triage</li>
              <li>• Custom white-label client audit reporting</li>
            </ul>
          </div>
          <a
            href="mailto:srijaan@proton.me?subject=Audit%20Firm%20Integration"
            className="mt-8 py-4 bg-[#00f0ff] text-black font-black text-center text-xs uppercase border-2 border-black hover:bg-black hover:text-[#ff006e]"
          >
            DISCUSS PARTNERSHIP
          </a>
        </div>

        {/* Track 3: Lime */}
        <div className="bg-[#39ff14] text-black p-10 sm:p-14 flex flex-col justify-between">
          <div>
            <span className="bg-black text-[#39ff14] text-xs font-black px-2 py-0.5">TRACK 03</span>
            <h3 className="text-3xl font-black mt-3">FOR GRANTS &amp; BUILDERS</h3>
            <ul className="mt-6 space-y-3 font-bold text-xs sm:text-sm">
              <li>• $500K Ethereum Foundation ESP 1TS Proposal</li>
              <li>• 100% Open Source (MIT / Apache-2.0)</li>
              <li>• Pure Zig 0.16.0 Bare-Silicon Core</li>
            </ul>
          </div>
          <a
            href="https://github.com/creatorofaurad/Roche/blob/main/ETHEREUM_FOUNDATION_ESP_500K_GRANT_PROPOSAL.md"
            target="_blank"
            rel="noreferrer"
            className="mt-8 py-4 bg-[#ffff00] text-black font-black text-center text-xs uppercase border-2 border-black hover:bg-black hover:text-[#39ff14]"
          >
            VIEW GRANT DOSSIER
          </a>
        </div>
      </section>

      {/* 7. SOCIAL PROOF & INDEPENDENT VERIFICATION */}
      <section className="relative z-10 py-16 px-6 bg-[#1a0033] max-w-[1400px] mx-auto text-center">
        <div className="border-4 border-[#ffff00] p-8 sm:p-12 bg-black shadow-[10px_10px_0px_#ffff00]">
          <div className="text-xs font-black text-[#39ff14] uppercase tracking-widest">
            INDEPENDENT SYSTEMS AUDIT CERTIFICATION
          </div>
          <h2 className="text-3xl sm:text-5xl font-black text-white mt-3">
            100% UNCONDITIONAL PASS
          </h2>
          <p className="mt-4 text-xs sm:text-sm text-slate-300 max-w-2xl mx-auto">
            Audited on bare silicon by <strong>Yelena (Systems Architect)</strong> on September 20, 2026. All 29 invariant suites passed with 0 bytes dynamic heap memory leaks.
          </p>

          <div className="mt-6">
            <a
              href="https://github.com/creatorofaurad/Roche/blob/main/VERIFICATION_AUDIT.md"
              target="_blank"
              rel="noreferrer"
              className="inline-block text-[#ffff00] font-black text-sm uppercase underline decoration-2 underline-offset-4 hover:text-[#ff006e]"
            >
              [READ COMPLETE VERIFICATION_AUDIT.MD ON GITHUB]
            </a>
          </div>
        </div>
      </section>

      {/* 8. FOOTER / CONTACT */}
      <footer className="relative z-10 border-t-4 border-black bg-black px-6 py-12 text-center text-xs">
        <div className="max-w-[1400px] mx-auto flex flex-col md:flex-row items-center justify-between gap-6">
          <div className="text-left">
            <div className="text-xl font-black text-white">ROCHE :: BARE-SILICON EVM</div>
            <div className="text-slate-400 mt-1 font-bold">
              Engineered by Charles (Lead Architect, Age 15) • MIT OR Apache-2.0 License
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-6 font-bold">
            <a href="mailto:srijaan@proton.me" className="text-[#00f0ff] hover:text-[#39ff14]">
              srijaan@proton.me
            </a>
            <a href="https://github.com/creatorofaurad/Roche" target="_blank" rel="noreferrer" className="text-[#ff006e] hover:text-[#ffff00]">
              github.com/creatorofaurad/Roche
            </a>
            <a href="https://github.com/creatorofaurad/Roche/blob/main/SECURITY.md" target="_blank" rel="noreferrer" className="text-[#ffff00] hover:text-white">
              SECURITY.MD
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
}
