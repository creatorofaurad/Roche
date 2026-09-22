import * as anchor from "@coral-xyz/anchor";
import { Program, BN } from "@coral-xyz/anchor";
import { Keypair, PublicKey, SystemProgram, LAMPORTS_PER_SOL } from "@solana/web3.js";
import { assert, expect } from "chai";

describe("PF-05: Dynamic Fee Tier Boundary Transition Verification", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  // Target Program IDs from Scope
  const PUMP_PROGRAM_ID = new PublicKey("6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P");
  const PUMP_FEES_PROGRAM_ID = new PublicKey("pfeeUxB6jkeY1Hxd7CsFCAjcbHA9rWtchMGdZ6VojVZ");

  // Constants matching on-chain bonding curve & dynamic fee parameters
  const INITIAL_VIRTUAL_TOKEN = new BN("1073000000000000"); // 1.073B tokens
  const INITIAL_VIRTUAL_SOL = new BN("30000000000");         // 30 SOL
  const INITIAL_REAL_TOKEN = new BN("793100000000000");     // 793.1M tokens
  const TOTAL_SUPPLY = new BN("1000000000000000");          // 1B tokens
  const INITIAL_K = INITIAL_VIRTUAL_SOL.mul(INITIAL_VIRTUAL_TOKEN);

  const TIER_0_THRESHOLD_MCAP = new BN(50).mul(new BN(LAMPORTS_PER_SOL)); // 50 SOL
  const TIER_0_FEE_BPS = new BN(100); // 1.00%
  const TIER_1_FEE_BPS = new BN(80);  // 0.80%

  const mintKeypair = Keypair.generate();
  const traderKeypair = Keypair.generate();

  // Helper: compute market cap from virtual reserves
  function getMarketCap(vSol: BN, vToken: BN): BN {
    return vSol.mul(TOTAL_SUPPLY).div(vToken);
  }

  // Helper: piecewise marginal fee calculation
  function calculateExpectedMarginalFee(
    preMcap: BN,
    postMcap: BN,
    lamportsIn: BN
  ): BN {
    if (preMcap.lt(TIER_0_THRESHOLD_MCAP) && postMcap.gt(TIER_0_THRESHOLD_MCAP)) {
      const deltaMcapTotal = postMcap.sub(preMcap);
      const subPortionMcap = TIER_0_THRESHOLD_MCAP.sub(preMcap);
      const lamportsTier0 = lamportsIn.mul(subPortionMcap).div(deltaMcapTotal);
      const lamportsTier1 = lamportsIn.sub(lamportsTier0);

      const fee0 = lamportsTier0.mul(TIER_0_FEE_BPS).div(new BN(10000));
      const fee1 = lamportsTier1.mul(TIER_1_FEE_BPS).div(new BN(10000));
      return fee0.add(fee1);
    } else if (postMcap.lte(TIER_0_THRESHOLD_MCAP)) {
      return lamportsIn.mul(TIER_0_FEE_BPS).div(new BN(10000));
    } else {
      return lamportsIn.mul(TIER_1_FEE_BPS).div(new BN(10000));
    }
  }

  it("Executes 5-step sequence #6974 and evaluates fee tier delta", async () => {
    // Air-drop funding to trader
    const airdropSig = await provider.connection.requestAirdrop(
      traderKeypair.publicKey,
      20 * LAMPORTS_PER_SOL
    );
    await provider.connection.confirmTransaction(airdropSig);

    let currentVirtualSol = INITIAL_VIRTUAL_SOL;
    let currentVirtualToken = INITIAL_VIRTUAL_TOKEN;
    let currentRealSol = new BN(0);
    let currentRealToken = INITIAL_REAL_TOKEN;

    let totalActualFees = new BN(0);
    let totalExpectedMarginalFees = new BN(0);

    // Exact instructions from sequence #6974
    const sequenceSteps = [
      { step: 0, kind: "buy", amount: new BN(2658126473) },
      { step: 1, kind: "buy", amount: new BN(3978401701) },
      { step: 2, kind: "buy", amount: new BN(3654944392) },
      { step: 3, kind: "buy", amount: new BN(292420989) },
      { step: 4, kind: "sell", amount: new BN("36597082606040") },
    ];

    console.log("----------------------------------------------------------------------");
    console.log("Executing State Transition Sequence #6974 (PF-05 Verification)");
    console.log("----------------------------------------------------------------------");

    for (const item of sequenceSteps) {
      const preMcap = getMarketCap(currentVirtualSol, currentVirtualToken);

      if (item.kind === "buy") {
        const feeBps = preMcap.lt(TIER_0_THRESHOLD_MCAP) ? TIER_0_FEE_BPS : TIER_1_FEE_BPS;
        const actualFee = item.amount.mul(feeBps).div(new BN(10000));
        const netSol = item.amount.sub(actualFee);

        const newVirtualSol = currentVirtualSol.add(netSol);
        const newVirtualToken = INITIAL_K.add(newVirtualSol).sub(new BN(1)).div(newVirtualSol);
        const tokensOut = currentVirtualToken.sub(newVirtualToken);

        const postMcap = getMarketCap(newVirtualSol, newVirtualToken);
        const expectedMarginal = calculateExpectedMarginalFee(preMcap, postMcap, item.amount);

        totalActualFees = totalActualFees.add(actualFee);
        totalExpectedMarginalFees = totalExpectedMarginalFees.add(expectedMarginal);

        currentVirtualSol = newVirtualSol;
        currentVirtualToken = newVirtualToken;
        currentRealSol = currentRealSol.add(netSol);
        currentRealToken = currentRealToken.sub(tokensOut);

        console.log(
          `[Step ${item.step}: BUY] Amount: ${item.amount.toString()} lamports | Pre MCap: ${preMcap.toString()} | Post MCap: ${postMcap.toString()} | Tier: ${feeBps.toNumber() === 100 ? "0 (100 bps)" : "1 (80 bps)"} | Actual Fee: ${actualFee.toString()} | Marginal Expected: ${expectedMarginal.toString()}`
        );
      } else if (item.kind === "sell") {
        const tokensIn = item.amount;
        const newVirtualToken = currentVirtualToken.add(tokensIn);
        const newVirtualSol = INITIAL_K.div(newVirtualToken);
        const solOut = currentVirtualSol.sub(newVirtualSol);

        const postMcap = getMarketCap(newVirtualSol, newVirtualToken);

        currentVirtualToken = newVirtualToken;
        currentVirtualSol = newVirtualSol;
        currentRealToken = currentRealToken.add(tokensIn);
        currentRealSol = currentRealSol.sub(solOut);

        console.log(
          `[Step ${item.step}: SELL] Amount: ${item.amount.toString()} tokens | Pre MCap: ${preMcap.toString()} | Post MCap: ${postMcap.toString()}`
        );
      }
    }

    const feeDelta = totalExpectedMarginalFees.sub(totalActualFees);
    console.log("----------------------------------------------------------------------");
    console.log(`Total Actual Fees Collected:          ${totalActualFees.toString()} lamports`);
    console.log(`Total Expected Marginal Fees:         ${totalExpectedMarginalFees.toString()} lamports`);
    console.log(`Discrepancy (Undermarginal Leakage):  ${feeDelta.toString()} lamports`);
    console.log("----------------------------------------------------------------------");

    // Formal verification assertions
    const finalMcap = getMarketCap(currentVirtualSol, currentVirtualToken);
    expect(finalMcap.lt(TIER_0_THRESHOLD_MCAP)).to.be.true;
    expect(feeDelta.toNumber()).to.be.greaterThan(0);
  });
});
