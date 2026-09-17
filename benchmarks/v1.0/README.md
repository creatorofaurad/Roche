# Volta Benchmark Suite v1.0

This directory contains the canonical hardware benchmark suite for **Volta v1.0**.

## Execution Instructions

Requirements: **Zig 0.16.0+**

```bash
# Run benchmark with ReleaseFast optimizations
zig run -O ReleaseFast ../../src/benchmark_harness.zig
```

## Workload Coverage
1. **Invariant IR Evaluation (AMM $x \cdot y \ge k$ Monotonicity)**: Evaluates constant-product pool reserves with 512-bit intermediate math.
2. **EIP-1153 Transient Storage Operations (`TSTORE`/`TLOAD`)**: Measures transient frame lifecycle and isolation costs.
3. **AVX2 SIMD Vectorized Invariant Math**: Tests parallel 256-bit register evaluation on 8 accounts simultaneously.
4. **State Rollback Journaling**: Measures $O(1)$ checkpoint rollback speed under simulated `REVERT` boundaries.
5. **Foundry `.t.sol` Synthesis**: Measures code generation throughput converting action sequences into compilable Solidity test files.
