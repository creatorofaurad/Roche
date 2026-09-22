# ROCHE Protocol Integration Guide: Continuous CI/CD Invariant Defense

This guide provides DeFi engineering teams with instructions for integrating ROCHE into their local development workflows and GitHub Actions CI pipelines.

---

## 1. Quick Installation

```bash
# Clone and build native binary
git clone https://github.com/creatorofaurad/ROCHE.git
cd ROCHE
zig build -Doptimize=ReleaseFast

# Add to system PATH
export PATH="$PATH:$(pwd)/zig-out/bin"
```

---

## 2. Running Invariant Verifications Locally

### Audit Bytecode with 22 Detectors
```bash
ROCHE audit path/to/Contract.bin
```

### Stateful Fuzzing with AFL Coverage Maps
```bash
ROCHE fuzz path/to/Contract.bin --runs 50000
```

### Reproduce Exploit Traces to Minimal Foundry Tests
```bash
ROCHE repro euler
ROCHE repro uniswap
ROCHE repro curve
```

---

## 3. GitHub Actions CI/CD Integration

Add the following workflow to `.github/workflows/ROCHE-gate.yml` in your protocol repository:

```yaml
name: ROCHE Continuous Invariant Gate

on: [push, pull_request]

jobs:
  ROCHE-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Zig Compiler
        uses: mlugg/setup-zig@v1
        with:
          version: 0.16.0

      - name: Install ROCHE
        run: |
          git clone https://github.com/creatorofaurad/ROCHE.git /tmp/ROCHE
          cd /tmp/ROCHE && zig build -Doptimize=ReleaseFast
          sudo cp zig-out/bin/ROCHE /usr/local/bin/

      - name: Run Invariant Gauntlet
        run: |
          ROCHE gauntlet
```

