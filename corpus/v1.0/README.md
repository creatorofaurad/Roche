# Volta Invariant Regression Corpus v1.0

This directory contains versioned, machine-readable invariant test cases and attack traces for **Volta Milestone 1**.

## Corpus Summary (100+ Total Cases)

| Category | Cases | Target Protocol / Invariant | Status |
| :--- | :--- | :--- | :--- |
| `erc4626_vaults.json` | 20+ | First-deposit donation inflation, share parity, redeem slippage | Verified |
| `amm_invariants.json` | 20+ | Constant product ($x \cdot y \ge k$), multi-hop fee conservation | Verified |
| `lending_solvency.json` | 40+ | Master solvency ($\text{Cash} + \text{Borrows} \ge \text{Claims}$), bad-debt | Verified |
| `eip1153_transient.json` | 15+ | Transient frame isolation, nested rollback, transaction-end reset | Verified |
| `flash_loans.json` | 15+ | Balance conservation + fee collection across receiver callbacks | Verified |
| `historical_exploits.json` | 15+ | Euler V2, Uniswap V4 hook drain, Ethena PSM, Balancer reentrancy | Verified |

## Execution
All corpus test cases are natively executed and formally verified in Volta's test runner:

```bash
zig test src/live_protocol_tests.zig
```
