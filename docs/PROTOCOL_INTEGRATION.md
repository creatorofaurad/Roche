# Volta Protocol Integration Guide: Continuous CI/CD Invariant Defense

This guide provides DeFi engineering teams with instructions for integrating Volta into their local development workflows and GitHub Actions CI pipelines.

---

## 1. Quick Installation

```bash
# Clone and build native binary
git clone https://github.com/creatorofaurad/volta.git
cd volta
zig build -Doptimize=ReleaseFast

# Add to system PATH
export PATH="$PATH:$(pwd)/zig-out/bin"
```

---

## 2. Running Invariant Verifications Locally

### Audit Bytecode with 22 Detectors
```bash
volta audit path/to/Contract.bin
```

### Stateful Fuzzing with AFL Coverage Maps
```bash
volta fuzz path/to/Contract.bin --runs 50000
```

### Reproduce Exploit Traces to Minimal Foundry Tests
```bash
volta repro euler
volta repro uniswap
volta repro curve
```

---

## 3. GitHub Actions CI/CD Integration

Add the following workflow to `.github/workflows/volta-gate.yml` in your protocol repository:

```yaml
name: Volta Continuous Invariant Gate

on: [push, pull_request]

jobs:
  volta-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Zig Compiler
        uses: mlugg/setup-zig@v1
        with:
          version: 0.16.0

      - name: Install Volta
        run: |
          git clone https://github.com/creatorofaurad/volta.git /tmp/volta
          cd /tmp/volta && zig build -Doptimize=ReleaseFast
          sudo cp zig-out/bin/volta /usr/local/bin/

      - name: Run Invariant Gauntlet
        run: |
          volta gauntlet
```
