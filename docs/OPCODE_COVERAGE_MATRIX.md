# EVM Opcode Coverage Matrix (Cancun / Prague Scope)

**Audited File:** `src/vm.zig`  
**Standard:** Ethereum Yellow Paper (Cancun / EIP-7692 / Prague)  
**Execution Runtime:** Pure Zig 0.16.0 (Zero Dynamic Heap Allocations)  
**Last Audited:** 2026-09-18  

---

## 1. Executive Summary

| Category | Total Opcodes | Implemented (✅) | Stubbed / Simplified (⚠️) | Missing / Invalid (❌) |
| :--- | :--- | :--- | :--- | :--- |
| **0x00s: Stop & Arithmetic** | 12 | 12 | 0 | 0 |
| **0x10s: Comparison & Bitwise** | 14 | 14 | 0 | 0 |
| **0x20s: Cryptographic (Keccak)** | 1 | 1 | 0 | 0 |
| **0x30s: Environmental State** | 16 | 16 | 0 | 0 |
| **0x40s: Block Environment** | 11 | 9 | 2 (BLOCKHASH, PREVRANDAO) | 0 |
| **0x50s: Stack, Memory & Storage** | 16 | 15 | 1 (GAS) | 0 |
| **0x60s-0x70s: Push Operations** | 33 | 33 (PUSH0..PUSH32) | 0 | 0 |
| **0x80s: Duplication Operations** | 16 | 16 (DUP1..DUP16) | 0 | 0 |
| **0x90s: Exchange Operations** | 16 | 16 (SWAP1..SWAP16) | 0 | 0 |
| **0xA0s: Logging Operations** | 5 | 0 | 5 (LOG0..LOG4 stubbed) | 0 |
| **0xF0s: System Operations** | 11 | 6 (CREATE, CREATE2, RETURN, REVERT, INVALID, SELFDESTRUCT) | 5 (CALL, CALLCODE, DELEGATECALL, STATICCALL, AUTH/AUTHCALL) | 0 |
| **Total Defined Opcodes** | **151** | **138 (91.4%)** | **13 (8.6%)** | **0 Unhandled Crashers** |

---

## 2. Granular Opcode Breakdown

### 0x00s: Stop & Arithmetic Operations
- `0x00` **STOP**: ✅ Implemented (Breaks execution cleanly).
- `0x01` **ADD**: ✅ Implemented (Wrapping 256-bit addition `+%`).
- `0x02` **MUL**: ✅ Implemented (Wrapping 256-bit multiplication `*%`).
- `0x03` **SUB**: ✅ Implemented (Wrapping 256-bit subtraction `-%`).
- `0x04` **DIV**: ✅ Implemented (Division with zero check $\to 0$).
- `0x05` **SDIV**: ✅ Implemented (Signed 256-bit division via `@divTrunc`).
- `0x06` **MOD**: ✅ Implemented (Modulo with zero check $\to 0$).
- `0x07` **SMOD**: ✅ Implemented (Signed 256-bit modulo via `@rem`).
- `0x08` **ADDMOD**: ✅ Implemented (512-bit intermediate modulo addition).
- `0x09` **MULMOD**: ✅ Implemented (512-bit intermediate modulo multiplication).
- `0x0A` **EXP**: ✅ Implemented (Square-and-multiply bitwise exponentiation).
- `0x0B` **SIGNEXTEND**: ✅ Implemented (Bitwise sign-extension).

### 0x10s: Comparison & Logic Operations
- `0x10` **LT**: ✅ Implemented (Unsigned less-than).
- `0x11` **GT**: ✅ Implemented (Unsigned greater-than).
- `0x12` **SLT**: ✅ Implemented (Signed less-than via `i256`).
- `0x13` **SGT**: ✅ Implemented (Signed greater-than via `i256`).
- `0x14` **EQ**: ✅ Implemented (256-bit equality).
- `0x15` **ISZERO**: ✅ Implemented (Zero predicate).
- `0x16` **AND**: ✅ Implemented (Bitwise AND).
- `0x17` **OR**: ✅ Implemented (Bitwise OR).
- `0x18` **XOR**: ✅ Implemented (Bitwise XOR).
- `0x19` **NOT**: ✅ Implemented (Bitwise NOT).
- `0x1A` **BYTE**: ✅ Implemented (Byte extraction).
- `0x1B` **SHL**: ✅ Implemented (Logical shift left).
- `0x1C` **SHR**: ✅ Implemented (Logical shift right).
- `0x1D` **SAR**: ✅ Implemented (Arithmetic signed shift right).

### 0x20s: Cryptographic Hashes
- `0x20` **KECCAK256**: ✅ Implemented (Native `std.crypto.hash.sha3.Keccak256` memory slice hashing).

### 0x30s: Environmental Information
- `0x30` **ADDRESS**: ✅ Implemented (Pushes current contract address).
- `0x31` **BALANCE**: ✅ Implemented (Queries `WorldState` account balance).
- `0x32` **ORIGIN**: ✅ Implemented (Pushes tx origin address).
- `0x33` **CALLER**: ✅ Implemented (Pushes context caller, respects `vm.prank`).
- `0x34` **CALLVALUE**: ✅ Implemented (Pushes context msg.value).
- `0x35` **CALLDATALOAD**: ✅ Implemented (Big-endian 32-byte calldata slice).
- `0x36` **CALLDATASIZE**: ✅ Implemented (Calldata length).
- `0x37` **CALLDATACOPY**: ✅ Implemented (Memory-bounded calldata copy).
- `0x38` **CODESIZE**: ✅ Implemented (Active bytecode length).
- `0x39` **CODECOPY**: ✅ Implemented (Bytecode slice memory copy).
- `0x3A` **GASPRICE**: ✅ Implemented (Gas price context).
- `0x3B` **EXTCODESIZE**: ✅ Implemented (WorldState code length query).
- `0x3C` **EXTCODECOPY**: ✅ Implemented (WorldState code copy).
- `0x3D` **RETURNDATASIZE**: ✅ Implemented (Dynamic returndata length).
- `0x3E` **RETURNDATACOPY**: ✅ Implemented (Returndata slice copy).
- `0x3F` **EXTCODEHASH**: ✅ Implemented (Account code Keccak256 hash).

### 0x40s: Block Information
- `0x40` **BLOCKHASH**: ⚠️ Stubbed (`0xDEADBEEFCAFE1337` fallback). *Classification: Low severity for local invariant fuzzing.*
- `0x41` **COINBASE**: ✅ Implemented (Returns coinbase account).
- `0x42` **TIMESTAMP**: ✅ Implemented (Context timestamp, respects `vm.warp`).
- `0x43` **NUMBER**: ✅ Implemented (Context block number, respects `vm.roll`).
- `0x44` **PREVRANDAO**: ⚠️ Stubbed (`0x13371337BEEFBEEF` pseudo-randomness).
- `0x45` **GASLIMIT**: ✅ Implemented (Fixed 30M default).
- `0x46` **CHAINID**: ✅ Implemented (Context chain ID, default 1).
- `0x47` **SELFBALANCE**: ✅ Implemented (Current address balance).
- `0x48` **BASEFEE**: ✅ Implemented (Context basefee).
- `0x49` **BLOBHASH** (EIP-4844): ✅ Implemented (Reads blob hash array).
- `0x4A` **BLOBBASEFEE** (EIP-7516): ✅ Implemented (Context blob basefee).

### 0x50s: Stack, Memory & Storage
- `0x50` **POP**: ✅ Implemented.
- `0x51` **MLOAD**: ✅ Implemented (32-byte big-endian memory read).
- `0x52` **MSTORE**: ✅ Implemented (32-byte big-endian memory write).
- `0x53` **MSTORE8**: ✅ Implemented (1-byte memory write).
- `0x54` **SLOAD**: ✅ Implemented (McCarthy storage select).
- `0x55` **SSTORE**: ✅ Implemented (Static-mode check + McCarthy storage store).
- `0x56` **JUMP**: ✅ Implemented (JUMPDEST boundary validation).
- `0x57` **JUMPI**: ✅ Implemented (Conditional jump with destination validation).
- `0x58` **PC**: ✅ Implemented (Current program counter).
- `0x59` **MSIZE**: ✅ Implemented (Linear memory size in bytes).
- `0x5A` **GAS**: ⚠️ Stubbed (Pushes 30,000,000; gas tracking unmetered for pure invariant evaluation).
- `0x5B` **JUMPDEST**: ✅ Implemented (Valid jump target anchor).
- `0x5C` **TLOAD** (EIP-1153): ✅ Implemented (Transient storage read).
- `0x5D` **TSTORE** (EIP-1153): ✅ Implemented (Static-mode check + transient storage write).
- `0x5E` **MCOPY** (EIP-5656): ✅ Implemented (Cancun memory block copy).
- `0x5F` **PUSH0** (EIP-3855): ✅ Implemented (Cancun zero-byte push).

### 0x60s-0x7Fs: Push Operations
- `0x60`..`0x7F` **PUSH1..PUSH32**: ✅ Fully Implemented (Parameterized byte width extraction).

### 0x80s: Duplication Operations
- `0x80`..`0x8F` **DUP1..DUP16**: ✅ Fully Implemented (Stack peek at depth $N$).

### 0x90s: Exchange Operations
- `0x90`..`0x9F` **SWAP1..SWAP16**: ✅ Fully Implemented (Stack word swapping at depth $N+1$).

### 0xA0s: Logging Operations
- `0xA0`..`0xA4` **LOG0..LOG4**: ⚠️ Stubbed (Pops memory offset, size, and $N$ topics; enforces `STATIC_MODE_VIOLATION` under static call context).

### 0xF0s: System & Call Operations
- `0xF0` **CREATE**: ✅ Implemented (Instantiates account in WorldState, deploys code).
- `0xF1` **CALL**: ⚠️ Simplified (Pushes success=1; full child frame isolation to be hardened in Phase 1 EEST).
- `0xF2` **CALLCODE**: ⚠️ Simplified (Pushes success=1).
- `0xF3` **RETURN**: ✅ Implemented (Slices returndata and halts with SUCCESS).
- `0xF4` **DELEGATECALL**: ⚠️ Simplified (Preserves context caller; full child frame execution in Phase 1).
- `0xF5` **CREATE2**: ✅ Implemented (Deterministic address generation and WorldState deployment).
- `0xFA` **STATICCALL**: ⚠️ Simplified (Enforces read-only execution context; child frame in Phase 1).
- `0xFD` **REVERT**: ✅ Implemented (Slices returndata, halts with `.REVERTED` status).
- `0xFE` **INVALID**: ✅ Implemented (Halts with `.INVALID_OPCODE`).
- `0xFF` **SELFDESTRUCT**: ✅ Implemented (Static mode check + account burn).

---

## 3. Prioritized Gap Classification

1. **Critical for Phase 1 (EEST Compliance):**
   - Implement true recursive `ExecutionContext` child-frame dispatch for `CALL`, `DELEGATECALL`, and `STATICCALL` with McCarthy rollback journaling.
2. **Important for Phase 2 (Differential Testing):**
   - Precise gas metering arithmetic for EIP-150 / EIP-158 gas burn rules.
3. **Nice-to-Have (Non-Blocking for Invariants):**
   - `BLOCKHASH` ring-buffer history.
   - `LOG0..LOG4` event stream serialization.
