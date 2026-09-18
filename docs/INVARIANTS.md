# Volta Formal Invariant Proof Sketches & Reference Oracles

**Document Status:** Production Reference  
**Scope:** 17 Protocol Invariant Families  

---

## Invariant Formal Sketches

### 1. Constant Product Monotonicity (AMM)
- **State Variables:** $R_0, R_1$ (Reserves in Slot 0, Slot 1).
- **Oracle Predicate:** $k_{\text{after}} \ge k_{\text{before}} = R_0 \cdot R_1$.
- **Adversarial Failure Mode:** Draining $R_0$ without proportional increase in $R_1$ via sandwich liquidity manipulation.

### 2. ERC-4626 Share Inflation Barrier
- **State Variables:** $A$ (Total Assets), $S$ (Total Shares).
- **Oracle Predicate:** $S = 0 \implies A = 0 \land \frac{A_{t+1}}{S_{t+1}} \ge \frac{A_t}{S_t}$.
- **Adversarial Failure Mode:** Donating assets to an empty vault to round down subsequent depositor share calculations to zero.

### 3. Flash Loan Net Repayment
- **State Variables:** $B_{\text{pre}}, B_{\text{post}}, \text{Fee}$.
- **Oracle Predicate:** $B_{\text{post}} \ge B_{\text{pre}} + \text{Fee}$.
- **Adversarial Failure Mode:** Reentering vault via callback to trick balance query with borrowed funds.

### 4. Protocol Solvency (Lending)
- **State Variables:** $C$ (Cash), $B$ (Total Borrows), $D$ (Depositor Claims).
- **Oracle Predicate:** $C + B \ge D$.
- **Adversarial Failure Mode:** Unbacked bad-debt write-offs leaving depositors undercollateralized.

### 5. GAV Monotonicity (Enzyme Blue)
- **State Variables:** $\text{GAV}_t, \text{GAV}_{t+1}$.
- **Oracle Predicate:** $\text{GAV}_{t+1} \ge \text{GAV}_t - \text{AllowedOutflows}$.
- **Adversarial Failure Mode:** Unaccounted slippage or adapter rebalancing skimming.
