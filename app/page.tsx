"use client";

import React, { useEffect, useState, useRef } from "react";
import Image from "next/image";

export default function SingleViewportLanding() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [activeTab, setActiveTab] = useState("Engine");
  const statsRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    // Count up logic
    const statElements = document.querySelectorAll<HTMLElement>(".stat-val");
    if (!statElements.length) return;

    const easeOutCubic = (t: number) => 1 - Math.pow(1 - t, 3);

    const startAnimation = () => {
      statElements.forEach((el, index) => {
        const target = parseFloat(el.getAttribute("data-target") || "0");
        const decimals = parseInt(el.getAttribute("data-decimals") || "0", 10);
        const suffix = el.getAttribute("data-suffix") || "";
        const duration = 1500 + index * 80;
        const delay = 480 + index * 90;

        setTimeout(() => {
          let startTime: number | null = null;

          const step = (timestamp: number) => {
            if (!startTime) startTime = timestamp;
            const elapsed = timestamp - startTime;
            const progress = Math.min(elapsed / duration, 1);
            const currentVal = easeOutCubic(progress) * target;

            el.textContent = `${currentVal.toFixed(decimals)}${suffix}`;

            if (progress < 1) {
              requestAnimationFrame(step);
            } else {
              el.textContent = `${target.toFixed(decimals)}${suffix}`;
            }
          };

          requestAnimationFrame(step);
        }, delay);
      });
    };

    if ("IntersectionObserver" in window && statsRef.current) {
      const observer = new IntersectionObserver(
        (entries, obs) => {
          entries.forEach((entry) => {
            if (entry.isIntersecting) {
              startAnimation();
              obs.disconnect();
            }
          });
        },
        { threshold: 0.25 }
      );
      observer.observe(statsRef.current);
    } else {
      startAnimation();
    }
  }, []);

  // Listen for Escape key to close mobile drawer
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape") {
        setMobileOpen(false);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  const navItems = [
    { label: "Engine", href: "#overview" },
    { label: "42 Detectors", href: "#invariants" },
    { label: "Exploits", href: "#exploits" },
    { label: "GitHub", href: "https://github.com/creatorofaurad/Roche", external: true },
  ];

  return (
    <>
      {/* Full-bleed background video container */}
      <div className="bg">
        <video className="bg-video" autoPlay muted loop playsInline>
          <source
            src="https://d8j0ntlcm91z4.cloudfront.net/user_38xzZboKViGWJOttwIXH07lWA1P/hf_20260809_012548_ef22562c-c0ae-4816-ad9d-f8922af4e6a7.mp4"
            type="video/mp4"
          />
        </video>
      </div>

      {/* Single-viewport page container */}
      <div className="page">
        {/* 1. Header (Desktop & Mobile) */}
        <header className="header">
          {/* Circular Logo (Roche R) */}
          <a
            href="https://github.com/creatorofaurad/Roche"
            target="_blank"
            rel="noopener noreferrer"
            className="logo-btn"
            aria-label="Roche GitHub Repository"
          >
            <Image
              src="/assets/logo.webp"
              alt="Roche"
              width={52}
              height={52}
              className="logo-img"
              unoptimized
            />
          </a>

          {/* Desktop Nav Pill (White) */}
          <nav className="nav-pill" aria-label="Main Navigation">
            {navItems.map((item) => (
              <a
                key={item.label}
                href={item.href}
                target={item.external ? "_blank" : undefined}
                rel={item.external ? "noopener noreferrer" : undefined}
                className={`nav-link ${activeTab === item.label ? "active" : ""}`}
                onClick={(e) => {
                  if (!item.external) {
                    e.preventDefault();
                    setActiveTab(item.label);
                  }
                }}
              >
                {item.label}
              </a>
            ))}
          </nav>

          {/* Desktop Sign In / Release Pill */}
          <a
            href="https://github.com/creatorofaurad/Roche"
            target="_blank"
            rel="noopener noreferrer"
            className="signin-btn"
          >
            v1.5.0 Release
          </a>

          {/* Mobile Hamburger Button (≤720px) */}
          <button
            className={`burger-btn ${mobileOpen ? "open" : ""}`}
            aria-label="Toggle navigation menu"
            aria-expanded={mobileOpen}
            onClick={() => setMobileOpen(!mobileOpen)}
          >
            <span className="burger-bar"></span>
            <span className="burger-bar"></span>
            <span className="burger-bar"></span>
          </button>
        </header>

        {/* 2. Hero Section (Centered) */}
        <main className="hero">
          {/* Trust Row ("Verified on Ethereum, Solana & Agglayer") */}
          <div className="trust-row anim" style={{ "--d": "0.05s" } as React.CSSProperties}>
            <div className="trust-avatars">
              {/* Ethereum */}
              <div className="avatar-ring a1">
                <div className="avatar-inner">
                  <i className="fa-brands fa-ethereum"></i>
                </div>
              </div>
              {/* EVM Cube */}
              <div className="avatar-ring a2">
                <div className="avatar-inner">
                  <i className="fa-solid fa-cube"></i>
                </div>
              </div>
              {/* Security Shield */}
              <div className="avatar-ring a3">
                <div className="avatar-inner">
                  <i className="fa-solid fa-shield-halved"></i>
                </div>
              </div>
            </div>
            <div className="trust-pill">
              <span>Verified on Ethereum, Solana &amp; Agglayer</span>
            </div>
          </div>

          {/* Headline (Solid White, Exact Two Lines, BubbledotICG-FinePos) */}
          <h1 className="headline anim">
            <span className="headline-line line-1">Roche</span>
            <span className="headline-line line-2">Silicon Invariant Engine</span>
          </h1>

          {/* Subhead (Exact Roche copy) */}
          <p className="subhead anim" style={{ "--d": "0.28s" } as React.CSSProperties}>
            Zero-allocation EVM formal invariant verification &amp; symbolic fuzzing at 118,000 execs/sec.
            Engineered in pure Zig 0.16.0 with direct Win32/POSIX system calls.
          </p>

          {/* CTA (Explore Roche on GitHub with Soft White Glow) */}
          <div className="cta-wrapper anim" style={{ "--d": "0.4s" } as React.CSSProperties}>
            <a
              href="https://github.com/creatorofaurad/Roche"
              target="_blank"
              rel="noopener noreferrer"
              className="cta-btn"
            >
              Explore Roche on GitHub
            </a>
          </div>
        </main>

        {/* 3. Stats Footer (4 Exact Roche Metrics) */}
        <footer className="stats-footer" ref={statsRef}>
          <div className="stats-grid">
            {/* Stat 1: < 120 µs Pre-Execution Latency */}
            <div className="stat-card anim" style={{ "--d": "0.5s" } as React.CSSProperties}>
              <div className="stat-icon">&lt;</div>
              <div className="stat-value-row">
                <span
                  className="stat-val"
                  data-target="120"
                  data-decimals="0"
                  data-suffix="µs"
                >
                  0
                </span>
              </div>
              <div className="stat-label">Pre-Exec Latency</div>
            </div>

            {/* Stat 2: % 100.0 % Solvency Accuracy */}
            <div className="stat-card anim" style={{ "--d": "0.58s" } as React.CSSProperties}>
              <div className="stat-icon">%</div>
              <div className="stat-value-row">
                <span
                  className="stat-val"
                  data-target="100.0"
                  data-decimals="1"
                  data-suffix="%"
                >
                  0
                </span>
              </div>
              <div className="stat-label">Solvency Accuracy</div>
            </div>

            {/* Stat 3: * 118 k/s Symbolic Execution */}
            <div className="stat-card anim" style={{ "--d": "0.66s" } as React.CSSProperties}>
              <div className="stat-icon">*</div>
              <div className="stat-value-row">
                <span
                  className="stat-val"
                  data-target="118"
                  data-decimals="0"
                  data-suffix="k/s"
                >
                  0
                </span>
              </div>
              <div className="stat-label">Symbolic Throughput</div>
            </div>

            {/* Stat 4: # 0 B Dynamic Heap Allocs */}
            <div className="stat-card anim" style={{ "--d": "0.74s" } as React.CSSProperties}>
              <div className="stat-icon">#</div>
              <div className="stat-value-row">
                <span
                  className="stat-val"
                  data-target="0"
                  data-decimals="0"
                  data-suffix="B"
                >
                  0
                </span>
              </div>
              <div className="stat-label">Dynamic Heap Allocs</div>
            </div>
          </div>
        </footer>
      </div>

      {/* Mobile Navigation Sheet & Backdrop */}
      <div
        className="mobile-overlay"
        hidden={!mobileOpen}
        onClick={(e) => {
          if (e.target === e.currentTarget) setMobileOpen(false);
        }}
      >
        <div className="mobile-sheet">
          <nav className="mobile-nav" aria-label="Mobile Navigation">
            {navItems.map((item) => (
              <a
                key={item.label}
                href={item.href}
                target={item.external ? "_blank" : undefined}
                rel={item.external ? "noopener noreferrer" : undefined}
                className={`mobile-link ${activeTab === item.label ? "active" : ""}`}
                onClick={(e) => {
                  if (!item.external) {
                    e.preventDefault();
                    setActiveTab(item.label);
                  }
                  setMobileOpen(false);
                }}
              >
                {item.label}
              </a>
            ))}
            <a
              href="https://github.com/creatorofaurad/Roche"
              target="_blank"
              rel="noopener noreferrer"
              className="mobile-signin"
              onClick={() => setMobileOpen(false)}
            >
              v1.5.0 Release
            </a>
          </nav>
        </div>
      </div>
    </>
  );
}
