# Roche EVM Security Engine v2.0 - Quickstart Guide

## Overview

Roche is a high-performance EVM static analysis and symbolic execution security engine written in native Zig 0.16.0 with TypeScript integrations.

## Prerequisites

- **Zig Compiler**: Version `0.16.0` (or `0.16.0-dev`)
- **Node.js**: Version `v20.0.0+` & `pnpm` / `npm`
- **Git**: Latest release

## 5-Minute Installation & First Audit

### 1. Build Roche Executable

```bash
git clone https://github.com/creatorofaurad/Roche.git
cd Roche
zig build -Doptimize=ReleaseFast
```

The compiled binary will be placed at `./zig-out/bin/roche`.

### 2. Run your First Audit

Analyze a target EVM bytecode or Solidity project:

```bash
./zig-out/bin/roche audit --target ./contracts/Vault.sol --json report.json
```

### 3. Start Local Security Dashboard

```bash
pnpm install
pnpm run dashboard:start
```

Open `http://localhost:3000` to view interactively flagged vulnerabilities and control flow graphs (CFGs).

---

## Command Line Usage Summary

| Command | Description | Example |
| :--- | :--- | :--- |
| `roche audit` | Run vulnerability analysis | `roche audit -t ./Vault.sol` |
| `roche prove` | Run Z3-backed formal verifier | `roche prove -t ./Vault.sol` |
| `roche trace` | Symbolic execution trace | `roche trace --depth 500` |
| `roche fmt` | Format detector rules | `roche fmt ./rules/` |

---

> [!TIP]
> For CI/CD setups, see [CI/CD Integration Guide](file:///C:/Users/srija/Projects/volta/docs/INTEGRATION_GUIDES/CI_CD_SETUP.md).
