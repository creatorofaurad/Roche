# GitHub Actions Workflow for Roche EVM Engine

## Automated Security Pipeline

Add `.github/workflows/roche-security.yml` to your repository:

```yaml
name: Roche EVM Security Scan

on:
  push:
    branches: [ main, dev ]
  pull_request:
    branches: [ main ]

jobs:
  roche-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Setup Zig
        uses: mlugg/setup-zig@v1
        with:
          version: 0.16.0

      - name: Build & Run Roche Scan
        run: |
          git clone https://github.com/creatorofaurad/Roche.git roche-engine
          cd roche-engine && zig build -Doptimize=ReleaseFast && cd ..
          ./roche-engine/zig-out/bin/roche audit --target ./contracts --json report.json

      - name: Upload SARIF Security Findings
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: report.json
```
