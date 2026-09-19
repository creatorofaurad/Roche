# Charles' Systems Architecture Portfolio

**Founder & Systems Architect:** Charles (`creatorofaurad`)  
**Core Discipline:** Bare-Silicon Systems Engineering, Formal Invariant Verification, Cryptanalysis & High-Performance Substrates.

---

## 1. Production EVM & Security Infrastructure
- **[Volta](https://github.com/creatorofaurad/volta)** — Zero-allocation, bare-silicon EVM stateful verification and dynamic trace reduction engine. Passing 29/29 test suites, verified 0 bytes heap allocations, sub-microsecond execution, with native `crates/volta-rs` Rust bindings and Foundry PoC synthesis.

## 2. Cryptanalysis & Mathematical Complexity
- **[1M](https://github.com/creatorofaurad/1M)** — Fundamental theoretical research on unconditional Boolean circuit size lower bounds via 2-dimensional LSV Ramanujan Complexes, $\varepsilon$-coboundary expansion, and non-linear Boolean Jacobian matrix rigidity over $\mathbb{F}_2$.
- **[Kangaroo Solver](https://github.com/creatorofaurad/kangaroo-solver)** — Hardware-optimized Pollard's Kangaroo discrete logarithm cryptanalysis engine for secp256k1 key recovery within bounded intervals.

## 3. Core Compute Substrates & Runtime Engines
- **[Syzygy](https://github.com/creatorofaurad/syzygy)** — Deterministic bare-silicon compute substrate and kinetic state execution engine with zero runtime overhead.
- **[Zig Tensor Engine](https://github.com/creatorofaurad/zig-tensor-engine)** — Zero-dependency native AVX2 SIMD deep-learning tensor runtime executing vectorized matrix multiplications directly from cache-aligned weights.

## 4. AI & Safety Infrastructure
- **[Aegis Inference](https://github.com/creatorofaurad/aegis-inference)** — Ultra-low-latency 1.58-bit ternary neural network (BitNet) native inference engine designed for zero-heap embedded execution.
- **[Halt](https://github.com/creatorofaurad/Halt)** — Real-time deterministic execution safety rails and opcode-level invariant assertion interceptor.

## 5. Networking & Distributed Mesh
- **[Vektor](https://github.com/creatorofaurad/vektor)** — High-throughput decentralized peer-to-peer compute mesh with lock-free memory mapping and direct socket serialization.

## 6. Systems & Application Layer Utilities
- **[WebAPI](https://github.com/creatorofaurad/webapi)** — Ultra-lightweight asynchronous native backend router.
- **[Scrnthrd](https://github.com/creatorofaurad/scrnthrd)** — Low-latency UI thread synchronization and memory-mapped rendering coordinator.

---

## The Architectural Thesis

Every system in this portfolio is engineered around four non-negotiable silicon invariants:
1. **0 Bytes Dynamic Heap Allocations** on hot execution paths (`malloc`/`free` = 0).
2. **64-Byte Hardware Cache Alignment** across memory pages, stacks, and tensor buffers.
3. **Formal Invariant Verification** over probabilistic heuristic testing.
4. **Zero Third-Party Runtime Bloat**—native code written directly for bare silicon in Zig, C/C++, Rust, and Assembly.
