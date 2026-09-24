# Integrating Roche with Foundry (Forge)

## Native Forge Support

Roche natively parses `out/` build artifacts produced by `forge build`.

## Workflow

```bash
# Build contracts using forge
forge build

# Run Roche analysis on compiled artifacts
roche audit --foundry --target ./out
```

## Adding Roche to `foundry.toml` Scripting

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]

[profile.default.roche]
fail_threshold = "High"
```
