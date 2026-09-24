// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

contract MockERC20 {
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract MinimalVault {
    MockERC20 public immutable asset;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    constructor(address _asset) { asset = MockERC20(_asset); }
    function totalAssets() public view returns (uint256) { return asset.balanceOf(address(this)); }

    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply;
        return supply == 0 ? assets : (assets * supply) / totalAssets();
    }

    function deposit(uint256 assets, address receiver) external returns (uint256 shares) {
        shares = convertToShares(assets);
        asset.transferFrom(msg.sender, address(this), assets);
        totalSupply += shares;
        balanceOf[receiver] += shares;
    }
}

contract VaultBoundaryConditionTest is Test {
    MockERC20 internal token;
    MinimalVault internal vault;
    address internal userA = address(0xA11CE);
    address internal userB = address(0xB0B);

    function setUp() public {
        token = new MockERC20();
        vault = new MinimalVault(address(token));
    }

    function test_ShareCalculationRoundingEdgeCase() public {
        token.mint(userA, 1000 ether);
        vm.prank(userA);
        token.transfer(address(vault), 1000 ether);

        token.mint(userB, 10 ether);
        vm.startPrank(userB);
        token.approve(address(vault), 10 ether);
        uint256 sharesMinted = vault.deposit(10 ether, userB);
        vm.stopPrank();

        emit log_named_uint("Computed shares", sharesMinted);
        assertEq(vault.balanceOf(userB), 0, "Edge case confirmed: zero shares due to rounding");
    }
}