# Volta 100x Architecture & Execution Specification

## Section 1: Low-Level Profiling & Hot-Path Optimization
### 1.1 Profiling Hot Paths & Latency Budget
| Subsystem | Function | Bottleneck Mechanics | Optimization Strategy |
| :--- | :--- | :--- | :--- |
| **Opcode Dispatch** | `VM.execute` | Sparse `switch(op)` compiles to binary comparison tree on LLVM, causing branch misprediction stalls. | Clustered direct jump tables & peephole super-instructions (`PUSH32+MSTORE`, `DUP1+SLOAD`). |
| **Storage Journal** | `StorageState.store` | Linear rollback recording with 64-byte padded entries. | Append-Only Circular WAL (40B compact layout) indexed by address and slot. |
| **Trace Minimization** | `fuzzer.shrinkSequence`| Linear sequential single-call elimination ($O(N^2)$). | Hierarchical Delta-Debugging (HDD) bisection search ($O(N \log N)$). |
| **Coverage Bitmap** | `CoverageEngine` | Byte-wise reset on 64KB table between runs. | AVX2 SIMD `@Vector(32, u8)` zero-splatting clearing 64KB in 64 clock cycles. |

---

## Section 2: EVM Specification Compliance (Cancun / Prague)
1. **`STATICCALL (0xFA)` Invariant:** Enforce static execution context. Any invocation of `SSTORE`, `TSTORE`, `LOG0..LOG4`, `CREATE`, `CREATE2`, or `SELFDESTRUCT` triggers an immediate `STATIC_MODE_VIOLATION` revert.
2. **`DELEGATECALL (0xF4)` Invariant:** Caller and value are preserved from the parent frame, executing code in the current account's storage context.
3. **`MCOPY (0x5E)` Invariant:** SIMD block memory copy with boundary and overlap validation.
4. **Transient Storage (EIP-1153):** Address-scoped transient map bounded to transaction lifetime and unwound upon sub-frame reverts.

---

## Section 3: Protocol Breadth & Invariant IR
```
+-----------------------------------------------------------------------------------------------+
|                                    VOLTA INVARIANT IR (I-IR)                                  |
|                                                                                               |
|  1. Solvency & Bad Debt:        Cash + OutstandingBorrows >= TotalDepositorClaims             |
|  2. AMM Constant Product:       Reserve0 * Reserve1 >= k                                      |
|  3. ERC-4626 Share Inflation:   TotalAssets > 0 -> TotalShares > 0                            |
|  4. Perp Futures Margin:        VaultCollateral >= Margin + UnrealizedPnL + FeePool           |
|  5. Liquid Staking (LSD):       stTokenSupply / StakedAsset <= TargetRate * (1 + epsilon)     |
|  6. Bridge Conservation:        L2_Minted <= L1_Locked - L2_Burned                            |
+-----------------------------------------------------------------------------------------------+
```

---

## Section 4: Modularity & Extensible Architecture
- **Data-Driven Action Alphabets:** Decouple protocol test cases from VM internals using structured selectors, weight distributions, and precondition filters.
- **Detector Plugin Architecture:** Modular static analysis registry supporting custom detector passes with zero runtime heap allocation.
- **Foundry PoC Synthesizer:** Auto-emit runnable Foundry `.t.sol` test files for any minimized counterexample trace.
