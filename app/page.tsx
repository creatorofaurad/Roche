"use client";

import React, { useEffect, useState, useRef } from "react";
import Image from "next/image";

export default function SingleViewportLanding() {
  const [mobileOpen, setMobileOpen] = useState(false);
  const [activeTab, setActiveTab] = useState("Home");
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
          {/* Circular Logo */}
          <a href="#" className="logo-btn" aria-label="Roche Home">
            <Image
              src="/assets/logo.webp"
              alt=""
              width={52}
              height={52}
              className="logo-img"
              unoptimized
            />
          </a>

          {/* Desktop Nav Pill (White) */}
          <nav className="nav-pill" aria-label="Main Navigation">
            {["Home", "Product", "Case Studies", "Contact"].map((item) => (
              <a
                key={item}
                href={`#${item.toLowerCase().replace(/\s+/g, "-")}`}
                className={`nav-link ${activeTab === item ? "active" : ""}`}
                onClick={(e) => {
                  e.preventDefault();
                  setActiveTab(item);
                }}
              >
                {item}
              </a>
            ))}
          </nav>

          {/* Desktop Sign In Pill */}
          <a href="#signin" className="signin-btn">
            Sign in
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
          {/* Trust Row ("Trusted by 2000+ Enterprises") */}
          <div className="trust-row anim" style={{ "--d": "0.05s" } as React.CSSProperties}>
            <div className="trust-avatars">
              {/* Microsoft */}
              <div className="avatar-ring a1">
                <div className="avatar-inner">
                  <i className="fa-brands fa-microsoft"></i>
                </div>
              </div>
              {/* Amazon */}
              <div className="avatar-ring a2">
                <div className="avatar-inner">
                  <i className="fa-brands fa-amazon"></i>
                </div>
              </div>
              {/* Google */}
              <div className="avatar-ring a3">
                <div className="avatar-inner">
                  <i className="fa-brands fa-google"></i>
                </div>
              </div>
            </div>
            <div className="trust-pill">
              <span>Trusted by 2000+ Enterprises</span>
            </div>
          </div>

          {/* Headline (Solid White, Exact Two Lines, BubbledotICG-FinePos) */}
          <h1 className="headline anim">
            <span className="headline-line line-1">Intelligence</span>
            <span className="headline-line line-2">Designed To Evolve</span>
          </h1>

          {/* Subhead (Exact copy, +2pt font sizing) */}
          <p className="subhead anim" style={{ "--d": "0.28s" } as React.CSSProperties}>
            Build applications that reason, adapt and collaborate using a modular
            AI platform designed for production.
          </p>

          {/* CTA (Get Started White Pill with Soft White Glow) */}
          <div className="cta-wrapper anim" style={{ "--d": "0.4s" } as React.CSSProperties}>
            <a href="#get-started" className="cta-btn">
              Get Started
            </a>
          </div>
        </main>

        {/* 3. Stats Footer (4 Exact Metrics) */}
        <footer className="stats-footer" ref={statsRef}>
          <div className="stats-grid">
            {/* Stat 1: < 120 ms Inference Time */}
            <div className="stat-card anim" style={{ "--d": "0.5s" } as React.CSSProperties}>
              <div className="stat-icon">&lt;</div>
              <div className="stat-value-row">
                <span
                  className="stat-val"
                  data-target="120"
                  data-decimals="0"
                  data-suffix="ms"
                >
                  0
                </span>
              </div>
              <div className="stat-label">Inference Time</div>
            </div>

            {/* Stat 2: % 99.99 % Platform Uptime */}
            <div className="stat-card anim" style={{ "--d": "0.58s" } as React.CSSProperties}>
              <div className="stat-icon">%</div>
              <div className="stat-value-row">
                <span
                  className="stat-val"
                  data-target="99.99"
                  data-decimals="2"
                  data-suffix="%"
                >
                  0
                </span>
              </div>
              <div className="stat-label">Platform Uptime</div>
            </div>

            {/* Stat 3: * 24 /7 Autonomous Runtime */}
            <div className="stat-card anim" style={{ "--d": "0.66s" } as React.CSSProperties}>
              <div className="stat-icon">*</div>
              <div className="stat-value-row">
                <span
                  className="stat-val"
                  data-target="24"
                  data-decimals="0"
                  data-suffix="/7"
                >
                  0
                </span>
              </div>
              <div className="stat-label">Autonomous Runtime</div>
            </div>

            {/* Stat 4: # 2.4 M Context Windows */}
            <div className="stat-card anim" style={{ "--d": "0.74s" } as React.CSSProperties}>
              <div className="stat-icon">#</div>
              <div className="stat-value-row">
                <span
                  className="stat-val"
                  data-target="2.4"
                  data-decimals="1"
                  data-suffix="M"
                >
                  0
                </span>
              </div>
              <div className="stat-label">Context Windows</div>
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
            {["Home", "Product", "Case Studies", "Contact"].map((item) => (
              <a
                key={item}
                href={`#${item.toLowerCase().replace(/\s+/g, "-")}`}
                className={`mobile-link ${activeTab === item ? "active" : ""}`}
                onClick={(e) => {
                  e.preventDefault();
                  setActiveTab(item);
                  setMobileOpen(false);
                }}
              >
                {item}
              </a>
            ))}
            <a
              href="#signin"
              className="mobile-signin"
              onClick={() => setMobileOpen(false)}
            >
              Sign in
            </a>
          </nav>
        </div>
      </div>
    </>
  );
}
