// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract VLT02_VaultPreviewRedeemDivergenceTest {
    uint256 public totalAssets = 1_000_000e18;
    uint256 public totalSupply = 1_000_000e18;

    function previewRedeem(uint256 shares) public view returns (uint256) {
        return (shares * totalAssets) / totalSupply; // Rounds down
    }

    function brokenRedeem(uint256 shares) public returns (uint256 assets) {
        // Bug: additional fee taken during execute not accounted for in preview
        assets = previewRedeem(shares);
        assets = (assets * 98) / 100; // 2% hidden fee
        totalSupply -= shares;
        totalAssets -= assets;
    }

    function validRedeem(uint256 shares) public returns (uint256 assets) {
        assets = previewRedeem(shares);
        totalSupply -= shares;
        totalAssets -= assets;
    }

    function test_VLT02_TruePositive_Divergence() public {
        uint256 preview = previewRedeem(100e18);
        uint256 actual = brokenRedeem(100e18);
        require(actual < preview, "Exploit reproduced: actual redeem < preview redeem");
    }

    function test_VLT02_TrueNegative_NoDivergence() public {
        uint256 preview = previewRedeem(100e18);
        uint256 actual = validRedeem(100e18);
        require(actual == preview, "Preview matches actual redeem amount");
    }
}
