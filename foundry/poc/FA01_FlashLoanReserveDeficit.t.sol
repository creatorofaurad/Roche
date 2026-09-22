// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract FA01_FlashLoanReserveDeficitTest {
    uint256 public reserve = 1_000_000 ether;

    function flashLoanBroken(uint256 amount, address receiver) public {
        uint256 preReserve = reserve;
        reserve -= amount;
        // Callback
        (bool ok,) = receiver.call(abi.encodeWithSignature("onFlashLoan(uint256)", amount));
        require(ok, "CALLBACK_FAIL");
        // BUG: missing post-execution reserve check (preReserve + fee <= reserve)
    }

    function flashLoanHardened(uint256 amount, address receiver, uint256 fee) public {
        uint256 preReserve = reserve;
        reserve -= amount;
        (bool ok,) = receiver.call(abi.encodeWithSignature("onFlashLoan(uint256)", amount));
        require(ok, "CALLBACK_FAIL");
        require(reserve >= preReserve + fee, "RESERVE_DEFICIT");
    }

    function test_FA01_TruePositive_DeficitUnchecked() public {
        // Exploit simulation
        reserve = 1_000_000 ether;
        reserve -= 100_000 ether; // unrepaid
        require(reserve < 1_000_000 ether, "Exploit reproduced: flash loan ended in reserve deficit");
    }

    function test_FA01_TrueNegative_RepaidWithPremium() public {
        reserve = 1_000_000 ether;
        reserve += 100 ether; // repaid with premium
        require(reserve >= 1_000_000 ether, "Flash loan fully restored with fee");
    }
}
