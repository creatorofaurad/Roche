# @creatorofaurad/hardhat-roche

Official Hardhat plugin for **Roche** bare-silicon EVM formal invariant verification and static security analysis.

---

## Installation

```bash
npm install --save-dev @creatorofaurad/hardhat-roche
# or
yarn add -D @creatorofaurad/hardhat-roche
# or
pnpm add -D @creatorofaurad/hardhat-roche
```

---

## Setup

Add the plugin to your `hardhat.config.ts`:

```typescript
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@creatorofaurad/hardhat-roche";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
};

export default config;
```

---

## Usage

```bash
# Run formal invariant audit on all compiled contracts
npx hardhat roche:audit

# Export audit findings to JSON
npx hardhat roche:audit --out reports/roche-audit.json
```

---

## License

MIT © [Charles](mailto:srijaan@proton.me)
