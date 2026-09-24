# Example Audit Case Study: Aave V3 Protocol

## Command Execution

```bash
roche audit --target ./contracts/aave-v3/Pool.sol --detectors flashloan,reentrancy
```

## Security Verification Highlights

- **Flashloan Security**: Verified health factor invariants post-flashloan execution.
- **Interest Rate Model**: Validated non-zero compounding interest rate accumulators under high state growth scenarios.
