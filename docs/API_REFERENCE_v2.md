# Roche EVM Security Engine v2.0 - API Reference

## Core Engine Architecture (Zig 0.16.0 API)

Roche core provides C-ABI and native Zig APIs for EVM disassembly, symbolic execution, and static detector execution.

### Struct `roche.Engine`

```zig
const std = @import("std");

pub const Engine = struct {
    allocator: std.mem.Allocator,
    max_depth: usize,
    timeout_ms: u64,

    pub fn init(allocator: std.mem.Allocator) Engine {
        return .{
            .allocator = allocator,
            .max_depth = 1000,
            .timeout_ms = 5000,
        };
    }

    pub fn analyzeBytecode(self: *Engine, code: []const u8) !AnalysisReport {
        // Zero dynamic allocation state machine evaluation
        _ = self;
        _ = code;
        return AnalysisReport{};
    }
};
```

---

## TypeScript SDK (`@roche/security-sdk`)

### `class RocheClient`

```typescript
import { RocheClient, AuditConfig, Report } from '@roche/security-sdk';

const client = new RocheClient({
  enginePath: './bin/roche',
  workers: 4,
});

const report: Report = await client.analyzeContract({
  sourcePath: './contracts/Vault.sol',
  solcVersion: '0.8.24',
  detectors: ['reentrancy', 'flashloan-attack', 'uninitialized-storage'],
});

console.log(`Found ${report.vulnerabilities.length} vulnerabilities.`);
```

---

## CLI Flags Reference

| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `--target, -t` | `string` | **Required** | Path to file or directory |
| `--detectors, -d` | `string[]` | `all` | Comma-separated list of detectors |
| `--timeout` | `integer` | `30` | Timeout per contract in seconds |
| `--json` | `string` | `stdout` | Export findings as JSON format |
| `--z3-prove` | `boolean` | `false` | Enable Z3 formal proof verification |
