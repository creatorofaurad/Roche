# Integrating Roche with Hardhat

## Plugin Setup

Install the Hardhat Roche Security Engine plugin:

```bash
npm install --save-dev @roche/hardhat-plugin
```

## Configuration (`hardhat.config.js`)

```javascript
require("@roche/hardhat-plugin");

module.exports = {
  solidity: "0.8.24",
  roche: {
    detectors: ["reentrancy", "uninitialized-storage", "integer-overflow"],
    failOnHighSeverity: true,
    outDir: "./roche-reports",
  }
};
```

## Running Security Tasks

```bash
npx hardhat roche:audit
```
