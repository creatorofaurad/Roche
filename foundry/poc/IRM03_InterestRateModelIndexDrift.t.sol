// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract IRM03_InterestRateModelIndexDriftTest {
    uint256 public borrowIndex = 1e27; // Ray

    function brokenAccrueInterest(uint256 timeDelta, uint256 borrowRate) public {
        // Bug: division by 1e18 instead of ray or truncating linear factor
        uint256 linearFactor = 1e27 + (borrowRate * timeDelta) / 1e18;
        borrowIndex = (borrowIndex * linearFactor) / 1e27;
    }

    function validAccrueInterest(uint256 timeDelta, uint256 borrowRate) public {
        uint256 linearFactor = 1e27 + (borrowRate * timeDelta);
        borrowIndex = (borrowIndex * linearFactor) / 1e27;
    }

    function test_IRM03_TruePositive_IndexDrift() public {
        uint256 pre = borrowIndex;
        brokenAccrueInterest(100, 1e25);
        require(borrowIndex > pre * 2, "Exploit reproduced: index drifted violently");
    }

    function test_IRM03_TrueNegative_AccurateIndex() public {
        borrowIndex = 1e27;
        validAccrueInterest(1, 1e18);
        require(borrowIndex == 1e27 + 1e18, "Index accrual within exact rounding bounds");
    }
}
