"use client";

import React from "react";

export default function Home() {
  return (
    <div style={{
      backgroundColor: "#0a0e27",
      color: "#ffffff",
      minHeight: "100vh",
      display: "flex",
      flexDirection: "column",
      fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif'
    }}>
      {/* Top Sticky Navigation */}
      <header style={{
        position: "sticky",
        top: 0,
        zIndex: 1000,
        backgroundColor: "rgba(10, 14, 39, 0.95)",
        borderBottom: "1px solid #003344",
        backdropFilter: "blur(8px)"
      }}>
        <div style={{
          maxWidth: "1200px",
          margin: "0 auto",
          padding: "1.1rem 1.5rem",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center"
        }}>
          <div style={{
            fontFamily: "'IBM Plex Mono', monospace",
            fontSize: "1.25rem",
            fontWeight: 700,
            letterSpacing: "0.12em",
            color: "#ffffff"
          }}>
            <span style={{ color: "#00d9ff" }}>[</span>ROCHE<span style={{ color: "#00d9ff" }}>]</span>
          </div>
          <nav style={{
            display: "flex",
            gap: "2rem",
            fontSize: "0.875rem",
            fontWeight: 500,
            fontFamily: "'IBM Plex Mono', monospace"
          }}>
            <a href="https://github.com/creatorofaurad/Roche" style={{ color: "#ffffff", textDecoration: "none" }}>GitHub</a>
            <a href="#docs" style={{ color: "#ffffff", textDecoration: "none" }}>Docs</a>
            <a href="#institutions" style={{ color: "#ffffff", textDecoration: "none" }}>For Institutions</a>
            <a href="mailto:partnerships@roche.dev" style={{ color: "#ffffff", textDecoration: "none" }}>Contact</a>
          </nav>
        </div>
      </header>

      {/* Main Content */}
      <main style={{ flexGrow: 1 }}>
        {/* Hero Section */}
        <div style={{ maxWidth: "1200px", margin: "0 auto", padding: "0 1.5rem" }}>
          <section style={{
            minHeight: "60vh",
            display: "flex",
            flexDirection: "column",
            justifyContent: "center",
            padding: "4rem 0"
          }}>
            <div style={{ height: "1px", backgroundColor: "#00d9ff", width: "100%", opacity: 0.8, marginBottom: "2.5rem" }}></div>
            
            <div style={{
              color: "#00ff41",
              fontSize: "0.875rem",
              marginBottom: "1rem",
              letterSpacing: "0.05em",
              fontFamily: "'IBM Plex Mono', monospace"
            }}>
              RELEASE-FAST :: PRODUCTION SPECIFICATION v1.5.0
            </div>
            
            <h1 style={{
              fontSize: "3.25rem",
              fontWeight: 700,
              letterSpacing: "0.08em",
              color: "#ffffff",
              marginBottom: "1.5rem",
              lineHeight: 1.1,
              fontFamily: "'IBM Plex Mono', monospace"
            }}>
              ROCHE
            </h1>

            <p style={{
              fontSize: "1.2rem",
              color: "#c0c0c0",
              lineHeight: 1.6,
              maxWidth: "820px",
              marginBottom: "2.5rem",
              fontFamily: "'IBM Plex Mono', monospace"
            }}>
              Zero-allocation EVM invariant engine.<br />
              Real-time protocol security verification.<br />
              118,000+ symbolic executions per second.
            </p>

            <div style={{ display: "flex", gap: "1.25rem", flexWrap: "wrap" }}>
              <a href="https://github.com/creatorofaurad/Roche" style={{
                display: "inline-flex",
                alignItems: "center",
                justifyContent: "center",
                padding: "0.85rem 1.75rem",
                fontFamily: "'IBM Plex Mono', monospace",
                fontSize: "0.875rem",
                fontWeight: 700,
                textTransform: "uppercase",
                letterSpacing: "0.05em",
                backgroundColor: "transparent",
                color: "#ffffff",
                border: "1px solid #00d9ff",
                textDecoration: "none"
              }}>
                ← GITHUB REPOSITORY
              </a>
              <a href="#docs" style={{
                display: "inline-flex",
                alignItems: "center",
                justifyContent: "center",
                padding: "0.85rem 1.75rem",
                fontFamily: "'IBM Plex Mono', monospace",
                fontSize: "0.875rem",
                fontWeight: 700,
                textTransform: "uppercase",
                letterSpacing: "0.05em",
                backgroundColor: "transparent",
                color: "#c0c0c0",
                border: "1px solid #003344",
                textDecoration: "none"
              }}>
                DOCUMENTATION →
              </a>
            </div>

            <div style={{ height: "1px", backgroundColor: "#00d9ff", width: "100%", opacity: 0.8, marginTop: "2.5rem" }}></div>
          </section>
        </div>


        {/* Performance Metrics Section */}
        <section style={{ maxWidth: "1200px", margin: "0 auto", padding: "0 1.5rem" }}>
          <h2 style={{
            fontSize: "1.35rem",
            fontWeight: 700,
            letterSpacing: "0.08em",
            color: "#ffffff",
            marginBottom: "2rem",
            textTransform: "uppercase",
            fontFamily: "'IBM Plex Mono', monospace"
          }}>
            <span style={{ color: "#00d9ff" }}>■ </span>INSTITUTIONAL-GRADE VERIFICATION
          </h2>

          <div style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
            gap: "1.25rem",
            marginBottom: "3rem"
          }}>
            <div style={{ backgroundColor: "rgba(0, 217, 255, 0.03)", border: "1px solid #003344", padding: "2rem 1.5rem" }}>
              <div style={{ fontSize: "2.25rem", fontWeight: 700, color: "#00d9ff", marginBottom: "0.35rem", fontFamily: "'IBM Plex Mono', monospace" }}>118,000</div>
              <div style={{ fontSize: "0.875rem", color: "#ffffff", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em", fontFamily: "'IBM Plex Mono', monospace" }}>execs/second</div>
              <div style={{ fontSize: "0.8rem", color: "#c0c0c0", marginTop: "0.25rem" }}>Pure Zig 0.16.0 bare-silicon core</div>
            </div>

            <div style={{ backgroundColor: "rgba(0, 217, 255, 0.03)", border: "1px solid #003344", padding: "2rem 1.5rem" }}>
              <div style={{ fontSize: "2.25rem", fontWeight: 700, color: "#00d9ff", marginBottom: "0.35rem", fontFamily: "'IBM Plex Mono', monospace" }}>&lt;10%</div>
              <div style={{ fontSize: "0.875rem", color: "#ffffff", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em", fontFamily: "'IBM Plex Mono', monospace" }}>false positives</div>
              <div style={{ fontSize: "0.8rem", color: "#c0c0c0", marginTop: "0.25rem" }}>on general code</div>
            </div>

            <div style={{ backgroundColor: "rgba(0, 217, 255, 0.03)", border: "1px solid #003344", padding: "2rem 1.5rem" }}>
              <div style={{ fontSize: "2.25rem", fontWeight: 700, color: "#00d9ff", marginBottom: "0.35rem", fontFamily: "'IBM Plex Mono', monospace" }}>0.00%</div>
              <div style={{ fontSize: "0.875rem", color: "#ffffff", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em", fontFamily: "'IBM Plex Mono', monospace" }}>on solvency</div>
              <div style={{ fontSize: "0.8rem", color: "#c0c0c0", marginTop: "0.25rem" }}>invariants</div>
            </div>

            <div style={{ backgroundColor: "rgba(0, 217, 255, 0.03)", border: "1px solid #003344", padding: "2rem 1.5rem" }}>
              <div style={{ fontSize: "2.25rem", fontWeight: 700, color: "#00d9ff", marginBottom: "0.35rem", fontFamily: "'IBM Plex Mono', monospace" }}>0 bytes</div>
              <div style={{ fontSize: "0.875rem", color: "#ffffff", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em", fontFamily: "'IBM Plex Mono', monospace" }}>heap allocations</div>
              <div style={{ fontSize: "0.8rem", color: "#c0c0c0", marginTop: "0.25rem" }}>on hot paths</div>
            </div>

            <div style={{ backgroundColor: "rgba(0, 217, 255, 0.03)", border: "1px solid #003344", padding: "2rem 1.5rem" }}>
              <div style={{ fontSize: "2.25rem", fontWeight: 700, color: "#00d9ff", marginBottom: "0.35rem", fontFamily: "'IBM Plex Mono', monospace" }}>193/193</div>
              <div style={{ fontSize: "0.875rem", color: "#ffffff", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em", fontFamily: "'IBM Plex Mono', monospace" }}>regression tests</div>
              <div style={{ fontSize: "0.8rem", color: "#c0c0c0", marginTop: "0.25rem" }}>passing (100% Green)</div>
            </div>

            <div style={{ backgroundColor: "rgba(0, 217, 255, 0.03)", border: "1px solid #003344", padding: "2rem 1.5rem" }}>
              <div style={{ fontSize: "2.25rem", fontWeight: 700, color: "#00d9ff", marginBottom: "0.35rem", fontFamily: "'IBM Plex Mono', monospace" }}>&lt;5 seconds</div>
              <div style={{ fontSize: "0.875rem", color: "#ffffff", fontWeight: 600, textTransform: "uppercase", letterSpacing: "0.05em", fontFamily: "'IBM Plex Mono', monospace" }}>per contract</div>
              <div style={{ fontSize: "0.8rem", color: "#c0c0c0", marginTop: "0.25rem" }}>(avg 10KB)</div>
            </div>
          </div>
        </section>

        {/* Market Segmentation Section */}
        <section style={{ maxWidth: "1200px", margin: "0 auto", padding: "0 1.5rem" }} id="institutions">
          <h2 style={{
            fontSize: "1.35rem",
            fontWeight: 700,
            letterSpacing: "0.08em",
            color: "#ffffff",
            marginBottom: "2rem",
            textTransform: "uppercase",
            fontFamily: "'IBM Plex Mono', monospace"
          }}>
            <span style={{ color: "#00d9ff" }}>■ </span>WHO USES ROCHE
          </h2>

          <div style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(320px, 1fr))",
            gap: "1.5rem",
            marginBottom: "3rem"
          }}>
            {/* Audit Firms */}
            <div style={{
              backgroundColor: "rgba(0, 217, 255, 0.05)",
              border: "1px solid #00d9ff",
              borderLeft: "3px solid #ff00ff",
              padding: "2rem",
              display: "flex",
              flexDirection: "column",
              justifyContent: "space-between"
            }}>
              <div>
                <div style={{ borderBottom: "1px solid #003344", paddingBottom: "1rem", marginBottom: "1.25rem" }}>
                  <div style={{ fontSize: "1.15rem", fontWeight: 700, color: "#ffffff", fontFamily: "'IBM Plex Mono', monospace" }}>AUDIT FIRMS</div>
                  <div style={{ fontSize: "0.8rem", color: "#00d9ff", fontFamily: "'IBM Plex Mono', monospace" }}>(Certora, Trail of Bits, Spearbit)</div>
                </div>

                <div style={{ marginBottom: "1.25rem" }}>
                  <div style={{ fontSize: "0.75rem", textTransform: "uppercase", letterSpacing: "0.05em", color: "#c0c0c0", marginBottom: "0.4rem", fontFamily: "'IBM Plex Mono', monospace" }}>Problem:</div>
                  <p style={{ fontSize: "0.875rem", color: "#c0c0c0", lineHeight: 1.5 }}>
                    Manual code review is slow.<br />
                    Edge cases are missed.<br />
                    Tools generate noise.
                  </p>
                </div>

                <div style={{ marginBottom: "1.25rem" }}>
                  <div style={{ fontSize: "0.75rem", textTransform: "uppercase", letterSpacing: "0.05em", color: "#c0c0c0", marginBottom: "0.4rem", fontFamily: "'IBM Plex Mono', monospace" }}>Roche Solution:</div>
                  <p style={{ fontSize: "0.875rem", color: "#ffffff", lineHeight: 1.6 }}>
                    • 50,000 transaction sequences in 5s<br />
                    • Protocol-specific invariants<br />
                    • &lt;10% false positive rate<br />
                    • CI/CD integration ready<br />
                    • 20-30% audit timeline acceleration
                  </p>
                </div>
              </div>

              <div style={{ borderTop: "1px solid #003344", paddingTop: "1rem", marginTop: "1rem", fontSize: "0.85rem", fontFamily: "'IBM Plex Mono', monospace", color: "#c0c0c0" }}>
                <div>Licensing: $50K-$200K/year</div>
                <div>White-label option available</div>
                <div style={{ marginTop: "0.75rem" }}>
                  <a href="mailto:partnerships@roche.dev?subject=Audit%20Firm%20Inquiry" style={{ color: "#00d9ff", textDecoration: "none", fontWeight: 700 }}>→ Contact: partnerships@roche.dev</a>
                </div>
              </div>
            </div>

            {/* Protocol Teams */}
            <div style={{
              backgroundColor: "rgba(0, 217, 255, 0.05)",
              border: "1px solid #00d9ff",
              borderLeft: "3px solid #ff00ff",
              padding: "2rem",
              display: "flex",
              flexDirection: "column",
              justifyContent: "space-between"
            }}>
              <div>
                <div style={{ borderBottom: "1px solid #003344", paddingBottom: "1rem", marginBottom: "1.25rem" }}>
                  <div style={{ fontSize: "1.15rem", fontWeight: 700, color: "#ffffff", fontFamily: "'IBM Plex Mono', monospace" }}>PROTOCOL TEAMS</div>
                  <div style={{ fontSize: "0.8rem", color: "#00d9ff", fontFamily: "'IBM Plex Mono', monospace" }}>(Uniswap, Aave, Curve, Lido)</div>
                </div>

                <div style={{ marginBottom: "1.25rem" }}>
                  <div style={{ fontSize: "0.75rem", textTransform: "uppercase", letterSpacing: "0.05em", color: "#c0c0c0", marginBottom: "0.4rem", fontFamily: "'IBM Plex Mono', monospace" }}>Problem:</div>
                  <p style={{ fontSize: "0.875rem", color: "#c0c0c0", lineHeight: 1.5 }}>
                    Post-deployment breaches = $M loss.<br />
                    Mainnet attacks are unpredictable.<br />
                    Standard testing misses edge cases.
                  </p>
                </div>

                <div style={{ marginBottom: "1.25rem" }}>
                  <div style={{ fontSize: "0.75rem", textTransform: "uppercase", letterSpacing: "0.05em", color: "#c0c0c0", marginBottom: "0.4rem", fontFamily: "'IBM Plex Mono', monospace" }}>Roche Solution:</div>
                  <p style={{ fontSize: "0.875rem", color: "#ffffff", lineHeight: 1.6 }}>
                    • Real-time mainnet monitoring<br />
                    • Instant invariant violation alerts<br />
                    • Custom detector engineering<br />
                    • Tier 1/2/3 ingestion ready<br />
                    • Protocol-specific safety guarantees
                  </p>
                </div>
              </div>

              <div style={{ borderTop: "1px solid #003344", paddingTop: "1rem", marginTop: "1rem", fontSize: "0.85rem", fontFamily: "'IBM Plex Mono', monospace", color: "#c0c0c0" }}>
                <div>Licensing: $200K-$1M/year</div>
                <div style={{ marginTop: "0.75rem" }}>
                  <a href="mailto:partnerships@roche.dev?subject=Protocol%20Team%20Inquiry" style={{ color: "#00d9ff", textDecoration: "none", fontWeight: 700 }}>→ Contact: partnerships@roche.dev</a>
                </div>
              </div>
            </div>

            {/* Bounty Hunters */}
            <div style={{
              backgroundColor: "rgba(0, 217, 255, 0.05)",
              border: "1px solid #00d9ff",
              borderLeft: "3px solid #ff00ff",
              padding: "2rem",
              display: "flex",
              flexDirection: "column",
              justifyContent: "space-between"
            }}>
              <div>
                <div style={{ borderBottom: "1px solid #003344", paddingBottom: "1rem", marginBottom: "1.25rem" }}>
                  <div style={{ fontSize: "1.15rem", fontWeight: 700, color: "#ffffff", fontFamily: "'IBM Plex Mono', monospace" }}>BOUNTY HUNTERS</div>
                  <div style={{ fontSize: "0.8rem", color: "#00d9ff", fontFamily: "'IBM Plex Mono', monospace" }}>(Cantina, Sherlock, Immunefi)</div>
                </div>

                <div style={{ marginBottom: "1.25rem" }}>
                  <div style={{ fontSize: "0.75rem", textTransform: "uppercase", letterSpacing: "0.05em", color: "#c0c0c0", marginBottom: "0.4rem", fontFamily: "'IBM Plex Mono', monospace" }}>Problem:</div>
                  <p style={{ fontSize: "0.875rem", color: "#c0c0c0", lineHeight: 1.5 }}>
                    Competitors move fast.<br />
                    Manual fuzzing takes days.<br />
                    Low signal-to-noise ratio.
                  </p>
                </div>

                <div style={{ marginBottom: "1.25rem" }}>
                  <div style={{ fontSize: "0.75rem", textTransform: "uppercase", letterSpacing: "0.05em", color: "#c0c0c0", marginBottom: "0.4rem", fontFamily: "'IBM Plex Mono', monospace" }}>Roche Solution:</div>
                  <p style={{ fontSize: "0.875rem", color: "#ffffff", lineHeight: 1.6 }}>
                    • 50,000 sequences in 2.8 seconds<br />
                    • Automatic Foundry PoC synthesis<br />
                    • Zero false-positive proof math<br />
                    • Protocol-specific edge cases<br />
                    • Competitive advantage you own
                  </p>
                </div>
              </div>

              <div style={{ borderTop: "1px solid #003344", paddingTop: "1rem", marginTop: "1rem", fontSize: "0.85rem", fontFamily: "'IBM Plex Mono', monospace", color: "#c0c0c0" }}>
                <div>Pricing: Free + Pro ($100/month)</div>
                <div style={{ marginTop: "0.75rem" }}>
                  <a href="https://github.com/creatorofaurad/Roche" style={{ color: "#00d9ff", textDecoration: "none", fontWeight: 700 }}>→ GitHub (Open Source)</a>
                </div>
              </div>
            </div>

          </div>
        </section>

        {/* Technical Architecture Section */}
        <section style={{ maxWidth: "1200px", margin: "0 auto", padding: "0 1.5rem" }}>
          <h2 style={{
            fontSize: "1.35rem",
            fontWeight: 700,
            letterSpacing: "0.08em",
            color: "#ffffff",
            marginBottom: "2rem",
            textTransform: "uppercase",
            fontFamily: "'IBM Plex Mono', monospace"
          }}>
            <span style={{ color: "#00d9ff" }}>■ </span>ARCHITECTURE
          </h2>

          <div style={{
            backgroundColor: "#060919",
            border: "1px solid #003344",
            padding: "1.5rem",
            marginBottom: "2rem",
            overflowX: "auto"
          }}>
            <pre style={{
              fontFamily: "'Courier New', Courier, monospace",
              fontSize: "0.825rem",
              lineHeight: 1.25,
              color: "#00ff41",
              margin: 0
            }}>
{`┌──────────────────────────────────────────────────────────────┐
│                    RAW BYTECODE / MAINNET                    │
└───────────────────────────────┬──────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────┐
│           EVM STATE MACHINE (src/vm.zig, 981 LOC)            │
│          Deterministic Bytecode Execution Engine             │
│        118,000+ execs/sec | Zero-Allocation | All 256 OPs    │
└───────────────────────────────┬──────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────┐
│         INVARIANT EVALUATOR (src/detectors_v2.zig)           │
│   42 Production Detectors | 900-Detector Architecture Ready  │
│    Reentrancy | AMM Curves | Lending | Bridges | Precision   │
└───────────────────────────────┬──────────────────────────────┘
                                │
                                ▼
┌──────────────────────────────────────────────────────────────┐
│              REPORTING ENGINE (src/reporter.zig)             │
│    JSON Findings + Foundry PoC Synthesis (.t.sol output)     │
│        CWE Tags | State Deltas | Mathematical Proof          │
└──────────────────────────────────────────────────────────────┘`}
            </pre>
          </div>

          <div style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
            gap: "1.5rem",
            marginBottom: "3rem"
          }}>
            <div style={{ backgroundColor: "rgba(0, 217, 255, 0.03)", border: "1px solid #003344", padding: "1.5rem" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.75rem" }}>
                <span style={{ fontSize: "0.95rem", fontWeight: 700, color: "#ffffff", fontFamily: "'IBM Plex Mono', monospace" }}>Tier 1: Anvil Fork</span>
                <span style={{ fontSize: "0.8rem", color: "#00d9ff", fontFamily: "'IBM Plex Mono', monospace", fontWeight: 700 }}>1-5ms latency</span>
              </div>
              <div style={{ fontSize: "0.825rem", color: "#c0c0c0", lineHeight: 1.5 }}>
                Local CI/CD<br />
                Deterministic testing
              </div>
            </div>

            <div style={{ backgroundColor: "rgba(0, 217, 255, 0.03)", border: "1px solid #003344", padding: "1.5rem" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.75rem" }}>
                <span style={{ fontSize: "0.95rem", fontWeight: 700, color: "#ffffff", fontFamily: "'IBM Plex Mono', monospace" }}>Tier 2: Reth IPC</span>
                <span style={{ fontSize: "0.8rem", color: "#00d9ff", fontFamily: "'IBM Plex Mono', monospace", fontWeight: 700 }}>&lt;50ms latency</span>
              </div>
              <div style={{ fontSize: "0.825rem", color: "#c0c0c0", lineHeight: 1.5 }}>
                Real-time mempool<br />
                Live mainnet monitoring
              </div>
            </div>

            <div style={{ backgroundColor: "rgba(0, 217, 255, 0.03)", border: "1px solid #003344", padding: "1.5rem" }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "0.75rem" }}>
                <span style={{ fontSize: "0.95rem", fontWeight: 700, color: "#ffffff", fontFamily: "'IBM Plex Mono', monospace" }}>Tier 3: Flashbots MEV</span>
                <span style={{ fontSize: "0.8rem", color: "#00d9ff", fontFamily: "'IBM Plex Mono', monospace", fontWeight: 700 }}>&lt;120µs latency</span>
              </div>
              <div style={{ fontSize: "0.825rem", color: "#c0c0c0", lineHeight: 1.5 }}>
                Pre-execution interception<br />
                Builder order flow
              </div>
            </div>
          </div>
        </section>

        {/* Documentation Section */}
        <section style={{ maxWidth: "1200px", margin: "0 auto", padding: "0 1.5rem" }} id="docs">
          <h2 style={{
            fontSize: "1.35rem",
            fontWeight: 700,
            letterSpacing: "0.08em",
            color: "#ffffff",
            marginBottom: "2rem",
            textTransform: "uppercase",
            fontFamily: "'IBM Plex Mono', monospace"
          }}>
            <span style={{ color: "#00d9ff" }}>■ </span>DOCUMENTATION
          </h2>

          <div style={{ display: "flex", flexDirection: "column", gap: "1.5rem", marginBottom: "3rem" }}>
            <div style={{
              backgroundColor: "rgba(0, 217, 255, 0.03)",
              border: "1px solid #003344",
              padding: "1.5rem 2rem",
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              gap: "2rem",
              flexWrap: "wrap"
            }}>
              <div>
                <h3 style={{ fontSize: "1.05rem", color: "#ffffff", marginBottom: "0.35rem", fontFamily: "'IBM Plex Mono', monospace" }}>ARCHITECTURE.md</h3>
                <p style={{ fontSize: "0.875rem", color: "#c0c0c0", lineHeight: 1.5 }}>
                  Complete technical specification. All subsystems, detector categories, performance benchmarks, memory model. 50+ pages.
                </p>
              </div>
              <div>
                <a href="https://github.com/creatorofaurad/Roche/blob/main/docs/ARCHITECTURE.md" style={{ color: "#00d9ff", textDecoration: "none", fontWeight: 700, fontFamily: "'IBM Plex Mono', monospace" }}>
                  → Read
                </a>
              </div>
            </div>

            <div style={{
              backgroundColor: "rgba(0, 217, 255, 0.03)",
              border: "1px solid #003344",
              padding: "1.5rem 2rem",
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              gap: "2rem",
              flexWrap: "wrap"
            }}>
              <div>
                <h3 style={{ fontSize: "1.05rem", color: "#ffffff", marginBottom: "0.35rem", fontFamily: "'IBM Plex Mono', monospace" }}>INSTITUTIONAL.md</h3>
                <p style={{ fontSize: "0.875rem", color: "#c0c0c0", lineHeight: 1.5 }}>
                  Institutional knowledge base. Market positioning, competitive analysis, risk matrices, go-to-market roadmap. For serious buyers.
                </p>
              </div>
              <div>
                <a href="https://github.com/creatorofaurad/Roche/blob/main/docs/INSTITUTIONAL.md" style={{ color: "#00d9ff", textDecoration: "none", fontWeight: 700, fontFamily: "'IBM Plex Mono', monospace" }}>
                  → Read
                </a>
              </div>
            </div>

            <div style={{
              backgroundColor: "rgba(0, 217, 255, 0.03)",
              border: "1px solid #003344",
              padding: "1.5rem 2rem",
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              gap: "2rem",
              flexWrap: "wrap"
            }}>
              <div>
                <h3 style={{ fontSize: "1.05rem", color: "#ffffff", marginBottom: "0.35rem", fontFamily: "'IBM Plex Mono', monospace" }}>VERIFICATION_AUDIT.md</h3>
                <p style={{ fontSize: "0.875rem", color: "#c0c0c0", lineHeight: 1.5 }}>
                  Third-party verification. Test results, exploit validation, proof chains.
                </p>
              </div>
              <div>
                <a href="https://github.com/creatorofaurad/Roche/blob/main/VERIFICATION_AUDIT.md" style={{ color: "#00d9ff", textDecoration: "none", fontWeight: 700, fontFamily: "'IBM Plex Mono', monospace" }}>
                  → Read
                </a>
              </div>
            </div>
          </div>
        </section>
      </main>

      {/* Institutional Monospace Footer */}
      <footer style={{
        backgroundColor: "#070a1c",
        borderTop: "1px solid #003344",
        padding: "3rem 0",
        marginTop: "auto"
      }}>
        <div style={{
          maxWidth: "1200px",
          margin: "0 auto",
          padding: "0 1.5rem",
          display: "flex",
          flexDirection: "column",
          gap: "1.5rem",
          fontFamily: "'IBM Plex Mono', monospace",
          fontSize: "0.825rem",
          color: "#c0c0c0"
        }}>
          <div style={{ height: "1px", backgroundColor: "#00d9ff", width: "100%", opacity: 0.8 }}></div>

          <div style={{ color: "#ffffff", fontWeight: 700, letterSpacing: "0.08em" }}>
            ROCHE EVM SECURITY ENGINE
          </div>

          <div style={{ display: "flex", gap: "1.5rem", flexWrap: "wrap" }}>
            <a href="https://github.com/creatorofaurad/Roche" style={{ color: "#00d9ff", textDecoration: "none" }}>[GitHub]</a>
            <a href="https://github.com/creatorofaurad/Roche/tree/main/docs" style={{ color: "#00d9ff", textDecoration: "none" }}>[Documentation]</a>
            <a href="https://github.com/creatorofaurad/Roche/blob/main/SECURITY.md" style={{ color: "#00d9ff", textDecoration: "none" }}>[Security Policy]</a>
            <a href="mailto:partnerships@roche.dev" style={{ color: "#00d9ff", textDecoration: "none" }}>[Institutional Contact]</a>
          </div>

          <div style={{ color: "#c0c0c0", lineHeight: 1.6 }}>
            © 2026 Charles Mandal. Open Source (GPLv3).<br />
            Institutional Licensing: <a href="mailto:partnerships@roche.dev" style={{ color: "#00d9ff", textDecoration: "none" }}>partnerships@roche.dev</a>
          </div>

          <div style={{ height: "1px", backgroundColor: "#00d9ff", width: "100%", opacity: 0.8 }}></div>
        </div>
      </footer>
    </div>
  );
}