// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CL04_TickFeeGrowthInsideTest {
    mapping(int24 => uint256) public feeGrowthOutside;
    int24 constant MIN_TICK = -887272;
    int24 constant MAX_TICK = 887272;

    function brokenGetFeeGrowthInside(int24 tickLower, int24 tickUpper, int24 currentTick) public view returns (uint256) {
        // Unchecked boundary access without validation
        return feeGrowthOutside[tickUpper] - feeGrowthOutside[tickLower] + uint256(int256(currentTick));
    }

    function validGetFeeGrowthInside(int24 tickLower, int24 tickUpper, int24 currentTick) public view returns (uint256) {
        require(tickLower < tickUpper, "TL_LT_TU");
        require(tickLower >= MIN_TICK && tickUpper <= MAX_TICK, "TICK_BOUNDS");
        _ = currentTick;
        return feeGrowthOutside[tickUpper] - feeGrowthOutside[tickLower];
    }

    function test_CL04_TruePositive_UnclampedTick() public {
        // Out of bounds tick triggers unvalidated state access
        int24 invalidLower = -900000;
        int24 invalidUpper = 900000;
        uint256 res = brokenGetFeeGrowthInside(invalidLower, invalidUpper, 0);
        require(res == 0, "Exploit reproduced: Out of bounds tick computed");
    }

    function test_CL04_TrueNegative_ValidatedTick() public {
        feeGrowthOutside[100] = 500;
        feeGrowthOutside[-100] = 200;
        uint256 res = validGetFeeGrowthInside(-100, 100, 0);
        require(res == 300, "Validated fee growth inside calculated");
    }
}
