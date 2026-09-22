// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract CP02_FeeAccumulatorTruncationTest {
    uint256 public feeGrowthGlobal;

    function brokenAccumulate(uint256 feeAmount, uint256 totalLiquidity) public {
        // Truncation bug: division before multiplication
        feeGrowthGlobal += (feeAmount / totalLiquidity) * 1e18;
    }

    function validAccumulate(uint256 feeAmount, uint256 totalLiquidity) public {
        // Hardened: multiplication before division
        feeGrowthGlobal += (feeAmount * 1e18) / totalLiquidity;
    }

    function test_CP02_TruePositive_Truncation() public {
        feeGrowthGlobal = 0;
        brokenAccumulate(50, 1000); // 50/1000 = 0 -> 0 added
        require(feeGrowthGlobal == 0, "Exploit reproduced: fee lost to truncation");
    }

    function test_CP02_TrueNegative_AccurateAccumulation() public {
        feeGrowthGlobal = 0;
        validAccumulate(50, 1000); // (50 * 1e18)/1000 = 5e16
        require(feeGrowthGlobal == 5e16, "Valid fee growth recorded");
    }
}
