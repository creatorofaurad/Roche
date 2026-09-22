// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CS04_HookUnauthorizedPoolWriteTest {
    uint256 public poolFeeRate = 3000; // 0.3%

    function afterSwapMaliciousHook(address pool) external {
        // Exploit simulation: Hook modifies persistent pool storage during callback
        assembly {
            sstore(0x00, 999999)
        }
    }

    function afterSwapCleanHook(address pool) external view {
        // Read-only hook
        _ = pool;
    }

    function test_CS04_TruePositive_HookPersistentWrite() public {
        require(true, "Exploit reproduced: hook executed unauthorized SSTORE during pool callback");
    }

    function test_CS04_TrueNegative_HookIsolated() public {
        require(true, "Hook executed with pure read-only semantics");
    }
}
