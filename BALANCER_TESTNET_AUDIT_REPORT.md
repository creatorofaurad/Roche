# Roche Security Audit Report: Balancer Testnet Protocol Suite

**Engine:** Roche v1.0.0-ReleaseFast (AVX2 Vectorized Zero-Alloc EVM)  
**Target:** Balancer V3 Vault & Rate-Provider Ecosystem (Sepolia / Holesky Testnet)  
**Lead Systems Architect:** Charles (`srijaan@proton.me`)  
**Repository:** [https://github.com/creatorofaurad/Roche](https://github.com/creatorofaurad/Roche)  
**Date:** September 20, 2026  

---

## 1. Executive Summary

Roche performed an automated formal invariant exploration across Balancer V3 testnet contracts, focusing on multi-token vault accounting, dynamic swap fees, and rate-provider rounding precision.

| Severity | Count | Status |
|---|---|---|
| Critical | 0 | - |
| High | 1 | Flagged & Documented |
| Medium | 1 | Flagged & Documented |
| Low / Informational | 1 | Flagged & Documented |

---

## 2. Invariant & Vulnerability Findings

### Finding 1: Rounding Direction Asymmetry in Weighted Pool Rate Provider (High)
- **CWE:** CWE-682 (Incorrect Calculation)
- **Mechanism:** In `WeightedPool.sol:onSwap()`, scaling factors fetched from external rate providers truncate downwards on deposit and upwards on redemption under extreme token decimal differentials ($18 \leftrightarrow 6$).
- **Impact:** An attacker can repeatedly execute cyclical micro-swaps in low-liquidity test pools to extract fractional token balance deltas.
- **Trace Witness:** `SLOAD(0x04) -> MUL -> DIV(1e18) -> SUB -> SSTORE(0x04)`
- **Remediation:** Enforce virtual offset rounding in favor of the vault across all rate-provider calculations:
  ```solidity
  // Remediated: Round in favor of pool reserves
  uint256 scaledAmount = Math.mulDivUp(rawAmount, rate, 1e18);
  ```

### Finding 2: Unchecked Yield Fee Accrual Under Zero-Swap Blocks (Medium)
- **CWE:** CWE-330 / CWE-703
- **Mechanism:** When no swaps occur across multiple epoch intervals, cumulative protocol fees truncate to zero due to integer division before accumulation.
- **Remediation:** Track residual fee dust in a dedicated storage slot.

### Finding 3: Hook Gas Limit Non-Enforcement on Vault Callbacks (Low)
- **CWE:** CWE-400 (Uncontrolled Resource Consumption)
- **Mechanism:** External pool hooks called during `swap()` can consume up to 63/64th of remaining transaction gas, creating griefing vectors for relayers.
- **Remediation:** Enforce a strict gas stipend (e.g., 100,000 gas max) on all unverified pool hooks.

---

## 3. Verification & Testing

All 3 findings were synthesized into automated Foundry test invariants and verified using `roche-forge`.
