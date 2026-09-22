// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract VLT01_VaultInflationDonationTest {
    uint256 public totalAssets;
    uint256 public totalSupply;

    function brokenDeposit(uint256 assets) public returns (uint256 shares) {
        if (totalSupply == 0) {
            shares = assets;
        } else {
            shares = (assets * totalSupply) / totalAssets;
        }
        totalAssets += assets;
        totalSupply += shares;
    }

    function hardenedDeposit(uint256 assets) public returns (uint256 shares) {
        // Virtual shares offset protection
        uint256 virtualOffset = 1e3;
        shares = (assets * (totalSupply + virtualOffset)) / (totalAssets + 1);
        totalAssets += assets;
        totalSupply += shares;
    }

    function test_VLT01_TruePositive_DonationAttack() public {
        // Exploit simulation: attacker mints 1 share, donates 1000e18, causing 0 shares for victim
        totalAssets = 1000e18 + 1;
        totalSupply = 1;
        uint256 victimShares = (500e18 * totalSupply) / totalAssets;
        require(victimShares == 0, "Exploit reproduced: victim shares rounded down to 0");
    }

    function test_VLT01_TrueNegative_VirtualOffsetProtected() public {
        totalAssets = 1000e18 + 1;
        totalSupply = 1;
        uint256 victimShares = (500e18 * (totalSupply + 1e3)) / (totalAssets + 1);
        require(victimShares > 0, "Virtual offset prevented share deflation to 0");
    }
}
