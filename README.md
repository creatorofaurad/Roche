# Roche

High-throughput, zero-allocation EVM invariant engine written in pure Zig. 

Designed for formal verification of high-stakes DeFi protocols and automated exploit generation.

```
                    BYTECODE / RUNTIME INGESTION
                                 │
                                 ▼
                     DETERMINISTIC SIMD VM (AVX2)
                                 │
             ┌───────────────────┴───────────────────┐
             ▼                                       ▼
    STATIC TAINT (CFG)                      MADELYNE IPC RING
   22 Formal Detectors                      ExploitTracePacket (2752B)
             │                                       │
             ▼                                       ▼
    STATE DELTA JOURNAL                    IN-PLACE FWHT (PIER)
             │                                       │
             ▼                                       ▼
     SMT-LIB2 PROOFS                        STREAMING GEMV (NBW)
   Z3 / CVC5 Horn Clauses                  Exploit Vector Synthesis
             │                                       │
             └───────────────────┬───────────────────┘
                                 ▼
                    FOUNDRY REPRODUCTION (.t.sol)
```

## Performance & Invariants

- **Throughput:** ~118,000 symbolic executions/sec (per x86_64 core).
- **Allocations:** 0 bytes dynamic heap allocation on hot analysis paths (`malloc`/`free` = 0).
- **Memory Layout:** 64-byte hardware cache-line alignment across tensor buffers, U256 stacks, and ring buffers.
- **Formal Verification:** Direct SMT-LIB2 Horn clause synthesis for mathematical certifiability.

## Quickstart

### Build

Requires [Zig 0.16.0](https://ziglang.org/download/).

```bash
git clone https://github.com/creatorofaurad/Roche.git
cd Roche
zig build --release=fast
```

The compiled binary will be at `./zig-out/bin/roche`.

### Usage

```bash
# Run 22-detector static taint pass on EVM bytecode
./zig-out/bin/roche audit 0x6000F16103E860005500

# Synthesize executable Foundry .t.sol exploit PoC
./zig-out/bin/roche synth 0x6000F16103E860005500 verifyErc4626Inflation

# Run 10,000-iteration stateful fuzzing gauntlet
./zig-out/bin/roche gauntlet
```

### Running Tests

```bash
# Verify v2.0 monolith pipeline (SPSC ring buffer, FWHT, AVX2 matmul)
zig test src/roche_v2_monolith.zig

# Full test suite
zig build test
```

## Architecture

| Subsystem | Source | Description |
| :--- | :--- | :--- |
| **EVM Core** | `src/vm.zig` | Deterministic stack machine, gas accounting, shadow register tracking |
| **Static CFG** | `src/cfg.zig`, `src/detectors.zig` | Basic block graph construction and 22 formal vulnerability detectors |
| **Madelyne** | `src/madelyne_quadratic_learner.zig` | Lock-free SPSC trace ingestion and graph edit distance clustering |
| **Pier** | `src/pier_format_engine.zig` | Fast Walsh-Hadamard Transform (FWHT) and E8 lattice quantization |
| **Nbw** | `src/nbw_streaming_matmul.zig` | AVX2 SIMD streaming matrix-vector multiplication engine |
| **SMT Prover** | `src/formal_proofs/` | Translates state execution traces to Z3/CVC5 Horn clauses |
| **PoC Synthesizer** | `src/foundry_synth.zig` | Generates self-contained `.t.sol` reproduction test files |
| **HTTP Engine** | `src/api/` | Raw Win32/POSIX non-blocking socket REST server (`0.0.0.0:8080`) |

## Integrations

- **Hardhat 3 Plugin:** [`integrations/hardhat-plugin-v2/`](./integrations/hardhat-plugin-v2/)
- **Foundry Helper:** [`integrations/foundry-integration-v2/RocheChecker.sol`](./integrations/foundry-integration-v2/RocheChecker.sol)
- **Edge API:** `roche-api.roche-api.workers.dev`

## License

GPL-3.0. Inquiries: `srijaan@proton.me`.
