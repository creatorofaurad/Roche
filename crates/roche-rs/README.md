# roche-rs

Official Rust C-ABI FFI bindings for **Roche**, the zero-allocation bare-silicon EVM formal invariant verification and differential fuzzing engine.

---

## Installation

Add to your `Cargo.toml`:

```toml
[dependencies]
roche-rs = "1.0.0"
```

---

## Usage

```rust
use roche_rs::RocheEngine;

fn main() {
    let bytecode = hex::decode("6080604052348015600f57600080fd5b5000").expect("Invalid hex");
    let result = RocheEngine::audit(&bytecode);

    println!("Is Vulnerable: {}", result.is_vulnerable);
    println!("Gas Used: {}", result.gas_consumed);
}
```

---

## License

MIT OR Apache-2.0 © [Charles](mailto:srijaan@proton.me)
