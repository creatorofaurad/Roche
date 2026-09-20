# ROCHE Specification Compliance & Execution Contract

**Document Status:** Frozen  
**Target Specification:** Ethereum Yellow Paper (Cancun / EIP-7692 / Prague Scope)  
**Execution Paradigm:** Zero Dynamic Heap Allocation (`malloc = 0`)  

---

## 1. The Execution Contract

ROCHE evaluates smart contract state machines under the following explicit execution contract:

### 1.1 Memory & Stack Bounds
- **Stack Depth:** Fixed 1024 256-bit words (`types.MAX_STACK_DEPTH`). PUSH past 1024 triggers deterministic `STACK_OVERFLOW`; POP on empty triggers `STACK_UNDERFLOW`.
- **Linear Memory:** Bounded static 4096-byte array (`types.MAX_MEMORY_BYTES`) per execution context with 64-byte L1 cache-line alignment (`align(64)`).
- **Calldata & Returndata:** Preallocated static buffers (`MAX_CALLDATA_BYTES = 4096`, `MAX_RETURNDATA_BYTES = 4096`).

### 1.2 Storage Model & Rollbacks
- **McCarthy Frame Model:** State is modeled as an array of 256-bit slots indexed by account and key.
- **Rollback Journal:** 40-byte Write-Ahead Log entries (`storage.JournalEntry`). State reversions rewind the journal entries in $O(\text{mutations})$ without memory cloning.
- **Transient Storage (EIP-1153):** Independent key-value mapping per transaction, zeroed at transaction boundary.

### 1.3 Cancun Opcode Compliance
- `0x5F` **PUSH0** (EIP-3855): Validated $\to$ pushes 0 onto stack with 0 gas overhead.
- `0x5E` **MCOPY** (EIP-5656): Validated $\to$ handles overlapping memory copy via `std.mem.copyForwards` / `copyBackwards`.
- `0x5C`/`0x5D` **TLOAD**/**TSTORE** (EIP-1153): Validated $\to$ transient storage isolation.
- `0x49`/`0x4A` **BLOBHASH**/**BLOBBASEFEE** (EIP-4844 / EIP-7516): Validated against `CheatcodeContext`.

### 1.4 Documented Simplifications & Scope Bounds
1. **Gas Metering:** Gas is unmetered (pushes 30M default) during pure invariant exploration. Invariant detection is governed by instruction step count and path depth rather than gas exhaustion.
2. **Event Logs (`LOG0`..`LOG4`):** Pops parameters and validates static context (`STATIC_MODE_VIOLATION`), but does not serialize bloom filters.
3. **Precompiles (`0x01`..`0x0A`):** `0x01` (ecrecover) and `0x02` (sha256) are mapped via Zig standard crypto; advanced elliptic curves (`bn256Pairing`, `bls12-381`) are stubbed for Phase 1 EEST integration.

---

## 2. Invariant Discovery vs. Standard EVM Runtimes

ROCHE is not designed as a general-purpose block producer; it is designed as an **invariant verification engine**. Its core execution invariants guarantee:
- Bitwise deterministic replay on all state transitions.
- Sub-nanosecond ($<1.00\text{ ns}$) invariant assertion checks after every state-modifying instruction.
- Automated trace delta-debugging ($O(N \log N)$) to emit minimal Foundry `.t.sol` reproduction suites.

