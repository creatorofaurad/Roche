# Roche EVM Security Engine v2.0 - Release Notes

We are thrilled to announce **Roche v2.0**, a major release engineered for extreme performance, mathematical rigor, and developer ergonomics.

## Key Highlights

- ⚡ **Native Zig 0.16.0 Performance**: Zero dynamic allocations in critical hot paths provide up to 10x faster execution than previous versions.
- 🔬 **Formal Symbolic Verification**: Deep SMT solver integration powered by Z3 proving contract safety invariants.
- 📊 **Interactive Dashboard**: Modern UI for visual control flow graph (CFG) analysis and execution trace debugging.
- 🛠️ **Integrations**: Native plugins for Hardhat, Foundry, and GitHub Actions.

## Installation

```bash
git clone https://github.com/creatorofaurad/Roche.git
cd Roche
zig build -Doptimize=ReleaseFast
```

For detailed documentation, explore the `/docs` directory.
