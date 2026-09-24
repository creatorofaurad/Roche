# Example Audit Case Study: Balancer V2 Vault

## Command Execution

```bash
roche audit --target ./contracts/balancer-v2/Vault.sol
```

## Security Findings & Proofs

- **Flashloan Reentrancy**: Verified read-only reentrancy resistance across multi-token pool join/exit calls.
- **Invariant Bounds**: Formally checked weighted math invariant logic for token balance edge cases (e.g. 1 wei swaps).
