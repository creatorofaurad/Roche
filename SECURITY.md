# Security Policy & Responsible Disclosure

## 1. Scope & Philosophy

Roche is engineered from the ground up as a defensive, high-assurance formal invariant verification engine. We uphold the highest standards of memory safety, deterministic execution, and cryptographic integrity.

We welcome security researchers, auditors, and protocol developers to audit our engine and disclose vulnerabilities responsibly.

---

## 2. Reporting a Vulnerability

If you discover a security issue, memory safety flaw, or invariant soundness bug in Roche, please report it immediately to our security desk via **ProtonMail**:

📧 **`srijaan@proton.me`**

### What to Include in Your Report:
1. **Description:** A detailed explanation of the vulnerability or soundness flaw.
2. **Reproducible Test Case:** A minimal, standalone Zig or Foundry test harness reproducing the failure.
3. **Engine Version / Commit Hash:** The exact Git commit hash of Roche where the issue was observed.
4. **Impact Assessment:** Explanation of whether the flaw causes false-negative proof generation, memory corruption, or denial-of-service in sequencer filtering.

---

## 3. Responsible Disclosure SLA

- **Initial Response:** We will acknowledge receipt of your report within **24 hours**.
- **Triage & Reproduction:** We will confirm reproducibility and determine severity within **48 hours**.
- **Fix & Patch Deployment:** Critical soundness or memory flaws will be patched and committed within **7 days**.
- **Public Disclosure:** Coordinated disclosure will occur only after a patch is merged and deployed across active protocol pilots.

---

## 4. Supported Versions

| Version | Supported | Security Maintenance |
| :--- | :--- | :--- |
| `v0.16.x` (Current) | ✅ Yes | Active formal testing & bug fixes |
| `< v0.16.0` | ❌ No | Deprecated legacy prototypes |

---

## 5. Security & Verification Invariants

Roche enforces the following permanent silicon invariants across all production releases:
- **0 Bytes Dynamic Heap Allocation:** Hot-path execution allocates zero dynamic heap memory (`malloc`/`free` = 0).
- **64-Byte Hardware Cache Alignment:** Tensor blocks, storage rollback rings, and stack memory are strictly hardware cache-aligned.
- **Deterministic Formal Proofs:** SMT array theory solves state taints without probabilistic heuristics or non-deterministic race conditions.

*Thank you for helping keep the Roche verification engine and the broader DeFi ecosystem secure.*
