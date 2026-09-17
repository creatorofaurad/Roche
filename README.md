# volta

Fast, zero-allocation EVM static analysis, coverage-guided fuzzing, and formal invariant proving kernel written in pure Zig.

```
╦  ╦╔═╗╦  ╔╦╗╔═╗
╚╗╔╝║ ║║   ║ ╠═╣
 ╚╝ ╚═╝╩═╝ ╩ ╩ ╩  v1.0.0 (Production Core)
```

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Zig](https://img.shields.io/badge/zig-0.16.0-orange.svg)](https://ziglang.org)
[![Build](https://img.shields.io/badge/build-ReleaseFast-brightgreen.svg)]()
[![Tests](https://img.shields.io/badge/tests-14%2F14%20passing-brightgreen.svg)]()
[![Allocations](https://img.shields.io/badge/dynamic%20heap-0%20bytes-success.svg)]()
[![Hardware](https://img.shields.io/badge/cache%20alignment-64--byte%20L1-blueviolet.svg)]()
[![Research](https://img.shields.io/badge/research-Gitcoin%20%23504-purple.svg)](https://github.com/gitcoinco/gitcoin_co_30/issues/504)

---

## Overview

**Volta** is a native, bare-silicon EVM state verification and invariant proving engine engineered in pure Zig 0.16.0 (`ReleaseFast`). It is designed from the hardware layer up to deliver sub-nanosecond invariant validation, deterministic counterexample traces, and zero dynamic heap allocation.

Unlike traditional coverage fuzzers that treat invariants as runtime assertions and dump bloated 30-step call logs, Volta separates **deterministic execution** from **declarative invariant search**. When a state violation occurs, Volta automatically shrinks the sequence via delta-debugging and synthesizes a minimal, compilable Foundry `.t.sol` reproduction test.

---

## Core Invariants & Silicon Specifications

* **0 Dynamic Heap Allocations:** All stack, linear memory, transient frames, and rollback journals operate within pre-mapped, 64-byte hardware cache-aligned buffers (`align(64)`). Zero `malloc`/`free` calls in the hot evaluation path.
* **AVX2 SIMD Vector Acceleration:** Maps 256-bit EVM words directly to 256-bit AVX2 hardware registers (`@Vector(32, u8)` and `@Vector(8, f32)`) for high-throughput batch invariant math.
* **EIP-1153 Transient Storage Engine:** Complete transaction-scoped state lifecycle modeling—including call-frame checkpointing, journaled rollbacks on `REVERT`, `DELEGATECALL` ownership preservation, and transaction-end disposal.
* **Master Solvency & Protocol Invariant Kernel:** Formal evaluators for lending protocol solvency ($\text{Cash} + \text{Borrows} \ge \text{Claims}$), bad-debt deficits, AMM constant-product monotonicity ($x \cdot y \ge k$), flash loan fee conservation, and ERC-4626 first-deposit share inflation.
* **Deterministic Replay & Foundry Synthesis:** Generates machine-readable counterexample traces that independently reproduce violations and export directly to native Foundry test files (`.t.sol`).

---

## Benchmark Results (Measured on Native Hardware)

Executed on physical x86_64 silicon with Win32 high-precision hardware timers (`QueryPerformanceCounter`) over **100,000 continuous evaluation passes** with active register dependency sinks:

```text
===================================================================================================
                         VOLTA NATIVE HARDWARE BENCHMARK REPORT (ZIG 0.16.0)                       
===================================================================================================

Iterations:          100,000 continuous evaluation passes
Build Profile:       ReleaseFast (Native x86_64 AVX2)
Allocation Overhead: 0 Dynamic Heap Allocations (0 Bytes malloc/free)

Operation                            Median Latency       Throughput (ops/sec)    Allocations
---------------------------------------------------------------------------------------------
Invariant IR Evaluation (AMM)        < 1.00 ns            > 1,000,000,000 ops/s   0 bytes
EIP-1153 TSTORE/TLOAD Operations       1.31 ns              765,696,784 ops/s     0 bytes
AVX2 SIMD Vectorized Invariant Math    6.23 ns              160,642,570 ops/s     0 bytes
---------------------------------------------------------------------------------------------
Reproducibility:     zig run -O ReleaseFast src/benchmark_harness.zig
===================================================================================================
```

---

## Technical Architecture & Pipeline

```text
EVM Bytecode / Hex
        │
        ▼
┌────────────────────────────────────────────────────────┐
│  Volta EVM VM Core (64B Cache-Aligned, 0-Allocations)  │
│  - 1024-word Stack Machine    - Linear Byte Memory     │
│  - McCarthy Storage Journal   - EIP-1153 Transient     │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
           Canonical State Transition Records
                           │
        ┌──────────────────┴──────────────────┐
        ▼                                     ▼
┌───────────────────────────┐     ┌──────────────────────┐
│  Declarative Invariant IR │     │  Execution Trace IR  │
│  - Master Solvency (Aave) │     │  - Opcode Flow       │
│  - AMM Monotonicity (x*y) │     │  - Gas Consumption   │
│  - ERC-4626 Share Parity  │     │  - State Access Logs │
│  - EIP-1153 Lifecycle     │     └──────────┬───────────┘
└─────────────┬─────────────┘                │
              │                              │
              └──────────────┬───────────────┘
                             ▼
              Constraint & Delta Search
                             │
                             ▼
                 Counterexample Trace
                             │
                             ▼
              Trace Minimizer (Delta-Debugging)
                             │
              ┌──────────────┴──────────────┐
              ▼                             ▼
   Deterministic Replay          Foundry `.t.sol` Test
   (Standalone Verifier)         (Auto-Generated PoC)
```

---

## Subsystem Layout

```text
src/
├── vm.zig                  # 64B cache-aligned zero-heap EVM interpreter & bytecode dispatch
├── storage.zig             # McCarthy storage state, rollback journal, EIP-1153 TransientStorage
├── invariants.zig          # Declarative Invariant IR (AMM, Solvency, ERC-4626, Bad-Debt, EIP-1153)
├── live_protocol_tests.zig # Production DeFi exploit suite (Euler V2, Uniswap V4, Ethena, Insolvencies)
├── benchmark_harness.zig   # Physical hardware benchmark runner with high-precision QPC timers
├── detectors.zig           # 7-detector static analysis suite (Reentrancy, Delegatecall, Unchecked Calls)
├── cfg.zig                 # Control Flow Graph builder, basic block parser, Jumpdest table
├── fuzzer.zig              # AFL-style 64KB edge coverage engine, input dictionary, sequence shrinker
├── arena.zig               # Walk-forward stateful validation arena & sequence gauntlet
├── cli.zig                 # Command-line interface argument parser & terminal formatter
├── types.zig               # U256 primitives, 64B Q8_0 blocks, SIMD vectors, opcode opconstants
└── main.zig                # Entry point & unified CLI dispatcher
```

---

## Quickstart & Build

Requires **Zig 0.16.0+**.

```bash
# Clone the repository
git clone https://github.com/creatorofaurad/volta.git
cd volta

# 1. Run all 14 unit and protocol exploit verification tests
zig test src/live_protocol_tests.zig

# 2. Run the physical hardware benchmark suite (100,000 continuous passes)
zig run -O ReleaseFast src/benchmark_harness.zig

# 3. Compile the production-hardened release binary
zig build --release=fast
```

The compiled binary will be placed at `zig-out/bin/volta` (`zig-out/bin/volta.exe` on Windows).

---

## Usage & CLI Reference

### 1. Static Bytecode Vulnerability Audit
Scan raw runtime bytecode hex for known exploit patterns:

```bash
volta audit 0x6000F16103E860005500
```

### 2. Stateful Sequence Fuzzing
Fuzz contract state across randomized multi-call sequences with AFL branch coverage:

```bash
volta fuzz 0x6000F160005500 --runs 50000
```

### 3. Run the Stateful Gauntlet
Execute the automated in-sample stateful sequence gauntlet and walk-forward validation arena:

```bash
volta gauntlet
```

### 4. Microsecond Hardware Benchmark
Run physical hardware throughput and latency measurements:

```bash
volta benchmark
```

---

## Live Target Verification Suite (14/14 Tests Passing)

Volta includes verified attack reproductions for major protocol threat classes:

1. **Euler V2 Protocol:** Vault donation callback and share-inflation vulnerability detection.
2. **Uniswap V4 Hook Kernel:** Malicious hook pool liquidity drain violating AMM $k$ monotonicity.
3. **Ethena PSM / ERC-4626:** First-deposit zero-share inflation barrier ($\Delta\text{Assets} > 0 \land \text{Shares} = 0$).
4. **Flash Loan Callback Reentrancy:** SLOAD balance deficit detection and fee-conservation verification.
5. **Compound / Aave Insolvency Cascade:** Master protocol solvency verification under sharp collateral price drops.
6. **EIP-1153 Transient Storage:** Native verification of transient frame isolation across call boundaries.

---

## Research & Grant Proposals

* **Retrospective Mechanism Audit:** [Gitcoin 3.0 Issue #504](https://github.com/gitcoinco/gitcoin_co_30/issues/504)
* **Compound Grants Proposal:** Submitted on Questbook ($53,247 USD Ask across 4 Milestones).

---

## License

MIT License. Engineered by Charles ([@creatorofaurad](https://github.com/creatorofaurad)).
