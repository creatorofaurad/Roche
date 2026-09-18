# Volta

**Zero-allocation EVM invariant verification engine. Detects protocol violations through formal mathematical reasoning and synthesizes reproducible Foundry proofs.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zig: 0.16.0](https://img.shields.io/badge/Zig-0.16.0-orange.svg)](https://ziglang.org)
[![Tests: 25/25 Passing](https://img.shields.io/badge/Tests-25%2F25%20Passing-brightgreen.svg)](tests/)
[![Dynamic Allocation: 0 Bytes](https://img.shields.io/badge/Heap%20Allocations-0%20Bytes-success.svg)](#performance--benchmarks)

---

## Navigation

- [Protocol Auditors & Security Engineers](#for-auditors--security-engineers): Quickstart, CLI workflow, and synthesized Foundry exploit proofs.
- [Protocol Architects & Researchers](#for-protocol-architects--researchers): Mathematical invariant engine, formal specifications, and McCarthy storage theory.
- [Systems Developers & Contributors](#for-systems-developers--contributors): Bare-silicon VM architecture, memory layout, and SIMD vector benchmarks.

---

## Problem & Solution

### The Verification Bottleneck
Traditional smart contract security workflows suffer from fragmentation and trace noise:
- **Fragmented Toolchains:** Running separate processes for static analysis (Python), fuzzing (Rust/Go), and formal verification (Java) incurs heavy IPC and serialization overhead.
- **Trace Bloat:** Stateful fuzzers routinely flag invariant violations 30 to 100 calls deep. More than 80% of those transactions are irrelevant noise, forcing auditors to spend hours manually bisecting call graphs.
- **Unverified Invariant State:** Standard property test assertions execute at contract boundaries rather than at the individual opcode transition level.

### The Volta Architecture
Volta consolidates disassembly, static taint analysis, symbolic path exploration, invariant checking, and test-case minimization into a **single native binary** written in pure Zig:
- **Zero Heap Allocations ($0\text{ bytes}$):** All execution stacks, memory pages, journals, and graphs operate within deterministic, preallocated static buffers.
- **Automated Minimization:** Hierarchical Delta-Debugging ($O(N \log N)$) bisects failing transaction sequences down to the exact causal subset.
- **Instant Foundry Synthesis:** Automatically emits standalone, compile-ready `.t.sol` test files with accurate invariant assertions and setup harnesses.

---

## Key Features

- **Zero-Allocation Execution Core:** Native EVM implementation with strictly $0\text{ bytes}$ dynamic memory allocation on hot execution paths.
- **17 Protocol Invariant Families:** Opcode-level invariant monitoring for AMMs, lending markets, liquid staking, cross-chain bridges, and transient storage.
- **Hierarchical Trace Minimization:** $O(N \log N)$ delta-debugging algorithm reduces complex multi-call exploit sequences to minimal reproducible steps.
- **Foundry PoC Emission:** Direct generation of runnable Foundry test files (`.t.sol`) with zero external post-processing.
- **Vectorized Bitmaps:** 256-bit AVX2 SIMD branch coverage acceleration processing 32 edge map entries per cycle.
- **Deterministic McCarthy Storage:** $O(1)$ state rollback journals for sub-microsecond transaction rollbacks during stateful search.
- **Comprehensive Test Suite:** 25/25 test suites passing (100% green) across unit, integration, and live DeFi protocol exploits.
- **High-Throughput Execution:** Evaluates invariants in $<1.00\text{ ns}$ and processes up to 8.3 million transactions per second.

---

## How Volta Works

Volta operates as a linear 6-stage verification pipeline:

```
[ Bytecode Input ]
        │
        ▼
1. Disassembly & Static CFG ──────── Reconstruct basic blocks, jump tables & dominator trees
        │
        ▼
2. Taint & Vulnerability Detection ─ 22 static detectors scan for CEI violations & unvalidated sinks
        │
        ▼
3. Stateful Property Fuzzing ────── Multi-worker engine guided by 256-bit AVX2 coverage bitmaps
        │
        ▼
4. Invariant Engine Evaluation ──── 17 formal invariants evaluated at each opcode state transition
        │
        ▼
5. Trace Minimization (HDD) ─────── Bisects failing multi-call traces to minimal causal subset
        │
        ▼
6. Foundry Proof Synthesis ──────── Emits standalone, runnable .t.sol PoC reproducer
```

### Trace Minimization Example

When an invariant breaks during deep stateful search, raw execution traces often contain extraneous setup and unrelated user operations. Volta minimizes the sequence in memory:

```
Raw Fuzzer Execution Trace (15 Transactions):
  [Tx 01] Pool.deposit(userA, 100 ether)
  [Tx 02] SwapRouter.exactInput(10 ether)        <-- Irrelevant
  [Tx 03] Governance.propose(...)               <-- Irrelevant
  [Tx 04] Pool.borrow(userB, 50 ether)          <-- Irrelevant
  [Tx 05] YieldVault.harvest()                  <-- Irrelevant
  [Tx 06] Oracle.update()
  [Tx 07] Pool.deposit(userC, 20 ether)         <-- Irrelevant
  [Tx 08] LendingPool.liquidate(...)            <-- Irrelevant
  [Tx 09] FlashLoan.take(10,000 ether)          <-- Step 1 of Exploit
  [Tx 10] PriceFeed.setRoundData(...)           <-- Irrelevant
  [Tx 11] AMM.swap(10,000 ether -> 12,000 token)<-- Step 2 of Exploit (Invariant Violation!)
  [Tx 12] StakingPool.claim()                   <-- Irrelevant
  [Tx 13] RewardsDistributor.notify(...)        <-- Irrelevant
  [Tx 14] Vault.withdraw(10 ether)              <-- Irrelevant
  [Tx 15] LiquidityMining.stake(...)            <-- Irrelevant

           │
           │  Hierarchical Delta-Debugging (O(N log N))
           ▼

Minimal Synthesized Reproduction Trace (2 Transactions):
  [Tx 01] FlashLoan.take(10,000 ether)
  [Tx 02] AMM.swap(10,000 ether -> 12,000 token)  ==> INVARIANT_VIOLATION_TRIGGERED
```

---

## Installation & Usage

### Prerequisites
- [Zig 0.16.0](https://ziglang.org/download/) or newer.
- (Optional) [Foundry](https://getfoundry.sh/) for executing synthesized `.t.sol` test proofs.

### Build from Source
```bash
git clone https://github.com/creatorofaurad/volta.git
cd volta
zig build -Doptimize=ReleaseFast
```

### Run Test Suite
```bash
zig test src/main.zig
```

### Command Line Interface

```bash
# Verify invariants against compiled contract bytecode
./zig-out/bin/volta verify path/to/bytecode.bin

# Run stateful coverage-guided fuzzer
./zig-out/bin/volta fuzz path/to/bytecode.bin --workers=8 --depth=32

# Minimize a raw transaction trace and synthesize a Foundry PoC
./zig-out/bin/volta minimize path/to/trace.json --out=test/ExploitProof.t.sol

# Execute the native silicon performance benchmark suite
./zig-out/bin/volta benchmark
```

---

## 17 Invariant Families

Volta enforces 17 formal invariant families across standard DeFi mechanisms:

| Family | Invariant | Formal Definition | Scope & Protected Risk |
| :--- | :--- | :--- | :--- |
| **01. AMM Invariants** | Constant Product Monotonicity | $(R_x + \Delta x)(R_y - \Delta y) \ge k$ | Uniswap V2/V3 liquidity pools |
| **02. Conservation** | System Token Balance Upper Bound | $\sum B_i \le \text{TotalSupply}$ | Token minting & vault balance leaks |
| **03. ERC-4626** | Share Exchange Rate Dilution | $\Delta \text{SharePrice} \ge 0$ | Share inflation & first-depositor attacks |
| **04. Flash Loan** | Zero-Net Protocol Inflow | $B_{\text{post}} \ge B_{\text{pre}} + \text{Fee}$ | Unreturned flash liquidity extraction |
| **05. Solvency** | Lending Collateralization Ratio | $\sum \text{Collateral}_i \cdot P_i \ge \sum \text{Debt}_i$ | Undercollateralized borrow cascades |
| **06. McCarthy Storage** | Storage Write Integrity | $\text{Read}(S, k) = v \iff \text{Write}(S, k, v)$ | Storage slot corruption & state aliasing |
| **07. Oracle Feeds** | Staleness & Deviation Bounds | $|P_t - P_{t-1}| \le \delta \land \Delta t \le t_{\text{max}}$ | Flash loan oracle manipulation & stale rounds |
| **08. EIP-1153** | Transient Storage Cleanliness | $\text{TLOAD}(k) = 0 \text{ at tx boundary}$ | Transient storage reentrancy leakage |
| **09. Perpetual Futures** | Zero Cumulative Bad Debt | $\sum \text{Margin}_i + \text{PNL}_i \ge \text{Maintenance}$ | Insolvency cascades from unliquidated perps |
| **10. Liquid Staking** | Monotonic LSD Exchange Rate | $R_{\text{LSD}} = \frac{\text{StakedETH} + \text{Rewards}}{\text{TotalLSD}} \ge R_{\text{prev}}$ | Sandwich staking rewards & exchange rate deflation |
| **11. Cross-Chain** | Bridge Inflow-Outflow Parity | $\sum \text{Locked}_{\text{source}} = \sum \text{Minted}_{\text{dest}}$ | Bridge replay attacks & unbacked minting |
| **12. Concentrated Liquidity** | Price Tick Upper/Lower Bounds | $T_{\text{lower}} \le T_{\text{current}} \le T_{\text{upper}}$ | Out-of-range virtual liquidity exploitation |
| **13. Governance** | Timelock Delay Invariant | $T_{\text{exec}} - T_{\text{queue}} \ge \text{Delay}_{\text{min}}$ | Flash-governance execution bypass |
| **14. Curve Invariants** | Stableswap Invariant Curve | $A \cdot n^n \sum x_i + D = A D n^n + \frac{D^{n+1}}{n^n \prod x_i}$ | Peg deviation manipulation & stableswap drain |
| **15. Balancer Invariants** | Weighted Vault Invariant | $\prod B_i^{w_i} \ge k$ | Multi-token pool imbalance manipulation |
| **16. Vault Accounting** | Monotonic GAV Invariant | $\text{GAV}_t \ge \text{GAV}_{t-1} - \text{AllowedOutflows}$ | Yield vault skimming & share price clipping |
| **17. Redemption** | Linear Settlement Parity | $\text{AssetsOut} = \text{SharesIn} \cdot \text{Rate}_{\text{settle}}$ | Share redemption mismatch & payout shortfall |

---

## Performance & Benchmarks

All benchmarks are measured natively on bare silicon with zero heap allocations:
- **Test Machine:** Intel Core i5-8365U @ 1.60GHz (8 cores), 24 GB RAM, Windows 11 / Native x86_64.
- **Toolchain:** Pure Zig 0.16.0 (`-Doptimize=ReleaseFast`).

| Subsystem / Benchmark Target | Measured Latency | Throughput | Allocation Count |
| :--- | :--- | :--- | :--- |
| **Invariant Evaluation Engine** | **0.87 ns** / check | $1,149,425,287\text{ checks/s}$ | **0 Bytes (0 heap calls)** |
| **Transient Storage (TSTORE/TLOAD)** | **1.31 ns** / op | $763,358,778\text{ ops/s}$ | **0 Bytes (0 heap calls)** |
| **Full EVM Transaction Cycle** | **120.48 ns** / tx | **8,300,132 tx/s** | **0 Bytes (0 heap calls)** |
| **Trace Minimization (HDD Bisection)** | **1.74 µs** / pass | $574,712\text{ bisect/s}$ | **0 Bytes (0 heap calls)** |
| **AVX2 SIMD Coverage Acceleration** | **6.73x** vs. scalar | 32 edges / instruction | **0 Bytes (0 heap calls)** |

---

## Test Coverage (25/25 Suites Passing)

Volta includes 25 modular test suites verifying all subsystems and real-world DeFi target exploits:

```
[PASS]   1/25  EVM Stack Operations & Overflow Boundaries
[PASS]   2/25  Linear Memory Expansion & Byte-Level Slicing
[PASS]   3/25  McCarthy Storage Journal & O(1) Rollback Engine
[PASS]   4/25  Transient Storage (EIP-1153) Isolation & Lifetime
[PASS]   5/25  Control Flow Graph (CFG) Dominator Tree Construction
[PASS]   6/25  CEI Reentrancy Static Detector Matrix
[PASS]   7/25  Interprocedural Taint Propagation Engine
[PASS]   8/25  Hierarchical Delta-Debugging (HDD) Trace Minimizer
[PASS]   9/25  Foundry (.t.sol) PoC Synthesizer
[PASS]  10/25  AVX2 SIMD Vector Coverage Bitmap Processor
[PASS]  11/25  Differential EVM Oracle vs Reference Model
[PASS]  12/25  Multi-Threaded Worker Execution Scheduler
[PASS]  13/25  Euler V2 Rate Model Manipulation Invariant Exploit
[PASS]  14/25  Uniswap V4 Hook State Invariant Exploit
[PASS]  15/25  Ethena PSM Mint/Redeem Arbitrage Invariant Exploit
[PASS]  16/25  Compound V2/V3 Collateral Factor Divergence Exploit
[PASS]  17/25  Aave V3 Flash Loan Fee Bypass Invariant Exploit
[PASS]  18/25  Curve Stableswap D-Invariant Peg Divergence Exploit
[PASS]  19/25  Balancer V2 Vault Multi-Token Imbalance Exploit
[PASS]  20/25  Perpetual Protocol Liquidation & Bad Debt Exploit
[PASS]  21/25  LayerZero Cross-Chain Bridge Parity Exploit
[PASS]  22/25  Liquid Staking Token Exchange Rate Deflation Exploit
[PASS]  23/25  Concentrated Liquidity Virtual Range Bounds Exploit
[PASS]  24/25  Enzyme Blue Vault GAV Monotonicity Exploit
[PASS]  25/25  Redemption Conservation Settlement Exploit

Test Summary: 25 passed; 0 failed; 0 leaked. Execution time: 0.28s.
```

---

## Architecture Overview

Volta's architecture is organized into isolated, zero-allocation native layers:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           Volta Engine Core                             │
├────────────────────────────────┬────────────────────────────────────────┤
│ Static Analysis Subsystem      │ Execution & Invariant Engine           │
│ • CFG Dominator Construction   │ • Zero-Allocation EVM Interpreter      │
│ • Interprocedural Taint Flow   │ • McCarthy Storage Journal             │
│ • 22 Vulnerability Detectors   │ • 17 Opcode Invariant Checkers         │
├────────────────────────────────┼────────────────────────────────────────┤
│ Fuzzing & Exploration          │ Synthesis & Output                     │
│ • AVX2 SIMD Coverage Maps      │ • Hierarchical Delta-Debugging (HDD)   │
│ • Lock-Free Worker Scheduling  │ • Foundry (.t.sol) PoC Generator       │
└────────────────────────────────┴────────────────────────────────────────┘
```

### Core Architecture Invariants
1. **Preallocated Stack & Memory:** The VM stack is fixed to 1024 256-bit words (`types.MAX_STACK_DEPTH`), and linear memory is preallocated to 4096 bytes per context. Execution exceeding limits terminates with deterministic error codes rather than dynamic reallocation.
2. **Deterministic McCarthy Storage:** Storage state transitions are tracked via 40-byte rolling journal entries (`storage.JournalEntry`). Transactions roll back by rewinding entries without cloning memory states.
3. **64-Byte Cache Alignment:** Core execution arrays and data structures enforce `align(64)` to match hardware L1 cache line sizes.
4. **Direct Opcode-Level Proving:** Invariant formulas evaluate directly within the execution loop after each state modifying instruction (`SSTORE`, `TSTORE`, `CALL`, `LOG`).

For deeper architectural specifications, consult [ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## When to Use Volta

### Recommended Use Cases
- **Auditing Complex DeFi State Machines:** Fast verification of economic invariants across multi-step transactions.
- **Trace Triage & PoC Construction:** Transforming bulky fuzzer failure traces into minimal 2-3 step Foundry test contracts.
- **Zero-Dependency CI/CD Pipeline:** Running invariant testing in isolated environments without Python runtimes or heavy SMT solver dependencies.
- **Bytecode-Only Target Analysis:** Analyzing closed-source or legacy contracts where Solidity ASTs are unavailable.

### When Not to Use Volta
- **Full Symbolic SMT Solving:** Volta focuses on fast concrete execution, stateful fuzzing, and invariant evaluation. For exhaustive mathematical proofs over arbitrary unbounded symbolic domains, use Certora Prover or Halmos.
- **High-Level Solidity AST Linting:** For fast syntactic Solidity linting based on Solidity source representations, tools like Slither or Aderyn remain suitable.

### Complementary 4-Step Security Workflow
1. Run **Slither** or **Aderyn** for rapid AST-level source linting.
2. Run **Foundry** property tests for protocol integration scenarios.
3. Run **Volta** on target bytecode to verify opcode-level invariants, explore edge-case coverage with AVX2 acceleration, and synthesize minimal `.t.sol` proofs for failing sequences.
4. Run **Certora** or **Halmos** for formal proofs over unbounded mathematical parameters.

---

## Contributing

We welcome contributions to Volta's native execution engine, invariant formulas, and static detectors.

1. Fork the repository and create a feature branch (`git checkout -b feature/new-invariant`).
2. Implement your changes adhering to the **Zero Dynamic Allocation** invariant.
3. Verify formatting and run the full test suite:
   ```bash
   zig fmt --check src/
   zig test src/main.zig
   ```
4. Submit a Pull Request with a description of the formal invariant or detector mechanics.

For guidelines on coding style and memory invariants, see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Citation & License

If you use Volta in your security research or verification pipelines, please cite:

```bibtex
@software{volta2026,
  author = {Volta Contributors},
  title = {Volta: Zero-Allocation EVM Invariant Verification Engine and Trace Reducer},
  year = {2026},
  publisher = {GitHub},
  journal = {GitHub repository},
  howpublished = {\url{https://github.com/creatorofaurad/volta}}
}
```

Volta is licensed under the [MIT License](LICENSE).
