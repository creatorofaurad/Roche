"use client";

import React from "react";
import { Terminal, ArrowUpRight } from "lucide-react";

export default function Navbar() {
  return (
    <header className="sticky top-0 z-50 bg-black/95 backdrop-blur-md border-b border-zinc-900 px-4 sm:px-8 py-3.5">
      <div className="max-w-7xl mx-auto flex items-center justify-between">
        {/* Brand */}
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded bg-white text-black flex items-center justify-center font-mono font-black text-sm">
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
              by Charles (Age 15)
            </span>
          </div>
        </div>

        {/* Navigation */}
        <nav className="hidden md:flex items-center gap-8 text-xs font-mono text-zinc-400">
          <a href="#dossier" className="hover:text-white transition-colors">
            Grant Dossier
          </a>
          <a href="#architect" className="hover:text-white transition-colors">
            The Architect
          </a>
          <a href="#architecture" className="hover:text-white transition-colors">
            Architecture
          </a>
          <a href="#benchmarks" className="hover:text-white transition-colors">
            Benchmarks
          </a>
          <a href="#faq" className="hover:text-white transition-colors">
            Technical FAQ
          </a>
        </nav>

        {/* Action Button */}
        <div className="flex items-center gap-3">
          <a
            href="https://github.com/creatorofaurad/roche"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 px-3.5 py-1.5 rounded bg-zinc-900 hover:bg-zinc-800 border border-zinc-800 text-white text-xs font-mono transition-all"
          >
            <svg className="w-3.5 h-3.5 fill-current text-white" viewBox="0 0 24 24">
              <path d="M12 0C5.37 0 0 5.37 0 12c0 5.31 3.435 9.795 8.205 11.385.6.105.825-.255.825-.57 0-.285-.015-1.23-.015-2.235-3.015.555-3.795-.735-4.035-1.41-.135-.345-.72-1.41-1.23-1.695-.42-.225-1.02-.78-.015-.795.945-.015 1.62.87 1.845 1.23 1.08 1.815 2.805 1.305 3.495.99.105-.78.42-1.305.765-1.605-2.67-.3-5.46-1.335-5.46-5.925 0-1.305.465-2.385 1.23-3.225-.12-.3-.54-1.53.12-3.18 0 0 1.005-.315 3.3 1.23.96-.27 1.98-.405 3-.405s2.04.135 3 .405c2.295-1.56 3.3-1.23 3.3-1.23.66 1.65.24 2.88.12 3.18.765.84 1.23 1.905 1.23 3.225 0 4.605-2.805 5.625-5.475 5.925.435.375.81 1.095.81 2.22 0 1.605-.015 2.895-.015 3.3 0 .315.225.69.825.57A12.02 12.02 0 0024 12c0-6.63-5.37-12-12-12z" />
            </svg>
            <span>View Source</span>
            <ArrowUpRight className="w-3.5 h-3.5 text-zinc-400" />
          </a>
        </div>
      </div>
    </header>
  );
}
