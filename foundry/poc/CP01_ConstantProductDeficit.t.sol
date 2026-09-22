// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITest {
    function test_CP01_TruePositive_InvariantViolation() external;
    function test_CP01_TrueNegative_ValidSwap() external;
}

contract MockAMMConstantProduct {
    uint256 public reserve0;
    uint256 public reserve1;

    constructor(uint256 _r0, uint256 _r1) {
        reserve0 = _r0;
        reserve1 = _r1;
    }

    function swapBroken(uint256 amountIn, uint256 amountOut) external {
        // Exploit simulation: output is oversized, causing k_post < k_pre
        reserve0 += amountIn;
        reserve1 -= amountOut;
    }

    function swapValid(uint256 amountIn, uint256 amountOut) external {
        // Valid swap: k_post >= k_pre
        reserve0 += amountIn;
        reserve1 -= amountOut;
        require(reserve0 * reserve1 >= 1000 * 1000, "K_INVARIANT");
    }
}

contract CP01_ConstantProductDeficitTest is ITest {
    MockAMMConstantProduct pool;

    function setUp() public {
        pool = new MockAMMConstantProduct(1000, 1000);
    }

    function test_CP01_TruePositive_InvariantViolation() public {
        uint256 k_pre = pool.reserve0() * pool.reserve1();
        pool.swapBroken(100, 200); // 1100 * 800 = 880,000 < 1,000,000
        uint256 k_post = pool.reserve0() * pool.reserve1();
        require(k_post < k_pre, "Exploit reproduced: k deficit occurred");
    }

    function test_CP01_TrueNegative_ValidSwap() public {
        uint256 k_pre = pool.reserve0() * pool.reserve1();
        pool.swapValid(100, 90); // 1100 * 910 = 1,001,000 >= 1,000,000
        uint256 k_post = pool.reserve0() * pool.reserve1();
        require(k_post >= k_pre, "Valid swap maintained k growth");
    }
}
