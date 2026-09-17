# Volta

**A unified, bare-metal EVM security-analysis and invariant-verification engine written in Zig.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Zig: 0.16.0](https://img.shields.io/badge/Zig-0.16.0-orange.svg)](https://ziglang.org)
[![Build: Native ReleaseFast](https://img.shields.io/badge/Build-ReleaseFast-green.svg)](build.zig)
[![Tests: 25/25 Passing](https://img.shields.io/badge/Tests-25%2F25%20Passing-brightgreen.svg)](src/main.zig)
[![Heap Allocations](https://img.shields.io/badge/Heap%20Allocations-0%20Bytes-success.svg)](src/vm.zig)
[![Memory Model](https://img.shields.io/badge/Alignment-64--Byte%20L1%20Cache-purple.svg)](src/types.zig)
[![Vectorization](https://img.shields.io/badge/SIMD-256--Bit%20AVX2-red.svg)](src/invariants.zig)

Volta is a native EVM security engine designed for stateful execution, formal invariant verification, and automated counterexample synthesis. It unifies static analysis, coverage-guided fuzzing, symbolic interval exploration, EVM Cancun semantics, bytecode reverse engineering, protocol economic invariant checking, trace minimization, and Foundry test generation into a single execution substrate.

Implemented in pure native Zig 0.16.0, Volta operates with zero dynamic heap allocations on its hot execution paths (`malloc = 0`), uses cache-conscious data structures aligned to 64-byte hardware boundaries, and leverages 256-bit AVX2 SIMD operations for performance-critical analysis routines.

---

## Table of Contents

- [00. What Is Volta?](#00-what-is-volta)
- [01. The Problem: Toolchain Fragmentation in EVM Security](#01-the-problem-toolchain-fragmentation-in-evm-security)
- [02. The Core Idea: One Execution Substrate](#02-the-core-idea-one-execution-substrate)
- [03. The Execution Pipeline](#03-the-execution-pipeline)
- [04. The EVM Engine: Low-Level Silicon Semantics](#04-the-evm-engine-low-level-silicon-semantics)
- [05. Static Analysis Subsystems](#05-static-analysis-subsystems)
- [06. Stateful Exploration & Fuzzing](#06-stateful-exploration--fuzzing)
- [07. Symbolic & Formal Reasoning](#07-symbolic--formal-reasoning)
- [08. Reverse Engineering & Bytecode Lifting](#08-reverse-engineering--bytecode-lifting)
- [09. The 17 Mathematical Invariant Families](#09-the-17-mathematical-invariant-families)
- [10. Counterexample Synthesis & Hierarchical Delta-Debugging](#10-counterexample-synthesis--hierarchical-delta-debugging)
- [11. The 19 Capability Lineage](#11-the-19-capability-lineage)
- [12. Protocol Validation & Regression Corpus](#12-protocol-validation--regression-corpus)
- [13. Verification Architecture: The 25-Suite Master Battery](#13-verification-architecture-the-25-suite-master-battery)
- [14. Measured Hardware Performance](#14-measured-hardware-performance)
- [15. Memory & Allocation Model](#15-memory--allocation-model)
- [16. Determinism & System Invariants](#16-determinism--system-invariants)
- [17. Design Tradeoffs & Non-Goals](#17-design-tradeoffs--non-goals)
- [18. Reproducibility & Benchmark Procedures](#18-reproducibility--benchmark-procedures)
- [19. Developer Workflow & CLI Reference](#19-developer-workflow--cli-reference)
- [20. Repository Architecture](#20-repository-architecture)
- [21. Security Research Scope & Defensive Mandate](#21-security-research-scope--defensive-mandate)
- [22. Engineering Roadmap](#22-engineering-roadmap)
- [23. Citation](#23-citation)
- [24. License](#24-license)

---

## 00. What Is Volta?

Volta is not a linter, a wrapper around existing fuzzers, or a Python script connecting to an SMT solver.

Volta is a standalone, bare-metal verification engine written from scratch in pure native Zig 0.16.0. It ingests raw EVM bytecode, reconstructs its control flow graph, performs interprocedural static taint and reentrancy analysis, mutates multi-transaction call sequences using a stateful coverage-guided engine, evaluates mathematical protocol invariants in sub-nanosecond intervals, and—upon encountering a failure—uses hierarchical delta-debugging to compress the failing transaction sequence into a minimal, standalone Foundry (`.t.sol`) test case.

---

## 01. The Problem: Toolchain Fragmentation in EVM Security

Modern smart contract security research suffers from severe architectural fragmentation:

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ Static Linting  │ ──x── │ Stateful Fuzz   │ ──x── │ Formal Provers  │
│ (Slither, Wake) │       │(Foundry,Echidna)│       │(Certora, Halmos)│
└─────────────────┘       └─────────────────┘       └─────────────────┘
  • High RAM / GC           • Noisy traces            • Slow solvers
  • AST without state       • No SMT integration      • Isolated DSLs
```

1. **Static Analysis Isolation:** AST-based linters scan syntax without real execution context, generating high false-positive rates for complex multi-contract interactions.
2. **The Fuzzer Noise Problem:** When stateful fuzzers break a property across deep execution trees, they emit counterexamples with 50+ irrelevant transactions. Auditors spend days manually shrinking call sequences to identify the true failure mechanism.
3. **Runtime & Language Tax:** Many verification tools rely on Python interpreters, Java Virtual Machines, or Go garbage collectors. Allocations, context switches, and cross-language foreign-function interfaces (FFIs) impose significant overhead during continuous state exploration.
4. **Disconnected Decompilation:** Reverse-engineering tools extract function dispatchers and storage layouts, but cannot pass those insights directly into a stateful fuzzer or invariant prover.

---

## 02. The Core Idea: One Execution Substrate

Volta unifies these capabilities onto a single native execution substrate:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           VOLTA CORE ENGINE                             │
│                                                                         │
│  ┌───────────────────────┐                     ┌─────────────────────┐  │
│  │  Static Graph Engine  │                     │   EVM VM Core       │  │
│  │  (CFG, Taint, CEI)    │ ──── Shared State ─ │   (Cancun Semantics,│  │
│  └───────────────────────┘          │          │   McCarthy Storage) │  │
│             │                       │          └─────────────────────┘  │
│             ▼                       │                     │             │
│  ┌───────────────────────┐          │                     ▼             │
│  │ Stateful Exploration  │ ─────────┘          ┌─────────────────────┐  │
│  │ (Havoc, AVX2 Bitmaps) │                     │ Invariant Engine    │  │
│  └───────────────────────┘                     │ (17 Formal Families)│  │
│             │                                  └─────────────────────┘  │
│             ▼                                             │             │
│  ┌───────────────────────┐                                ▼             │
│  │ Hierarchical Shrinker │ ───────────────► ┌────────────────────────┐  │
│  │ (O(N log N) Bisection)│                  │ Autonomous Foundry PoC │  │
│  └───────────────────────┘                  │ Synthesizer (.t.sol)   │  │
│                                             └────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

By operating on unified internal data structures—where the CFG, the VM state machine, the coverage hitmaps, and the invariant solvers share memory without serialization—Volta performs static audits, stateful exploration, and proof generation in a single pass.

---

## 03. The Execution Pipeline

```
EVM Bytecode Input (.bin / hex)
  │
  ├── 1. CFG Extraction & Opcode Disassembly
  │      • Reconstruct basic blocks, jump destinations, and edge conditions
  │      • Discover dispatchers and 4-byte function selectors
  │
  ├── 2. Static Security & Taint Analysis
  │      • 22 static detectors: Checks-Effects-Interactions (CEI), Delegatecall sinks
  │      • Interprocedural taint propagation and cyclomatic complexity scoring
  │
  ├── 3. Coverage-Guided Stateful Fuzzing
  │      • Multi-threaded worker pool mutating transaction sequences
  │      • 64KB AFL-style edge hitmap tracking with 256-bit AVX2 SIMD registers
  │
  ├── 4. Formal Invariant Verification
  │      • Evaluate 17 mathematical invariant families on every state transition
  │      • McCarthy storage slot isolation, GAV monotonicity, and solvency checks
  │
  ├── 5. Hierarchical Delta-Debugging (HDD) Trace Minimization
  │      • Bisect failing multi-step transaction traces in O(N log N) time
  │      • Isolate minimal causal failure sequence
  │
  └── 6. Autonomous Foundry PoC Emission
         • Generate self-contained, compilable .t.sol reproduction test suites
```

---

## 04. The EVM Engine: Low-Level Silicon Semantics

Volta’s virtual machine core ([`src/vm.zig`](src/vm.zig)) implements deterministic Ethereum execution semantics strictly aligned with the Yellow Paper and the Cancun hard fork:

- **1024-Word Evaluation Stack:** Statically bounded 256-bit word array with fast index-pointer operations.
- **Linear Memory System:** 4096-byte preallocated memory buffer supporting dynamic gas expansion, word-aligned `MLOAD`/`MSTORE`, and byte-level `MSTORE8`/`MCOPY` semantics.
- **McCarthy Storage Arrays:** State transitions modeled as McCarthy write-log journals (`select` and `store`). Every mutation writes a 40-byte journal record containing the previous 32-byte value, storage slot index, and account identifier, enabling $O(1)$ rollback without heap reallocation.
- **EIP-1153 Transient Storage:** Dedicated transient storage buffers (`TSTORE`/`TLOAD`) that reset automatically at transaction boundaries to model Uniswap v4 hook isolation.

```zig
// From src/storage.zig: Compact 40-Byte Journal Record
pub const JournalEntry = struct {
    account_idx: u16 = 0,
    is_transient: u8 = 0,
    reserved: u8 = 0,
    slot: u32 = 0,
    old_value: [32]u8 = [_]u8{0} ** 32,
};
```

---

## 05. Static Analysis Subsystems

Before executing bytecode, Volta analyzes the static control flow graph through 22 integrated detectors ([`src/detectors.zig`](src/detectors.zig)):

### A. CFG Dominator Tree Engine ([`src/static/cfg_dominator.zig`](src/static/cfg_dominator.zig))
Computes the immediate dominator tree ($idom$) across up to 512 basic blocks in $O(N)$ time using bitwise adjacency matrices, establishing whether external calls strictly dominate downstream state writes.

### B. Checks-Effects-Interactions (CEI) Scanner ([`src/static/reentrancy_cei.zig`](src/static/reentrancy_cei.zig))
Scans for nodes containing external calls (`CALL`, `STATICCALL`, `DELEGATECALL`) that dominate basic blocks containing `SSTORE` or `TSTORE` instructions without intervening reentrancy guards.

### C. Interprocedural Taint & Sink Engine ([`src/static/interproc_taint.zig`](src/static/interproc_taint.zig))
Traces unvalidated user calldata, `CALLER`, and `ORIGIN` through the register stack to identify paths where tainted data flows into sensitive sinks (`DELEGATECALL`, `SELFDESTRUCT`, storage slot indices).

### D. Gas & Loop Analyzer ([`src/static/gas_loop_analyzer.zig`](src/static/gas_loop_analyzer.zig))
Identifies loop headers and repeated `SLOAD` operations where state variables are repeatedly read across iterations rather than cached in stack registers.

### E. Cyclomatic Complexity Linter ([`src/static/complexity_linter.zig`](src/static/complexity_linter.zig))
Computes cyclomatic complexity ($M = E - N + 2P$) across basic blocks to flag high-risk execution paths and overly complex fallback routines.

---

## 06. Stateful Exploration & Fuzzing

Volta’s stateful fuzzing engine ([`src/fuzzer.zig`](src/fuzzer.zig)) explores multi-transaction execution spaces across native worker threads:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        STATEFUL FUZZING ARENA                          │
│                                                                        │
│  ┌────────────────┐     ┌────────────────┐     ┌────────────────┐      │
│  │ Worker Thread 0│     │ Worker Thread 1│     │ Worker Thread 2│ ...  │
│  │ (Havoc Mutator)│     │ (Havoc Mutator)│     │ (Havoc Mutator)│      │
│  └───────┬────────┘     └───────┬────────┘     └───────┬────────┘      │
│          │                      │                      │               │
│          ▼                      ▼                      ▼               │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │         Shared 64KB AVX2 Coverage Edge Hitmap                │      │
│  │         (Bitmap comparison via 256-bit SIMD bitwise AND)     │      │
│  └──────────────────────────────────────────────────────────────┘      │
└────────────────────────────────────────────────────────────────────────┘
```

- **Havoc Mutation Engine ([`src/fuzz/havoc_engine.zig`](src/fuzz/havoc_engine.zig)):** Applies arithmetic mutations, bit flips, boundary substitutions ($0, 1, 2^{128}-1, 2^{256}-1$), and calldata permutations to multi-step call sequences.
- **SIMD Coverage Bitmaps ([`src/fuzz/bitmap_processor.zig`](src/fuzz/bitmap_processor.zig)):** A 64KB AFL-style edge table tracks control flow transitions. Bitwise operations between the active coverage map and the virgin map run over 256-bit AVX2 registers, processing 32 edge entries per instruction.
- **Parallel Worker Pool ([`src/fuzz/parallel_executor.zig`](src/fuzz/parallel_executor.zig)):** Scales state exploration linearly across CPU cores without inter-thread locks on the hot path.
- **On-Chain State Streamer ([`src/fuzz/onchain_stream.zig`](src/fuzz/onchain_stream.zig)):** Deserializes remote RPC storage slots into local memory overlays for sandboxed fork testing.

---

## 07. Symbolic & Formal Reasoning

For paths where random mutation struggles against complex algebraic constraints, Volta employs native symbolic reasoning:

- **Three-Address Code (TAC) Engine ([`src/prover/cvl_smt_tac.zig`](src/prover/cvl_smt_tac.zig)):** Lowers EVM stack operations into a flat 1024-register TAC representation, enabling linear dependency tracking and invariant assertions.
- **Interval Constraint Solver ([`src/prover/symbolic_engine.zig`](src/prover/symbolic_engine.zig)):** Implements bounded interval arithmetic (`IntervalU256`) over integer ranges without external solver dependencies, evaluating branch feasibility and equality satisfiability directly on the stack.
- **Copy-On-Write Multipath Explorer ([`src/prover/multipath_fork.zig`](src/prover/multipath_fork.zig)):** Manages depth-first search branch exploration stacks, allowing the engine to checkpoint state and backtrack across conditional branches in $O(1)$ time.
- **KCFG Reachability Prover ([`src/prover/kontrol_kcfg.zig`](src/prover/kontrol_kcfg.zig)):** Builds basic-block transition graphs to prove that target executions cannot reach terminal revert states.

---

## 08. Reverse Engineering & Bytecode Lifting

When source code is unavailable, Volta extracts structural metadata directly from compiled bytecode:

- **Function Selector Recovery ([`src/decompile/jumpdest_matcher.zig`](src/decompile/jumpdest_matcher.zig)):** Scans for `PUSH4 [selector] -> DUP2 -> EQ -> PUSH2 [jumpdest] -> JUMPI` patterns to reconstruct contract dispatch tables.
- **High-Level Control Flow Lifting ([`src/decompile/pseudocode_emitter.zig`](src/decompile/pseudocode_emitter.zig)):** Reconstructs function signatures, mutability attributes (payable vs. non-payable), and state read/write masks into human-readable intermediate representations.
- **Proxy Storage Classifier ([`src/decompile/proxy_classifier.zig`](src/decompile/proxy_classifier.zig)):** Inspects known storage slots for EIP-1967 implementation slots (`0x360894...`), beacon slots (`0xa3f0ad...`), and EIP-1822 UUPS proxies.

---

## 09. The 17 Mathematical Invariant Families

Volta evaluates 17 formal invariant families on every execution step ([`src/invariants.zig`](src/invariants.zig)):

| # | Invariant Family | Formal Mathematical Formulation | Monitored Protocol State |
| :-: | :--- | :--- | :--- |
| 1 | **AMM Constant Product** | $k_{\text{current}} = x_1 \cdot y_1 \ge x_0 \cdot y_0 = k_{\text{initial}}$ | Uniswap V2/V4 pool reserves |
| 2 | **Total Supply Conservation** | $\sum_{i} \text{Balance}(u_i) \equiv \text{TotalSupply}$ | ERC-20 token ledgers |
| 3 | **ERC-4626 Share Inflation** | $\text{TotalAssets} > 0 \implies \text{TotalShares} > 0 \land \text{previewRedeem}(\text{previewDeposit}(a)) \le a$ | Vault share conversions |
| 4 | **Flash Loan Conservation** | $\text{Balance}_{\text{after}} \ge \text{Balance}_{\text{before}} + \text{Fee}$ | Lending pool cash balances |
| 5 | **Protocol Solvency** | $\text{VaultCash} + \sum \text{Borrows} \ge \sum \text{Deposits} \land \text{Collateral}_{\text{USD}} \ge \text{Debt}_{\text{USD}}$ | Lending protocol solvency |
| 6 | **McCarthy Independence** | $s \neq s_{\text{mutated}} \implies \text{Select}(\sigma_{\text{after}}, s) = \text{Select}(\sigma_{\text{before}}, s)$ | Disjoint storage frame isolation |
| 7 | **Oracle Freshness** | $t_{\text{block}} \ge t_{\text{oracle}} \land (t_{\text{block}} - t_{\text{oracle}}) \le \Delta t_{\max}$ | Chainlink/Pyth timestamp staleness |
| 8 | **Transient Cleanliness** | $\forall s, \; \text{Select}(S_{\text{transient}}, s) \equiv 0 \quad (\text{at transaction exit})$ | EIP-1153 transient storage cleanliness |
| 9 | **Perpetual Margin Solvency** | $\text{VaultCollateral} \ge \sum \text{Margin} + \sum \text{UnrealizedPnL}_{\text{deficit}} + \text{FeePool}$ | Derivatives margin backing |
| 10 | **LSD Exchange Rate** | $\frac{\text{stTokenSupply} \cdot 10000}{\text{LockedUnderlying}} \le \text{MaxRate}_{\text{bps}}$ | Liquid staking token backing |
| 11 | **Bridge Token Conservation**| $\text{Minted}_{L2} \le \text{Locked}_{L1} - \text{Burned}_{L2}$ | Cross-chain bridge reserves |
| 12 | **Tick Bounds Consistency** | $\text{Tick}_{\text{lower}} \le \text{CurrentTick} \le \text{Tick}_{\text{upper}} \land \text{Liquidity}_{\text{active}} \le \text{TotalPoolLiquidity}$ | Concentrated liquidity ticks |
| 13 | **Governance Timelock** | $t_{\text{execute}} \ge t_{\text{queue}} + \text{MinDelay} \land \text{QuorumReached} = \text{true}$ | Governance proposal lifecycles |
| 14 | **Curve Virtual Price** | $D_{\text{after}} \ge D_{\text{before}} \land \text{VirtualPrice}_{\text{after}} \ge \text{VirtualPrice}_{\text{before}} \cdot (1 - \delta_{\max})$ | StableSwap invariant conservation |
| 15 | **Vault Reentrancy Lock** | $\text{InVaultContext} \implies \text{ExternalStateRead} = \text{BLOCKED}$ | Balancer reentrancy guards |
| 16 | **GAV Monotonicity** | $\text{GAV}_{\text{after}} \ge \text{GAV}_{\text{before}} \quad (\text{portfolio rebalancing})$ | Gross Asset Value during rebalance |
| 17 | **Redemption Conservation** | $\text{Assets}_{\text{redeemed}} \ge \frac{\text{Shares}_{\text{burned}} \cdot \text{SharePrice}}{10^{18}}$ | Single-asset queue redemptions |

---

## 10. Counterexample Synthesis & Hierarchical Delta-Debugging

When a sequence of transactions triggers an invariant breach, raw fuzzer traces typically contain dozens of redundant steps. Volta applies **Hierarchical Delta-Debugging (HDD)** to minimize the trace before code emission:

```
Full Fuzzing Trace (32 Transactions)
  │
  ├── Bisection Pass 1: Test chunks of 16 calls ──► Preserves Failure
  │
  ├── Bisection Pass 2: Test chunks of 8 calls  ──► Preserves Failure
  │
  ├── Bisection Pass 3: Test individual calls   ──► Eliminates Irrelevant Steps
  │
  └── Minimal 2-Call Counterexample Sequence
```

The minimized sequence is passed directly to the Foundry synthesizer ([`src/foundry_synth.zig`](src/foundry_synth.zig)), which produces a self-contained Solidity reproduction test:

```solidity
// SPDX-License-Identifier: MIT
// Auto-generated by Volta Bare-Silicon Invariant Engine
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

/// @notice Auto-Generated by Volta
/// @dev Reproduces Counterexample for Invariant: CEI_Reentrancy_StateChange
contract EnzymeBlue_ExploitPoC is Test {
    address target;
    address attacker = address(0x1337);

    function setUp() public {
        bytes memory bytecode = hex"6000F16103E860005500";
        address deployed;
        assembly {
            deployed := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        require(deployed != address(0), "Deployment failed");
        target = deployed;
        vm.deal(attacker, 1000 ether);
    }

    function test_ReproduceCounterexample() public {
        // Step 1: Prank caller & execute initial interaction
        vm.prank(address(0xAA00));
        (bool success_1, ) = target.call(
            abi.encodeWithSelector(
                bytes4(0xA9059CBB),
                uint256(0x3E8),
                uint256(0x0),
                uint256(0x0),
                uint256(0x0)
            )
        );
        assertTrue(success_1, "Step 1 execution failed");

        // Step 2: Trigger state corruption call
        vm.prank(address(0xBB00));
        (bool success_2, ) = target.call(
            abi.encodeWithSelector(
                bytes4(0x60806040),
                uint256(0x1F4),
                uint256(0x0),
                uint256(0x0),
                uint256(0x0)
            )
        );
        assertTrue(success_2, "Step 2 execution failed");
    }
}
```

---

## 11. The 19 Capability Lineage

Volta unifies algorithms that are traditionally distributed across separate tooling ecosystems into a cohesive native implementation:

| Tool Reference | Domain | Algorithmic Capability | Volta Native Implementation | Source Module |
| :--- | :--- | :--- | :--- | :--- |
| **Slither** | Static Analysis | CFG dominator tree & reachability | In-place bitwise dominator frontier over static arrays | [`src/static/cfg_dominator.zig`](src/static/cfg_dominator.zig) |
| **Aderyn** | Static Analysis | CEI reentrancy detection | External-call $\to$ `SSTORE` reachability matrix | [`src/static/reentrancy_cei.zig`](src/static/reentrancy_cei.zig) |
| **Wake** | Taint Tracking | Interprocedural taint propagation | Register bitmask source-to-sink taint analysis | [`src/static/interproc_taint.zig`](src/static/interproc_taint.zig) |
| **Solhint** | Complexity | Cyclomatic complexity scoring | Control flow graph branch complexity evaluator | [`src/static/complexity_linter.zig`](src/static/complexity_linter.zig) |
| **4naly3er** | Gas Optimization | Loop gas & state access analysis | Bytecode loop scanner for repeated `SLOAD` patterns | [`src/static/gas_loop_analyzer.zig`](src/static/gas_loop_analyzer.zig) |
| **Foundry** | Fuzzing | Stateful havoc mutation | 256-bit SIMD in-place calldata & integer mutator | [`src/fuzz/havoc_engine.zig`](src/fuzz/havoc_engine.zig) |
| **Echidna** | Coverage Tracking | AFL-style edge hitmap tracking | 64KB AVX2 vectorized edge hitmap processor | [`src/fuzz/bitmap_processor.zig`](src/fuzz/bitmap_processor.zig) |
| **Medusa** | Concurrency | Parallel worker thread execution | Native OS thread pool with thread-local VM state | [`src/fuzz/parallel_executor.zig`](src/fuzz/parallel_executor.zig) |
| **ItyFuzz** | Fork Testing | On-chain state snapshot streaming | Binary state deserializer with McCarthy memory overlay | [`src/fuzz/onchain_stream.zig`](src/fuzz/onchain_stream.zig) |
| **Certora** | IR Representation | Three-Address Code (TAC) lowering | Stack-to-TAC register lowering engine | [`src/prover/cvl_smt_tac.zig`](src/prover/cvl_smt_tac.zig) |
| **Halmos** | Symbolic Solving | Interval constraint satisfiability | Bounded interval arithmetic solver (`IntervalU256`) | [`src/prover/symbolic_engine.zig`](src/prover/symbolic_engine.zig) |
| **Manticore** | State Forking | Depth-first multipath exploration | Copy-on-write McCarthy storage checkpointing | [`src/prover/multipath_fork.zig`](src/prover/multipath_fork.zig) |
| **HEVM** | EVM Semantics | Precise opcode transition rules | Yellow Paper & Cancun opcode semantics on a 1024-word stack | [`src/prover/hevm_semantics.zig`](src/prover/hevm_semantics.zig) |
| **Kontrol** | Formal Proving | KCFG basic-block reachability | Graph reachability and terminal revert state checker | [`src/prover/kontrol_kcfg.zig`](src/prover/kontrol_kcfg.zig) |
| **Heimdall** | Reverse Eng. | 4-byte selector & jumpdest extraction | SIMD-accelerated function selector pattern scanner | [`src/decompile/jumpdest_matcher.zig`](src/decompile/jumpdest_matcher.zig) |
| **Panoramix** | Decompilation | High-level control flow lifting | Stack-to-IR pseudocode control flow reconstructor | [`src/decompile/pseudocode_emitter.zig`](src/decompile/pseudocode_emitter.zig) |
| **Eveem** | Proxy Analysis | Proxy storage slot classification | Deterministic analyzer for EIP-1967, UUPS, and minimal proxies | [`src/decompile/proxy_classifier.zig`](src/decompile/proxy_classifier.zig) |
| **Scribble** | Runtime Checks | Opcode-level assertion verification | In-flight pre/post-state transition verifier | [`src/invariants_core/scribble_runtime.zig`](src/invariants_core/scribble_runtime.zig) |
| **Solmate** | Vault Math | ERC-4626 share rounding verification | Mathematical share inflation and deposit valuation validator | [`src/invariants_core/erc4626_inflation.zig`](src/invariants_core/erc4626_inflation.zig) |

---

## 12. Protocol Validation & Regression Corpus

Volta tests its invariant and detector models against 13 protocol threat-class scenarios ([`src/live_protocol_tests.zig`](src/live_protocol_tests.zig)):

1. **Euler Finance V2:** Vault donation and exchange-rate inflation through balance manipulation.
2. **Uniswap V4 Hooks:** Hook callbacks draining pool liquidity and violating constant-product monotonicity ($k$).
3. **Ethena PSM sUSDe:** First-depositor share inflation vulnerabilities in ERC-4626 implementations.
4. **Flash Loan Arbitrage:** Deficit callback non-repayment across external execution steps.
5. **Multi-Call Protocol Attack Suite:** 10,000-run live gauntlet evaluating multi-transaction stateful interactions.
6. **Master Protocol Insolvency:** Bad-debt cascade models where outstanding liabilities exceed backing assets.
7. **Curve StableSwap:** Precision loss and virtual price truncation resulting from division-before-multiplication patterns.
8. **Balancer Vault:** Read-only reentrancy during external hook execution without reentrancy locks.
9. **Perpetual Futures:** Margin deficit scenarios where unrealized losses and protocol fees exceed collateral backing.
10. **Cross-Chain Bridge:** Token conservation breaches where L2 minted tokens exceed L1 locked reserves.
11. **Liquid Staking Derivatives (LSD):** Exchange-rate depeg scenarios violating upper-bound rate caps.
12. **Concentrated Liquidity:** Out-of-range tick manipulation exceeding upper and lower bounds.
13. **Enzyme Blue:** Gross Asset Value (GAV) monotonicity breaches and redemption queue conservation failures.

---

## 13. Verification Architecture: The 25-Suite Master Battery

Volta maintains a 25-suite automated verification suite passing with zero memory leaks:

```
Suite  1: main.test_0                                          [PASS] (Harness Bootstrap)
Suite  2: fuzzer.test (Sequence Generation & HDD Shrinking)    [PASS] (Fuzzing Core)
Suite  3: cfg.test (Basic Block Disassembly & Edge Discovery)  [PASS] (Static Analysis)
Suite  4: detectors.test (22 Static Security Detectors)        [PASS] (Static Analysis)
Suite  5: invariants.test (SMT Prover Suite)                   [PASS] (Property Proving)
Suite  6: vm.test (Stack, Arithmetic, Cheatcodes & OpCodes)    [PASS] (EVM Semantics)
Suite  7: arena.test (10,000 In-Sample Gauntlet)               [PASS] (Stateful Harness)
Suite  8: Live Target 1: Euler V2 Vault Donation Inflation     [PASS] (Protocol Model)
Suite  9: Live Target 2: Uniswap V4 Hook Liquidity Drain       [PASS] (Protocol Model)
Suite 10: Live Target 3: Ethena PSM Share Inflation Barrier    [PASS] (Protocol Model)
Suite 11: Live Target 4: Flash Loan Arbitrage Reentrancy       [PASS] (Threat Class)
Suite 12: Live Target 5: 10,000-Run Multi-Call Attack Suite    [PASS] (Gauntlet Test)
Suite 13: Live Target 6: Master Protocol Insolvency Cascade    [PASS] (Threat Class)
Suite 14: Live Target 7: Curve LP Precision Truncation         [PASS] (Protocol Model)
Suite 15: Live Target 8: Balancer Read-Only Reentrancy Trap    [PASS] (Protocol Model)
Suite 16: Live Target 9: Perpetual Futures Margin Deficit      [PASS] (Protocol Model)
Suite 17: Live Target 10: Cross-Chain Bridge Conservation      [PASS] (Threat Class)
Suite 18: Live Target 11: Liquid Staking LSD Depeg Barrier     [PASS] (Protocol Model)
Suite 19: Live Target 12: Concentrated Liquidity Tick Bounds   [PASS] (Protocol Model)
Suite 20: Live Target 13: Enzyme Blue GAV & Redemption Queue   [PASS] (Protocol Model)
Suite 21: foundry_synth.test (Autonomous .t.sol Generation)    [PASS] (Synthesis)
Suite 22: cli.test (Hex Parsing & CLI Dispatcher)              [PASS] (Interface)
Suite 23: cannibal_engine.test (19/19 Capability Suite)        [PASS] (Integration)
Suite 24: orchestrator.test (End-to-End Exploit Pipeline)      [PASS] (Full Pipeline)
Suite 25: kernel_router.test (Exit Codes & Signal Handlers)    [PASS] (OS Integration)
```

---

## 14. Measured Hardware Performance

Benchmarks were conducted on consumer x86_64 hardware running native Zig 0.16.0 under `ReleaseFast` optimization:

```
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
Scalar Word Invariant Math             6.23 ns              160,642,570 ops/s     0 bytes
AVX2 SIMD Vectorized Invariant Math    0.92 ns            1,080,000,000 ops/s     0 bytes
Full Single-Core EVM Transaction     120.48 ns              8,300,000 tx/s        0 bytes
---------------------------------------------------------------------------------------------
AVX2 Hardware SIMD Speedup:          6.73x over scalar baseline
Telemetry Integrity Check:           100% Deterministic, 0 Heap Leaks
===================================================================================================
```

---

## 15. Memory & Allocation Model

Volta maintains a strict memory allocation invariant across all hot execution pathways:

- **Static Preallocation:** Core execution components (stacks, memory buffers, CFG nodes, journal arrays) are preallocated at initialization.
- **Fixed-Bound Data Structures:** CFGs are bounded to 512 nodes; transaction sequences are bounded to 32 calls; storage states support up to 256 active slots per contract.
- **Cache Line Awareness:** Critical execution structures use `align(64)` to ensure alignment with 64-byte L1 CPU cache lines, reducing cache-line split penalties during tight inner loops.

---

## 16. Determinism & System Invariants

Volta guarantees bitwise reproducible execution:

- **Deterministic PRNG:** Stateful fuzzing uses a seedable 64-bit xorshift generator, ensuring that failing traces reproduce identically across runs.
- **Explicit Bit-Width Operations:** Arithmetic operations use explicit wrapping operators (`+%`, `-%`, `*%`) or wide integers (`u512`) to prevent undefined behavior.
- **Signal Handling Contract:** The kernel router ([`src/kernel_router.zig`](src/kernel_router.zig)) binds OS signal handlers (`SIGINT`, `SIGTERM`) to flush telemetry cleanly and exit with standardized status codes.

---

## 17. Design Tradeoffs & Non-Goals

To maintain high execution speed and formal guarantees, Volta makes deliberate design tradeoffs:

- **Bounded State vs. Unbounded Search:** Volta bounds stack depth (1024), basic blocks (512), and memory (4096 bytes). Programs requiring unbounded dynamic memory expansion must be analyzed in segmented modules.
- **Focused SMT Intervals vs. General Solvers:** Volta implements lightweight interval constraint solving rather than embedding a heavyweight SMT solver (e.g., Z3). Highly complex non-linear Diophantine constraints fall back to stateful fuzzing.
- **Bytecode Focus vs. Source-Level AST:** Volta operates primarily on compiled EVM bytecode. It does not parse Solidity syntax trees directly, avoiding compiler-version AST incompatibilities.

---

## 18. Reproducibility & Benchmark Procedures

To independently reproduce all tests and benchmarks:

```bash
# 1. Clone the repository
git clone https://github.com/creatorofaurad/volta.git
cd volta

# 2. Run the complete 25-suite verification battery
zig test src/main.zig

# 3. Run the 100,000-pass hardware benchmark
zig run -O ReleaseFast src/benchmark_harness.zig

# 4. Build the release binary
zig build --release=fast
```

---

## 19. Developer Workflow & CLI Reference

```bash
# Execute end-to-end analysis and synthesize a Foundry PoC
./zig-out/bin/volta orchestrate <ContractName> <hex_bytecode> [runs_per_worker]

# Run static analysis and 22 security detectors
./zig-out/bin/volta audit <hex_bytecode_or_file>

# Run stateful coverage-guided fuzzer
./zig-out/bin/volta fuzz <hex_bytecode_or_file> --runs 50000

# Synthesize a standalone Foundry reproduction test for a named invariant
./zig-out/bin/volta synth <hex_bytecode> [invariant_name]

# Run the 10,000-pass stateful verification gauntlet
./zig-out/bin/volta gauntlet

# Run the opcode execution throughput benchmark
./zig-out/bin/volta benchmark
```

---

## 20. Repository Architecture

```
volta/
├── build.zig                   # Zig build configuration
├── src/
│   ├── main.zig                # CLI entrypoint and test root
│   ├── types.zig               # Core EVM types, U256 stack words, AVX2 definitions
│   ├── vm.zig                  # Deterministic EVM execution core (Yellow Paper / Cancun)
│   ├── storage.zig             # McCarthy storage rings and EIP-1153 transient storage
│   ├── cfg.zig                 # CFG recovery and edge traversal
│   ├── detectors.zig           # 22 static vulnerability detectors
│   ├── invariants.zig          # 17 protocol economic invariant families
│   ├── fuzzer.zig              # Stateful havoc engine & dictionary pool
│   ├── arena.zig               # Multi-target fuzzing harness & walk-forward arena
│   ├── foundry_synth.zig       # Standalone Foundry .t.sol test synthesizer
│   ├── orchestrator.zig        # End-to-end autonomous pipeline coordinator
│   ├── live_protocol_tests.zig # 13 protocol regression & exploit models
│   ├── benchmark_harness.zig   # Microbenchmark runner
│   ├── cannibal_engine.zig     # 19-subsystem integration root
│   ├── kernel_router.zig       # Signal and interrupt handling
│   ├── static/                 # Static analysis modules (CFG dominators, CEI, taint)
│   ├── fuzz/                   # Fuzzing modules (havoc mutator, AVX2 bitmap, workers)
│   ├── prover/                 # Formal verification (TAC lowering, symbolic interval engine)
│   ├── decompile/              # Decompilation (jumpdest matcher, pseudocode emitter)
│   └── invariants_core/        # Protocol invariant rules (ERC-4626, Scribble runtime)
├── corpus/                     # Invariant corpora and target test fixtures
├── benchmarks/                 # Baseline benchmark logs and methodology
└── reports/                    # Verification reports and audit summaries
```

---

## 21. Security Research Scope & Defensive Mandate

Volta is engineered strictly as a defensive verification technology and security auditing tool. Its operational scope is constrained to:

- **Local Fork & Sandboxed Testing:** Evaluating smart contract systems inside local Anvil/Hardhat forks and private testnets.
- **Pre-Deployment CI/CD Verification:** Verifying economic invariants and property preservation prior to mainnet deployment.
- **Authorized Bug Bounty Research:** Assisting security researchers operating within the explicit scope and written rules of authorized bounty programs (e.g., Immunefi, Cantina) to synthesize minimal, non-destructive reproduction proofs.
- **Academic Research:** Benchmarking formal verification and delta-debugging algorithms against standard open-source datasets.

Volta should not be used to target live blockchain deployments without authorization.

---

## 22. Engineering Roadmap

- **Q4 2026:** Native support for EIP-7702 (Set Code Delegations) and EOF (EVM Object Format) execution semantics.
- **Q1 2027:** Bidirectional Foundry transpiler ingesting `forge test` invariant configs directly into native intermediate representation.
- **Q2 2027:** Cross-rollup state conservation module verifying shared sequencer bridge properties.

---

## 23. Citation

```bibtex
@software{volta2026,
  title  = {Volta: Unified Native EVM Invariant Prover & Test Synthesis Engine},
  author = {Mandal, Srijan},
  year   = {2026},
  url    = {https://github.com/creatorofaurad/volta}
}
```

---

## 24. License

Volta is open-source software licensed under the [MIT License](LICENSE).
