# Roche EVM Security Engine - Foundry Integration

Integration guide for using Roche EVM Security Engine with Foundry (`forge`).

## Quickstart

1. Copy `RocheChecker.sol` into your `src/` or `test/` directory.
2. Include invariant assertions in your test or contract code:
   ```solidity
   import "./RocheChecker.sol";

   contract MyTest {
       function testInvariant() public {
           RocheChecker.assertInvariant(balance >= expected, "MIN_BALANCE_CHECK");
       }
   }
   ```
3. Run the verification script:
   ```bash
   chmod +x roche-verify.sh
   ./roche-verify.sh
   ```
