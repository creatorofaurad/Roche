# Security Policy for Roche

## Reporting Security Vulnerabilities

If you discover a security vulnerability in Roche, **DO NOT** open a public GitHub issue.

Instead, email: **security@roche.dev** with:
1. Detailed description of the vulnerability
2. Steps to reproduce
3. Potential impact
4. Your contact information

We will respond within 48 hours and work with you on a coordinated disclosure timeline.

## Security Guarantees

### Zero-Allocation Promise
Every hot-path execution in Roche (EVM stepping, invariant checking, reporter output) 
is guaranteed to perform zero dynamic memory allocations.

**Verification:** Run `zig build test` to enforce this policy and verify zero memory leaks across all execution frames.

### Deterministic Execution
All bytecode execution is deterministic: same input → same output, every time.
No unseeded randomness, no timing-dependent behavior, no floating-point arithmetic on critical paths.

### State Machine Correctness
Roche's EVM state machine has been tested against the official Ethereum Execution 
Specification Tests (EEST) for Cancun and Prague hardforks.

## Disclosure Timeline

1. **Day 0:** Vulnerability reported
2. **Day 1:** Acknowledgment + impact assessment
3. **Day 7:** Fix ready for internal testing
4. **Day 14:** Security patch released to production
5. **Day 21:** Public CVE and blog post (if applicable)

## Previous Security Audits

- **VERIFICATION_AUDIT.md:** Internal verification audit (Sep 22, 2026)
- Future: Independent formal audits planned for Q1 2027

## Bug Bounty Program

Roche participates in Cantina bug bounty program for discovered vulnerabilities.
See: https://cantina.xyz/bounties/roche

Bounty tier is determined by severity and impact:
- **Critical:** $100K-$250K
- **High:** $50K-$100K
- **Medium:** $10K-$25K
- **Low:** $1K-$5K
