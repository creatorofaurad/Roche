# Roche Hardhat Integration Guide

This guide details how to install and configure the official `@roche/hardhat` plugin for automated contract audits and invariant verification within Hardhat development pipelines.

---

## 1. Installation

Install the package in your Hardhat project:

```bash
npm install --save-dev hardhat-roche
# or
yarn add -D hardhat-roche
# or
pnpm add -D hardhat-roche
```

---

## 2. Configuration

Import the plugin in your `hardhat.config.ts` or `hardhat.config.js`:

```typescript
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-roche";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
};

export default config;
```

---

## 3. Usage

Run Roche audit across all compiled project artifacts:

```bash
# Run Roche audit
npx hardhat roche:audit

# Export audit findings to custom JSON file
npx hardhat roche:audit --out reports/audit-results.json
```

---

## 4. Output

The plugin generates a structured JSON output reporting vulnerable contracts, triggered detector flags, gas usage metrics, and causal trace steps.
