# Volta

Deterministic, bare-metal EVM invariant verification and automated test reduction engine written in pure native Zig 0.16.0.

Volta evaluates smart contract state transitions against formal economic invariants, shrinks multi-transaction violation traces using hierarchical delta-debugging (HDD), and emits self-contained Foundry (`.t.sol`) test cases for local reproduction and CI/CD pipelines.

---

## Core Invariants

- **Zero Dynamic Allocations:** The hot execution path operates with 0 runtime heap allocations (`malloc = 0`). Memory, execution stack, and rollback journals are statically bounded.
- **Cache-Line Alignment:** VM state and SIMD structures are aligned to 64-byte hardware boundaries (`align(64)`) to minimize cache miss penalties.
- **Vectorized Evaluation:** Edge hitmaps, branch masking, and invariant calculations utilize 256-bit AVX2 vectors (`@Vector(32, u8)`, `@Vector(8, u32)`).

---

## Pipeline

```
Bytecode Input (.bin / hex)
  │
  ├── 1. CFG Extraction & Static Analysis (22 Detectors)
  │
  ├── 2. Parallel Coverage-Guided Fuzzing (AVX2 Bitmap Feedback)
  │
  ├── 3. Formal Invariant Verification (17 Mathematical Invariant Families)
  │
  ├── 4. Trace Minimization (Hierarchical Delta-Debugging)
  │
  └── 5. Foundry PoC Emission (.t.sol)
```

---

## Building & Testing

### Requirements
- Zig `0.16.0` (or `0.14.0+` compatible)
- x86_64 CPU with AVX2 support (or fallback scalar build)

### Quickstart

```bash
# Clone the repository
git clone https://github.com/creatorofaurad/volta.git
cd volta

# Run all 25 test suites
zig test src/main.zig

# Build optimized binary
zig build -Doptimize=ReleaseFast
```

---

## CLI Usage

```bash
# Run static analysis and CFG taint checks on bytecode
./zig-out/bin/volta audit <hex_or_bin_file>

# Run multi-threaded fuzzer against a target contract
./zig-out/bin/volta fuzz <hex_or_bin_file> --runs 50000

# Execute full pipeline: Fuzz -> Invariant Check -> Trace Shrink -> Synthesize PoC
./zig-out/bin/volta orchestrate <TargetName> <hex_bytecode> [runs]

# Synthesize a standalone Foundry reproduction test for a known invariant break
./zig-out/bin/volta synth <hex_bytecode> <invariant_name>

# Run the 10,000-pass stateful verification gauntlet
./zig-out/bin/volta gauntlet

# Run native opcode execution benchmark
./zig-out/bin/volta benchmark
```

---

## Supported Invariant Categories

Volta's verification engine evaluates 17 formal invariant families:

1. **AMM Constant Product:** $x \cdot y \ge k$
2. **Total Supply Conservation:** $\sum \text{Balance}(u_i) = \text{TotalSupply}$
3. **ERC-4626 Share Rounding & Inflation:** $\text{previewRedeem}(\text{previewDeposit}(a)) \le a$
4. **Flash Loan Conservation:** $\text{Balance}_{\text{post}} \ge \text{Balance}_{\text{pre}} + \text{Fee}$
5. **Protocol Solvency:** $\text{Assets} \ge \text{Liabilities} + \text{BadDebt}$
6. **McCarthy Frame Independence:** $\forall s \neq s_{\text{modified}}, \, \sigma'(s) = \sigma(s)$
7. **Oracle Freshness:** $t_{\text{current}} - t_{\text{updated}} \le \Delta t_{\max}$
8. **EIP-1153 Transient Cleanliness:** $\forall s, \, T_{\text{exit}}(s) = 0$
9. **Perpetual Margin Solvency:** $\text{Collateral} \ge \text{MaintenanceMargin} + \text{PnL}_{\text{deficit}}$
10. **LSD Exchange Rate Ceiling:** $\frac{\text{stToken}}{\text{Underlying}} \le \text{MaxExchangeRate}$
11. **Bridge Conservation:** $\text{Minted}_{L2} \le \text{Locked}_{L1} - \text{Burned}_{L2}$
12. **Concentrated Liquidity Bounds:** $\text{Tick}_{\text{lower}} \le \text{Tick}_{\text{current}} \le \text{Tick}_{\text{upper}}$
13. **Governance Timelock:** $t_{\text{exec}} \ge t_{\text{queue}} + \text{Delay}_{\min}$
14. **Curve Virtual Price Monotonicity:** $VP_{\text{post}} \ge VP_{\text{pre}} \cdot (1 - \delta_{\max})$
15. **Balancer Vault Reentrancy Lock:** Reentrancy guard slot consistency during external calls
16. **Gross Asset Value (GAV) Monotonicity:** $\text{GAV}_{\text{post}} \ge \text{GAV}_{\text{pre}}$ during portfolio rebalancing
17. **Redemption Queue Conservation:** $\text{Assets}_{\text{redeemed}} \ge \frac{\text{Shares}_{\text{burned}} \cdot \text{Price}}{10^{18}}$

---

## Architecture Overview

```
src/
├── main.zig              # Entrypoint and CLI dispatcher
├── types.zig             # Core types, U256 stack words, AVX2 SIMD definitions
├── vm.zig                # Deterministic EVM interpreter (Yellow Paper / Cancun)
├── storage.zig           # McCarthy storage rings and EIP-1153 transient storage
├── cfg.zig               # Basic block disassembler & edge discovery
├── detectors.zig         # 22 static vulnerability detectors
├── invariants.zig        # Formal invariant verification engine
├── fuzzer.zig            # Coverage-guided havoc fuzzer & dictionary extractor
├── arena.zig             # Multi-target fuzzing harness & walk-forward validator
├── foundry_synth.zig     # Standalone Foundry .t.sol PoC generator
├── orchestrator.zig      # End-to-end pipeline coordinator
├── live_protocol_tests.zig # 13 protocol target test suites
└── kernel_router.zig     # POSIX/Win32 signal & interrupt handlers
```

---

## Output Example

When an invariant violation is identified, Volta emits a minimal Foundry test (`.t.sol`):

```solidity
// SPDX-License-Identifier: MIT
// Auto-generated by Volta
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

contract VoltaExploitReproductionTest is Test {
    address public attacker = address(0xAA);

    function setUp() public {
        vm.deal(attacker, 100 ether);
    }

    function test_reproduce_invariant_violation() public {
        vm.startPrank(attacker);
        bytes memory targetBytecode = hex"6000F16103E860005500";
        address targetContract;
        assembly {
            targetContract := create(0, add(targetBytecode, 0x20), mload(targetBytecode))
        }
        require(targetContract != address(0), "Deployment failed");

        (bool step0_success,) = targetContract.call{value: 0}(abi.encodeWithSelector(bytes4(0xA9059C00)));
        require(step0_success, "Step 0 execution failed");

        assertTrue(false, "Volta Invariant Broken: verifyConstantProduct");
        vm.stopPrank();
    }
}
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
