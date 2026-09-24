# Custom Detector Example Walkthrough

## Writing a Custom Reentrancy Detector in TypeScript

```typescript
import { DefineDetector, ASTNode, FindingSeverity } from '@roche/security-sdk';

export default DefineDetector({
  id: 'ROCHE-RULE-101',
  name: 'Unchecked Low-Level Call Return Value',
  severity: FindingSeverity.High,

  onCall(node: ASTNode, ctx) {
    if (node.type === 'LowLevelCall' && !ctx.isReturnValueChecked(node)) {
      ctx.report({
        node,
        message: 'Low-level call return value must be verified with require or if-check.',
      });
    }
  },
});
```
