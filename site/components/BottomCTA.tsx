"use client";

import React, { useState } from "react";
import { Terminal, Copy, Check, ShieldCheck, ArrowUpRight } from "lucide-react";

export default function BottomCTA() {
  const [copied, setCopied] = useState(false);
  const cloneCmd = "git clone https://github.com/creatorofaurad/roche";

  const handleCopy = () => {
    navigator.clipboard.writeText(cloneCmd);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <footer className="relative bg-black pt-20 pb-12 border-t border-zinc-900 text-zinc-400 font-mono">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Main CTA Section */}
        <div className="max-w-3xl mb-16">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded border border-zinc-800 bg-zinc-950 text-zinc-300 text-xs uppercase tracking-widest mb-4">
            <ShieldCheck className="w-3.5 h-3.5 text-white" />
            Ecosystem Grant Dossier · Fall 2026
          </div>

          <h2 className="text-3xl sm:text-5xl font-bold tracking-tight text-white mb-4">
            Support the Research & Verification Core.
          </h2>

          <p className="text-zinc-400 text-sm sm:text-base leading-relaxed mb-8">
            Roche is engineered by Charles (age 15) to provide bare-silicon, zero-allocation formal verification infrastructure for Ethereum, Base, Uniswap, and Arbitrum.
          </p>

          {/* Quick Clone Bar */}
          <div className="flex items-center justify-between bg-zinc-950 p-3 rounded border border-zinc-800 max-w-lg">
            <div className="flex items-center gap-2 text-xs text-zinc-300 overflow-hidden">
              <span className="text-white font-bold">$</span>
              <span className="select-all truncate">{cloneCmd}</span>
            </div>
            <button
              onClick={handleCopy}
              className="px-3.5 py-1.5 rounded bg-zinc-900 hover:bg-zinc-800 text-white text-xs font-semibold flex items-center justify-center gap-2 border border-zinc-700 transition-colors shrink-0 ml-3"
            >
              {copied ? (
                <>
                  <Check className="w-3.5 h-3.5 text-white" />
                  <span>Copied</span>
                </>
              ) : (
                <>
                  <Copy className="w-3.5 h-3.5 text-white" />
                  <span>Copy</span>
                </>
              )}
            </button>
          </div>
        </div>

        {/* Links Grid */}
        <div className="pt-12 border-t border-zinc-900 grid grid-cols-2 md:grid-cols-4 gap-8 mb-12 text-xs">
          {/* Brand */}
          <div className="col-span-2 md:col-span-1">
            <div className="flex items-center gap-2 mb-3">
              <div className="w-6 h-6 rounded bg-white text-black flex items-center justify-center font-bold text-xs">
                R
              </div>
              <span className="font-bold text-white tracking-tight">ROCHE ENGINE</span>
            </div>
            <p className="text-zinc-500 text-xs leading-relaxed mb-4">
              Bare-silicon EVM invariant prover. Written in Zig 0.16 by Charles.
            </p>
            <div className="flex items-center gap-3 text-zinc-400">
              <a
                href="https://github.com/creatorofaurad/roche"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="GitHub Repository"
                className="hover:text-white transition-colors p-1.5 rounded bg-zinc-950 border border-zinc-800"
              >
                <svg className="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24">
                  <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" />
                </svg>
              </a>
              <a
                href="https://x.com"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="X (Twitter)"
                className="hover:text-white transition-colors p-1.5 rounded bg-zinc-950 border border-zinc-800"
              >
                <svg className="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24">
                  <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
                </svg>
              </a>
            </div>
          </div>

          {/* Col 1 */}
          <div>
            <h4 className="text-zinc-200 font-bold uppercase tracking-wider mb-3">Architecture</h4>
            <ul className="space-y-2 text-zinc-500">
              <li><a href="#architecture" className="hover:text-white">SMT Array Theory</a></li>
              <li><a href="#architecture" className="hover:text-white">AVX2 Vectorization</a></li>
              <li><a href="#architecture" className="hover:text-white">0-Heap Allocation</a></li>
              <li><a href="#benchmarks" className="hover:text-white">Hardware Benchmarks</a></li>
            </ul>
          </div>

          {/* Col 2 */}
          <div>
            <h4 className="text-zinc-200 font-bold uppercase tracking-wider mb-3">Grant Proposals</h4>
            <ul className="space-y-2 text-zinc-500">
              <li><a href="#dossier" className="hover:text-white">Uniswap Foundation ($75k)</a></li>
              <li><a href="#dossier" className="hover:text-white">Base Ecosystem ($100k)</a></li>
              <li><a href="#dossier" className="hover:text-white">Arbitrum Builders ($50k)</a></li>
              <li><a href="#dossier" className="hover:text-white">Ethereum ESP ($50k)</a></li>
            </ul>
          </div>

          {/* Col 3 */}
          <div>
            <h4 className="text-zinc-200 font-bold uppercase tracking-wider mb-3">The Architect</h4>
            <ul className="space-y-2 text-zinc-500">
              <li><a href="#architect" className="hover:text-white">Charles (Age 15)</a></li>
              <li><a href="https://github.com/creatorofaurad/roche" className="hover:text-white flex items-center gap-1">GitHub Repo <ArrowUpRight className="w-3 h-3" /></a></li>
              <li><a href="#faq" className="hover:text-white">Technical Invariants</a></li>
              <li><span className="text-white font-semibold">29/29 Suites Green</span></li>
            </ul>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="pt-6 border-t border-zinc-900 flex flex-col sm:flex-row items-center justify-between text-[11px] text-zinc-600 gap-2">
          <div className="flex items-center gap-2">
            <span className="w-1.5 h-1.5 rounded-full bg-white" />
            <span>Bare Silicon Verification Core • 0 B Dynamic Heap</span>
          </div>
          <div>
            © {new Date().getFullYear()} Roche. Engineered & formally proven by Charles.
          </div>
        </div>
      </div>
    </footer>
  );
}
