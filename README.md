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
[![Allocations](https://img.shields.io/badge/dynamic%20heap-0%20bytes-success.svg)]()
[![Hardware](https://img.shields.io/badge/cache%20alignment-64--byte%20L1-blueviolet.svg)]()
[![Research](https://img.shields.io/badge/research-Gitcoin%20%23504-purple.svg)](https://github.com/gitcoinco/gitcoin_co_30/issues/504)

---

## What is Volta?

Volta is a native, bare-silicon EVM state verification and invariant proving engine engineered in pure Zig 0.16.0 (`ReleaseFast`). It is designed from the hardware layer up to deliver sub-microsecond invariant validation, deterministic counterexample traces, and zero dynamic heap allocation.

* **0 Dynamic Heap Allocations:** All stack, memory, and rollback structures operate in pre-mapped, 64-byte hardware cache-aligned buffers (`align(64)`).
* **AVX2-Accelerated Operations:** Maps 256-bit EVM words directly to 256-bit AVX2 hardware registers (`@Vector(32, u8)` and `@Vector(8, f32)`) for sub-microsecond math.
* **EIP-1153 Transient Storage Prover:** Complete transaction-scoped state lifecycle modeling (checkpointing, nested `REVERT` rollbacks, and frame disposal) to catch transient reentrancy bugs in Cancun/Prague protocols.
* **Master Solvency & Protocol Invariant Engine:** Formal evaluators for lending solvency ($\text{Cash} + \text{Borrows} \ge \text{Claims}$), bad-debt deficits, AMM constant-product monotonicity ($x \cdot y \ge k$), and ERC-4626 first-deposit inflation.

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

## Architecture Pipeline

```text
EVM Bytecode
    │
    ▼
┌──────────────┐
│  Volta VM    │
└──────┬───────┘
       │
       ▼
Canonical State Transition Records
       │
    ┌──┴──────────┐
    ▼             ▼
Invariant IR   Trace IR
    │             │
    └──────┬──────┘
           ▼
    Search / Constraints
           │
           ▼
    Counterexample Trace
           │
           ▼
    Trace Minimizer
           │
    ┌──────┴──────────┐
    ▼                 ▼
Deterministic      Foundry .t.sol
Replay             Synthesis
```

---

## Quickstart & Build

Requires **Zig 0.16.0+**.

```bash
git clone https://github.com/creatorofaurad/volta.git
cd volta

# 1. Run all 14 unit and protocol attack tests
zig test src/live_protocol_tests.zig

# 2. Run the native 100,000-pass hardware benchmark
zig run -O ReleaseFast src/benchmark_harness.zig

# 3. Build optimized static binary
zig build -Doptimize=ReleaseFast
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

## License

MIT License. Engineered by Charles ([@creatorofaurad](https://github.com/creatorofaurad)).
