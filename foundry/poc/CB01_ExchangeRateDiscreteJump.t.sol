// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockExchangeRateUpdater {
    uint256 public exchangeRate = 1e18; // 1.00 ETH/cbETH
    uint256 public constant MAX_RATE_CHANGE_BPS = 500; // 5% max deviation per update

    function updateRateBroken(uint256 newRate) external {
        // Bug: unconstrained exchange rate update permits discrete price manipulation jumps
        exchangeRate = newRate;
    }

    function updateRateHardened(uint256 newRate) external {
        uint256 maxUpper = (exchangeRate * (10000 + MAX_RATE_CHANGE_BPS)) / 10000;
        uint256 maxLower = (exchangeRate * (10000 - MAX_RATE_CHANGE_BPS)) / 10000;
        require(newRate <= maxUpper && newRate >= maxLower, "RATE_JUMP_EXCEEDED");
        exchangeRate = newRate;
    }
}

contract CB01_ExchangeRateDiscreteJumpTest {
    MockExchangeRateUpdater updater;

    function setUp() public {
        updater = new MockExchangeRateUpdater();
    }

    function test_CB01_TruePositive_DisasterJump() public {
        uint256 initialRate = updater.exchangeRate();
        // Attacker or rogue oracle triggers a 25% instantaneous rate jump
        updater.updateRateBroken(1.25e18);
        uint256 updatedRate = updater.exchangeRate();
        require(updatedRate > (initialRate * 105) / 100, "Exploit verified: unbounded discrete rate jump occurred");
    }

    function test_CB01_TrueNegative_ConstrainedRateChange() public {
        // Valid 0.5% rate accrual
        updater.updateRateHardened(1.005e18);
        require(updater.exchangeRate() == 1.005e18, "Rate change within bounded epoch cap");
    }
}
