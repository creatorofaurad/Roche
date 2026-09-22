// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SW03_StableSwapVirtualPriceTest {
    uint256 public virtualPrice = 1e18;

    function brokenRemoveLiquidityImbalance(uint256 feeDeduction) public {
        // Bug: virtual price decreases without an explicit loss/burn event
        virtualPrice -= feeDeduction;
    }

    function validRemoveLiquidityImbalance(uint256 feeDeduction) public {
        // Correct: fee accrues to pool, virtual price stays monotonic >=
        virtualPrice += (feeDeduction / 2);
    }

    function test_SW03_TruePositive_VirtualPriceDrop() public {
        uint256 pre = virtualPrice;
        brokenRemoveLiquidityImbalance(1e16);
        require(virtualPrice < pre, "Exploit reproduced: virtual price decreased");
    }

    function test_SW03_TrueNegative_MonotonicVirtualPrice() public {
        uint256 pre = virtualPrice;
        validRemoveLiquidityImbalance(1e16);
        require(virtualPrice >= pre, "Virtual price monotonicity preserved");
    }
}
