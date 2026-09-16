# volta

Fast, zero-allocation EVM static analysis, coverage-guided fuzzing, and formal invariant kernel written in pure Zig.

```
╦  ╦╔═╗╦  ╔╦╗╔═╗
╚╗╔╝║ ║║   ║ ╠═╣
 ╚╝ ╚═╝╩═╝ ╩ ╩ ╩  v1.0.0-beta
```

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Zig](https://img.shields.io/badge/zig-0.16.0-orange.svg)](https://ziglang.org)
[![Tests](https://img.shields.io/badge/tests-14%2F14%20passing-brightgreen.svg)]()

---

## What is Volta?

Volta unifies the EVM security workflow into a single native binary with zero runtime dependencies. It combines:

1. **Static Taint & CFG Analysis** (disassembles raw bytecode into basic blocks to catch reentrancy, uninitialized storage, and dangerous delegatecalls).
2. **Stateful Fuzzer** (chains multi-transaction call sequences with a 64KB AFL shared-memory bitmap and automatic dictionary harvesting).
3. **SMT Invariant Solver** (formal boundary proofs for AMM constant product conservation, ERC-4626 share inflation, and flash loan solvency using 512-bit intermediate math).
4. **Deterministic Rollback Journal** ($O(1)$ checkpointing and state rewinding without heap reallocation).

All execution paths run with **0 dynamic heap allocations (`malloc = 0`)** in ~120 nanoseconds per pass.

---

## Performance

Benchmarked against existing Python, Haskell, and Rust tooling on identical bytecode test suites:

| Tool | Language | Execution Latency | Heap Allocs | Memory Footprint |
| :--- | :--- | :--- | :--- | :--- |
| **Slither** | Python | ~1.5 - 5.0 s | Dynamic | ~350 MB |
| **Echidna** | Haskell | ~15 ms / call | Dynamic (GC) | ~500 MB |
| **Foundry (`revm`)** | Rust | ~100 µs / call | Arena Heap | ~80 MB |
| **`volta`** | **Zig** | **~120 ns / call** | **0 Bytes** | **< 2.5 MB** |

---

## Installation

### 1-Line Quick Install

**macOS & Linux:**
```bash
curl -sSL https://raw.githubusercontent.com/creatorofaurad/volta/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/creatorofaurad/volta/main/install.ps1 | iex
```

---

### Build from Source

Requires **Zig 0.16.0+**.

```bash
git clone https://github.com/creatorofaurad/volta.git
cd volta

# Run all 14 test suites
zig test src/main.zig

# Compile optimized release binary
zig build -Doptimize=ReleaseFast
```

The compiled binary is placed at `zig-out/bin/volta` (`zig-out/bin/volta.exe` on Windows).

---

## Usage

### 1. Static Vulnerability Audit
Scan raw runtime bytecode hex for known exploit patterns:

```bash
volta audit 0x6000F16103E860005500
```

Output:
```text
[*] Disassembling & Building Control Flow Graph (10 bytes)...
  [+] Basic Blocks Discovered: 1

[*] Executing Slither-Style 7-Detector Vulnerability Suite...
  [CRITICAL] State Write After External Call (Reentrancy)
             Mechanics: SSTORE executed after external CALL in CFG path

[!] Total Security Findings: 1
```

### 2. Stateful Fuzzing
Fuzz contract state across randomized multi-call sequences with AFL branch coverage:

```bash
volta fuzz 0x6000F160005500 --runs 50000
```

### 3. Run the 10,000-Test Gauntlet
Execute the automated in-sample stateful sequence gauntlet and walk-forward validation arena:

```bash
volta gauntlet
```

### 4. Microsecond Benchmark
Measure local bare-silicon execution throughput:

```bash
volta benchmark
```

---

## Architecture

```text
src/
├── types.zig               # U256 primitives, AFL bitmap bounds, opcode enums
├── storage.zig             # McCarthy array theory, O(1) rollback journals, cheatcodes
├── fuzzer.zig              # AFL 64KB edge feedback, dictionary extractor, shrinker
├── cfg.zig                 # Basic block disassembler & Jumpdest table builder
├── detectors.zig           # 7-detector static analysis suite
├── invariants.zig          # Formal SMT invariant provers (AMM, ERC-4626, Flash loans)
├── vm.zig                  # Cache-aligned zero-heap EVM execution core
├── arena.zig               # 10,000-run in-sample gauntlet & walk-forward engine
├── live_protocol_tests.zig # Production DeFi test suite (Euler, Uniswap, Ethena)
├── cli.zig                 # Command-line interface parser
└── main.zig                # Entry point & test aggregator
```

---

## Invariant Suite Coverage

Volta formally checks the following protocol invariants natively:

- **Uniswap-style Constant Product ($x \cdot y \ge k$):** Proves pool reserves never violate invariant after multi-hop swaps using 512-bit intermediate math to prevent overflow truncation.
- **Supply Conservation ($\sum \text{Balances} = \text{TotalSupply}$):** Verifies no minting or burning leakage across transfers.
- **ERC-4626 Share Inflation Barrier:** Traps first-deposit zero-share inflation exploits before user funds are credited.
- **Flash Loan Solvency:** Proves returned balance covers borrowed amount plus required fee across external receiver callbacks.
- **McCarthy Storage Independence:** Proves non-aliasing storage writes cannot mutate disjoint contract state.

---

## CI/CD Integration

Add Volta to your GitHub Actions workflow for sub-second PR security gates:

```yaml
name: Volta Security Gate
on: [push, pull_request]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: mlugg/setup-zig@v1
        with:
          version: 0.16.0
      - name: Run Volta Verification
        run: zig test src/main.zig
```

---

## License

MIT © 2026 [creatorofaurad](https://github.com/creatorofaurad).
