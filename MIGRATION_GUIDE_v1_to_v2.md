# Migration Guide: Upgrading from Roche v1.x to v2.0

## Breaking Changes Summary

1. **CLI Flag Format**:
   - `roche --file <path>` is deprecated. Use `roche audit --target <path>`.
2. **Configuration File Schema**:
   - `roche.config.yaml` has been replaced by `roche.config.json`.
3. **Detector API**:
   - Custom detectors written for v1 JavaScript runtime must be updated to `@roche/security-sdk` v2 API.

## Code Migration Example

### CLI Migration

```bash
# Roche v1.x
roche --file ./contracts/Vault.sol --scan-all

# Roche v2.0
roche audit --target ./contracts/Vault.sol --detectors all
```

### Config File Migration (`roche.config.json`)

```json
{
  "$schema": "https://roche.security/schema/v2.json",
  "engine": {
    "maxDepth": 1000,
    "timeout": 30000
  },
  "detectors": [
    "reentrancy",
    "uninitialized-storage"
  ]
}
```
