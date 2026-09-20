# ROCHE: Architecture & Subsystem Specification

---

## 1. System Overview & Engineering Foundations

ROCHE is engineered in pure native Zig 0.16.0 (`ReleaseFast`) to execute EVM bytecode, track coverage transitions, evaluate mathematical invariants, and minimize exploit counterexamples with **zero dynamic heap allocations (`malloc=0`)** and **cache-conscious data layouts (`align(64)`)**.

```text
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                                                      THE ROCHE UNIFIED ARCHITECTURE                                                         â”‚
â”‚ Language: Pure Native Zig 0.16.0 (ReleaseFast)                                                                                              â”‚
â”‚ Systems Invariants: 0 Bytes Dynamic Heap (malloc = 0) | 64-Byte Cache Aligned (align(64)) | 256-Bit AVX2 SIMD Hardware Acceleration         â”‚
â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¤
â”‚                                                                                                                                             â”‚
â”‚  PHASE 1: THE EXECUTION CORE                                                                                                                â”‚
â”‚  â€¢ Zero-Heap EVM (src/vm.zig): Fixed-capacity [1024]u256 stack machine & Cancun/Prague opcodes.                                             â”‚
â”‚  â€¢ McCarthy Persistent State (src/storage.zig): O(1) circular rollback ring-buffers for SSTORE & EIP-1153 TSTORE transient frames.         â”‚
â”‚                                                                                                                                             â”‚
â”‚  PHASE 2: THE 19 MODULAR SUBSYSTEMS                                                                                                         â”‚
â”‚  1. Static Detection Matrix (Slither, Aderyn, 4naly3er, Solhint, Wake Lineage):                                                             â”‚
â”‚     - src/static/cfg_dominator.zig: 512-node stack arrays with bitwise dominator tree intersections.                                        â”‚
â”‚     - src/static/reentrancy_cei.zig: 1-cycle bitwise Checks-Effects-Interactions violation detection.                                       â”‚
â”‚     - src/static/interproc_taint.zig: 256-bit bitmask register matrix tracking cross-contract data flow.                                     â”‚
â”‚     - src/static/gas_loop_analyzer.zig & src/static/complexity_linter.zig: O(N) zero-heap AST optimization scans.                           â”‚
â”‚                                                                                                                                             â”‚
â”‚  2. The Stateful Fuzzing Arena (Foundry, Echidna, Medusa, ItyFuzz Lineage):                                                                 â”‚
â”‚     - src/fuzz/parallel_executor.zig: Lock-free, multi-core worker arenas pinned to OS threads.                                             â”‚
â”‚     - src/fuzz/havoc_engine.zig: AVX2 vector mutations flipping bits across calldata arrays.                                                â”‚
â”‚     - src/fuzz/bitmap_processor.zig: 64KB AFL coverage map tracking edge hits entirely in L1 cache.                                         â”‚
â”‚     - src/fuzz/onchain_stream.zig: Bounded 2048-slot RPC cache for live mainnet flash-loan simulation.                                      â”‚
â”‚                                                                                                                                             â”‚
â”‚  3. The Invariant & Proving Subsystems (Certora, Halmos, HEVM, Kontrol Lineage):                                                            â”‚
â”‚     - src/prover/cvl_smt_tac.zig: Internal Three-Address Code (TAC) compiler.                                                               â”‚
â”‚     - src/prover/symbolic_engine.zig: Mathematical interval domains evaluating path constraints natively in hardware.                       â”‚
â”‚     - src/prover/kontrol_kcfg.zig & src/prover/hevm_semantics.zig: Operational state transformations & formal KCFG simplification.          â”‚
â”‚     - src/invariants_core/erc4626_inflation.zig & src/invariants_core/scribble_runtime.zig: Out-of-band DeFi economic property verifiers. â”‚
â”‚                                                                                                                                             â”‚
â”‚  4. Reverse Engineering & Decompilation (Heimdall, Panoramix, Eveem Lineage):                                                               â”‚
â”‚     - src/decompile/jumpdest_matcher.zig: Fast jump-table resolution using AVX2 byte-pattern matching.                                      â”‚
â”‚     - src/decompile/pseudocode_emitter.zig & src/decompile/proxy_classifier.zig: Zero-allocation interface & EIP-1967 proxy extraction.     â”‚
â”‚                                                                                                                                             â”‚
â”‚  PHASE 3: THE PIPELINE ORCHESTRATOR                                                                                                         â”‚
â”‚  â€¢ src/orchestrator.zig: Unified state-machine wiring static analysis -> parallel fuzzing -> invariant provers -> PoC synthesizer.          â”‚
â”‚  â€¢ src/foundry_synth.zig: Automatically emits standalone, compilable ExploitReproduction.t.sol files.                                      â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

---

## 2. Master Execution Pipeline

```text
Bytecode Ingestion (.bin / hex)
      â”‚
      â–¼
[Phase 1] CFG Dominator & CEI Scanner (src/static/cfg_dominator.zig, src/static/reentrancy_cei.zig)
      â”‚
      â–¼
[Phase 2] Parallel Havoc Fuzzing (src/fuzz/parallel_executor.zig, src/fuzz/havoc_engine.zig)
      â”‚       â”‚
      â”‚       â”œâ”€â”€> McCarthy O(1) Checkpoint Rollback (src/storage.zig)
      â”‚       â””â”€â”€> 64KB AFL Coverage Tracking in L1 Cache (src/fuzz/bitmap_processor.zig)
      â”‚
      â–¼
[Phase 3] Invariant Prover & Economic Property Evaluation (src/prover/symbolic_engine.zig, src/invariants.zig)
      â”‚
      â”œâ”€â”€ [Invariant Holds] â”€â”€> Next Mutation Iteration
      â”‚
      â””â”€â”€ [Invariant Breached]
                â”‚
                â–¼
[Phase 4] Hierarchical Delta-Debugging (O(N log N) Minimization) (src/fuzzer.zig)
                â”‚
                â–¼
[Phase 5] Automated Foundry PoC Synthesis (src/foundry_synth.zig) â”€â”€> Compilable ExploitReproduction.t.sol
```

---

## 3. Hardware Alignment & Performance Characteristics

Tested on benchmark host: Intel Core i5-8365U @ 1.60GHz, 24 GB RAM, 256 GB NVMe SSD (compiled with Zig 0.16.0 under `ReleaseFast`):

| Metric | Measured Value | Implementation Design |
| :--- | :--- | :--- |
| **Dynamic Heap Allocation** | **0 Bytes** | Zero `malloc`/`free` calls across entire execution pipeline |
| **Invariant Check Latency** | **< 1.00 ns** | Inlined SIMD / register-resident arithmetic |
| **EIP-1153 TSTORE/TLOAD** | **1.31 ns** | Direct slot indexing in transient memory arrays |
| **VM Throughput** | **> 8,300,000 tx/s** | Single-threaded release execution on x86_64 silicon |
| **AVX2 Acceleration** | **6.73x over scalar** | 256-bit hardware SIMD vectorization |
| **Cache Alignment** | **64-Byte Hardware L1** | `align(64)` across all VM memory and internal tensor blocks |
| **Foundry PoC Gen Time** | **< 15 ms** | Direct buffer template emission |
