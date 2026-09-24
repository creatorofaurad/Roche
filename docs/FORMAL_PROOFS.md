# Roche Formal Proofs & Verification

## Overview

Roche integrates SMT solvers (Z3 / CVC5) to provide mathematical proofs of correctness or exploitability for EVM smart contracts.

## Mathematical Model

Let \( S \) be the state space of an EVM contract, \( T: S \times I \to S \) be the transition function given input \( I \), and \( P: S \to \{0, 1\} \) be an invariant property.

Roche proves:
\[ \forall s_0 \in S_{init}, \forall (i_1, i_2, \dots, i_k), \quad P(T(T(\dots T(s_0, i_1), \dots), i_k)) = 1 \]

If a violation is found, Roche generates a counterexample execution trace.

---

## Running Solvers

```bash
roche prove --target ./contracts/Token.sol --property invariants/total_supply.smt2
```

## Solvers Supported

- **Z3**: Default SMT solver for bit-vector arithmetic and array theory.
- **CVC5**: Alternative solver for complex quantifiers and integer linear arithmetic.
