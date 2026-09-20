# Roche Foundry Integration Guide

This guide details how to integrate **Roche** with Foundry projects for automated invariant synthesis, fuzzing acceleration, and executable `.t.sol` PoC generation.

---

## 1. Installation

Add `roche` CLI to your environment or build the native Rust bridge:

```bash
# Clone and build Roche native binary
git clone https://github.com/creatorofaurad/Roche.git
cd Roche
zig build -Doptimize=ReleaseFast

# Add roche to your PATH
export PATH="$PATH:$(pwd)/zig-out/bin"
```

---

## 2. Synthesizing Foundry PoCs from Bytecode

Run Roche against any compiled contract artifact to automatically synthesize a runnable Foundry test:

```bash
# Synthesize Foundry test from compiled artifact bytecode
roche synth \
  --name DynamicFeeHook \
  --bytecode $(cat out/DynamicFeeHook.sol/DynamicFeeHook.json | jq -r .deployedBytecode.object) \
  --out test/RocheDynamicFeeHook.t.sol
```

---

## 3. Running Synthesized Tests

Run standard Foundry commands:

```bash
forge test --match-contract RocheDynamicFeeHookTest -vvvv
```

---

## 4. Rust FFI Integration (`roche-foundry`)

In your Rust tools or Foundry plugins, add `roche-foundry` to your `Cargo.toml`:

```toml
[dependencies]
roche-foundry = { path = "crates/roche-foundry" }
```

Execute synthesis programmatically:

```rust
use roche_foundry::RocheFoundryHarness;

fn main() {
    let bytecode = hex::decode("6080604052348015...").unwrap();
    let solidity_test = RocheFoundryHarness::synthesize_poc("VaultV3", &bytecode).unwrap();
    std::fs::write("test/VaultV3PoC.t.sol", solidity_test).unwrap();
}
```
