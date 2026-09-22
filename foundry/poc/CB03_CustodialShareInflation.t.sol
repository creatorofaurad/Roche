// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract MockCbBTCWrapper {
    uint256 public totalAssets;
    uint256 public totalSupply;

    function donateTokens(uint256 amount) external {
        totalAssets += amount;
    }

    function depositBroken(uint256 assets) external returns (uint256 shares) {
        if (totalSupply == 0) {
            shares = assets;
        } else {
            shares = (assets * totalSupply) / totalAssets;
        }
        totalAssets += assets;
        totalSupply += shares;
    }

    function depositHardened(uint256 assets) external returns (uint256 shares) {
        // Virtual offset to mitigate empty-vault donation inflation
        shares = (assets * (totalSupply + 1e3)) / (totalAssets + 1);
        totalAssets += assets;
        totalSupply += shares;
    }
}

contract CB03_CustodialShareInflationTest {
    MockCbBTCWrapper wrapper;

    function setUp() public {
        wrapper = new MockCbBTCWrapper();
    }

    function test_CB03_TruePositive_FirstDepositDonationInflation() public {
        // Attacker deposits 1 wei, gets 1 share
        wrapper.depositBroken(1);
        // Attacker donates 100 BTC (100e8)
        wrapper.donateTokens(100e8);
        
        // Victim deposits 50 BTC (50e8)
        uint256 victimShares = wrapper.depositBroken(50e8);
        require(victimShares == 0, "Exploit verified: victim receives 0 shares for 50 BTC deposit");
    }

    function test_CB03_TrueNegative_VirtualOffsetProtected() public {
        MockCbBTCWrapper protectedWrapper = new MockCbBTCWrapper();
        protectedWrapper.depositHardened(1);
        protectedWrapper.donateTokens(100e8);
        uint256 victimShares = protectedWrapper.depositHardened(50e8);
        require(victimShares > 0, "Virtual offset prevents complete capital loss");
    }
}
