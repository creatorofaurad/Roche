// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SDT04_BorrowCapacityOverflowTest {
    struct Market {
        uint128 borrowCap;
        uint128 totalBorrows;
    }

    Market public market;

    function brokenSetBorrowCap(uint256 newCap) public {
        // Unsafe downcast in Solidity / assembly without check
        market.borrowCap = uint128(newCap);
    }

    function safeSetBorrowCap(uint256 newCap) public {
        require(newCap <= type(uint128).max, "CAP_OVERFLOW");
        market.borrowCap = uint128(newCap);
    }

    function test_SDT04_TruePositive_Truncation() public {
        uint256 oversizedCap = uint256(type(uint128).max) + 500;
        brokenSetBorrowCap(oversizedCap);
        require(market.borrowCap == 499, "Exploit reproduced: borrow cap wrapped around zero");
    }

    function test_SDT04_TrueNegative_ValidCap() public {
        uint256 validCap = 1_000_000e18;
        safeSetBorrowCap(validCap);
        require(market.borrowCap == 1_000_000e18, "Valid borrow cap stored without wrapping");
    }
}
