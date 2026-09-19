"use client";

import React from "react";
import { Terminal, Shield, ArrowRight } from "lucide-react";

export default function Navbar() {
  return (
    <header className="sticky top-0 z-50 w-full border-b border-[#222226] bg-[#080809]/80 backdrop-blur-md">
      <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-3.5">
        {/* Logo */}
        <a href="#" className="flex items-center gap-2.5 group">
          <div className="flex h-7 w-7 items-center justify-center rounded-md bg-zinc-900 border border-zinc-700 text-emerald-400 group-hover:border-emerald-500 transition-colors">
            <span className="font-mono font-bold text-sm">R_</span>
          </div>
          <span className="font-semibold text-base tracking-tight text-white flex items-center gap-1.5">
            Roche <span className="text-[10px] uppercase font-mono px-1.5 py-0.5 rounded bg-emerald-950 text-emerald-400 border border-emerald-800/50">EVM</span>
          </span>
        </a>

        {/* Nav Links */}
        <nav className="hidden md:flex items-center gap-7 text-xs text-zinc-400 font-medium">
          <a href="#how-it-works" className="hover:text-white transition-colors">How it works</a>
          <a href="#features" className="hover:text-white transition-colors">Features</a>
          <a href="#pricing" className="hover:text-white transition-colors">Pricing</a>
          <a href="#faq" className="hover:text-white transition-colors">FAQ</a>
        </nav>

        {/* Action Button */}
        <div className="flex items-center gap-3">
          <a
            href="https://github.com/creatorofaurad/roche"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1.5 rounded-full bg-white px-4 py-1.5 text-xs font-semibold text-black hover:bg-zinc-200 transition-all hover:scale-105"
          >
            <span>Get Roche</span>
            <ArrowRight className="h-3.5 w-3.5" />
          </a>
        </div>
      </div>
    </header>
  );
}
