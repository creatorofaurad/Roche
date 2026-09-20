# Roche GitHub Actions CI/CD Integration Guide

Integrate continuous bare-silicon EVM formal invariant verification into your protocol repository's GitHub Actions pipeline.

---

## 1. Minimal Workflow (`.github/workflows/roche.yml`)

Copy and paste this workflow into your project's `.github/workflows/roche.yml`:

```yaml
name: Roche Security Gate

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  roche-check:
    name: Roche Formal Verification
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Zig 0.16.0
        uses: mlugg/setup-zig@v1
        with:
          version: 0.16.0

      - name: Download Roche Pre-built Binary
        run: |
          curl -sSL https://raw.githubusercontent.com/creatorofaurad/Roche/main/install.sh | bash

      - name: Run Roche Audit on Contracts
        run: |
          roche audit --path ./contracts --fail-on high
```

---

## 2. Configuration Parameters

- `--fail-on [low|medium|high|critical]`: Set the minimum severity threshold that causes CI to exit with non-zero error.
- `--output-format [console|json|sarif]`: Output SARIF format for native integration into GitHub Code Scanning alerts.
- `--smt-timeout [ms]`: Max milliseconds allotted per invariant SMT proof branch (default: `5000`).
