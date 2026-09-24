# Roche Dashboard User Guide

## Overview

The Roche Dashboard is a real-time web interface built with React & Next.js for visualizing EVM vulnerability execution traces, call graphs, and formal verification proofs.

## Features

- **Control Flow Graph (CFG) Visualizer**: Interactive rendering of basic blocks and bytecode execution branches.
- **Symbolic Stack Inspector**: Trace stack states (`s(0)`, `s(1)`, ...) at every step of execution.
- **Solidity Line Mapper**: Maps compiled EVM opcodes directly back to original Solidity source code lines.
- **Report Exporter**: Export audit reports to PDF, HTML, Markdown, or SARIF formats.

## Starting the Dashboard

```bash
pnpm install
pnpm run dev
```

Navigate to `http://localhost:3000` in your web browser.

---

## Configuration (`dashboard.config.json`)

```json
{
  "port": 3000,
  "theme": "dark",
  "rocheEngineRpc": "http://127.0.0.1:8545",
  "autoRefresh": true
}
```
