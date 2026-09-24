# Example Audit Case Study: Uniswap V3 Core

## Command Execution

```bash
roche audit --target ./contracts/uniswap-v3/UniswapV3Pool.sol --z3-prove
```

## Audit Findings Summary

| ID | Title | Severity | Location | Status |
| :--- | :--- | :--- | :--- | :--- |
| `ROCHE-MATH-001` | Unchecked Liquidity Underflow | Informational | `UniswapV3Pool.sol#L412` | Verified Safe via Z3 |
| `ROCHE-SWAP-002` | Precision Loss in Tick Calculation | Low | `TickMath.sol#L78` | Verified Safe |

## Symbolic Proof Output

```text
[INFO] Starting Symbolic Execution Engine (Depth: 1000)
[Z3] Checking invariant: tick >= MIN_TICK && tick <= MAX_TICK
[Z3] Proof SATISFIED: No overflow path reachable in 4,129 steps.
```
