# Roche EVM Security Engine v2.0 - Changelog

## [2.0.0] - 2026-09-24

### Added
- **Native Zig 0.16.0 Core Engine**: Rebuilt the core EVM analyzer from scratch with zero dynamic memory allocation state machines.
- **Formal Solver Integration**: Built-in support for Z3 and CVC5 SMT solvers to provide exact mathematical proofs.
- **Interactive Dashboard**: Modern web interface for analyzing execution traces and control flow graphs.
- **Foundry & Hardhat Plugins**: First-class support for compiled artifacts from `forge` and `hardhat`.

### Changed
- Replaced dynamic heap allocation in symbolic stack evaluation with fixed-size ring buffers.
- Improved audit speed by 10x compared to v1.x engine.

### Fixed
- Fixed path explosion issue during recursive contract call parsing.
- Resolved memory leak when parsing malformed ABI JSON schemas.
