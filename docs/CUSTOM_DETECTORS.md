# Writing Custom Security Detectors for Roche Engine

## Overview

Roche allows security researchers to build zero-allocation static analysis detectors in **Zig 0.16.0** or high-level AST pattern rules in **TypeScript**.

---

## Native Zig Detector Interface

```zig
const std = @import("std");

pub const Severity = enum {
    Informational,
    Low,
    Medium,
    High,
    Critical,
};

pub const Finding = struct {
    id: []const u8,
    title: []const u8,
    severity: Severity,
    pc: usize,
};

pub const Detector = struct {
    name: []const u8,
    id: []const u8,

    pub fn inspectOpcode(self: *const Detector, opcode: u8, pc: usize) ?Finding {
        _ = self;
        if (opcode == 0xF7) { // Hypothetical bad opcode match
            return Finding{
                .id = "ROCHE-CUSTOM-001",
                .title = "Forbidden Opcode Detected",
                .severity = .High,
                .pc = pc,
            };
        }
        return null;
    }
};
```

---

## TypeScript AST Detector Interface

```typescript
import { DefineDetector, ASTNode, FindingSeverity } from '@roche/security-sdk';

export default DefineDetector({
  id: 'CUSTOM-REENTRANCY-01',
  name: 'State Modification After External Call',
  severity: FindingSeverity.High,

  onFunctionCall(node: ASTNode, ctx) {
    if (ctx.isExternalCall(node) && ctx.hasStateMutationAfter(node)) {
      ctx.report({
        node,
        message: 'State variable updated after low-level external call',
      });
    }
  },
});
```
