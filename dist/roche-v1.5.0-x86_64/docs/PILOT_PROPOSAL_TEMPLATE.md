# Roche Automated Invariant Verification: Protocol Pilot Agreement

**Effective Date:** October 1, 2026  
**Provider:** Roche Systems Architecture (`srijaan@proton.me`)  
**Client / Protocol:** [Protocol / Partner Name]  
**Lead Systems Architect:** Charles  

---

## 1. Scope of Pilot Engagement

Roche provides [Protocol Name] with a **3-month zero-cost evaluation pilot** of the Roche Bare-Silicon EVM Formal Verification and Automated Fuzzing Engine.

### Core Deliverables Provided by Roche:
1. **GitHub Actions CI/CD Integration:** Automated deployment of `@roche/audit` into the protocol’s core repositories, running formal invariant checks on every pull request.
2. **Automated Exploit PoC Synthesis:** Automatic generation of executable Foundry `.t.sol` regression test suites for any detected state boundary violations or invariant regressions.
3. **Pre-Deployment Formal SMT Audit:** Comprehensive symbolic invariant evaluation across all core smart contracts prior to testnet/mainnet launches.
4. **Dedicated Engineering Channel:** Direct private communication with Lead Systems Architect Charles for technical troubleshooting.

---

## 2. Success Criteria & Evaluation Metrics

The pilot engagement will be deemed successful upon satisfying the following verifiable metrics:
- **Zero False-Positive Alert Fatigue:** Over 95% of flagged state invariant warnings represent legitimate edge-case arithmetic, access control, or reentrancy anomalies.
- **Sub-Minute CI Execution:** Automated invariant runs complete within 60 seconds per PR in standard GitHub Actions environments.
- **Trace Minimization:** Discovered state anomalies are automatically reduced to minimal $\le 5$-opcode causal witnesses.

---

## 3. Commercial Transition Terms

Upon successful completion of the 3-month pilot period:
- **Annual Enterprise Contract:** [Protocol Name] may convert to an annual enterprise tier ($36,000 USD / year) including custom invariant rule generation, dedicated multi-node cluster compute, and continuous on-chain sequencer monitoring.
- **No Lock-In:** If [Protocol Name] chooses not to transition, all generated Foundry test files and audit reports remain 100% owned by the protocol under open-source licenses.

---

## 4. Signatures & Acceptance

**For Roche:**  
*Charles*  
Lead Systems Architect, Roche  
Date: September 20, 2026  

**For [Protocol Name]:**  
*[Authorized Representative Name / Title]*  
Date: ________________________
