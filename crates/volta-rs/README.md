# `volta-rs`

[![Crates.io](https://img.shields.io/badge/crates.io-v0.2.0-orange.svg)](https://crates.io)
[![License](https://img.shields.io/badge/license-MIT%20OR%20Apache--2.0-blue.svg)](LICENSE)
[![Engine](https://img.shields.io/badge/engine-Zig%200.16.0-green.svg)](https://ziglang.org)

**Native Rust FFI Bindings and Foundry Trace Reduction Plugin for Volta.**

Volta is an institutional-grade bare-silicon EVM stateful verification and dynamic trace reduction engine engineered in Pure Zig 0.16.0 with **0 dynamic heap allocations**.

---

## Capabilities

- **Sub-Microsecond Execution:** In-register stack VM with 128 KB cache-aligned memory and $O(1)$ rollback journals.
- **Dynamic RAW Trace Reduction:** Backward DAG reachability bisection collapsing 10,000-step execution traces into minimal ($\le 4$ steps) causal failure sequences.
- **Automated Exploit Synthesis:** Generates fully runnable Foundry `.t.sol` test harnesses with ERC-3156 flash loans and Uniswap v4 hook callbacks.
- **22-Detector Static Security Engine:** Slither-equivalent static bytecode security audit in $<50\mu s$.

---

## Installation

Add to your `Cargo.toml`:

```toml
[dependencies]
volta-rs = "0.2.0"
```

---

## Quickstart

### 1. Dynamic Trace Minimization
```rust
use volta_rs::{Volta, CTraceResult};

fn main() {
    let read_slots = [0x00, 0x00, 0x100];
    let write_slots = [0x100, 0x200, 0x00];
    let failing_step = 2;

    if let Some(res) = Volta::minimize_trace(&read_slots, &write_slots, failing_step) {
        println!("Trace reduced from {} to {} causal steps in {}ns", 
            res.original_steps, res.minimized_steps, res.elapsed_nanos);
    }
}
```

### 2. Automated Foundry PoC Synthesis
```rust
use volta_rs::{Volta, CallbackType};

fn main() {
    let poc = Volta::synthesize_poc(
        "EulerVaultInsolvencyExploit",
        "6000F16103E860005500",
        "verifySolvency",
        CallbackType::ERC3156FlashBorrower,
    ).expect("Synthesis failed");

    println!("{}", poc);
}
```

---

## License

MIT OR Apache-2.0
