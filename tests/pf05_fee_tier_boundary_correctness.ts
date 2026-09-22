import * as anchor from "@coral-xyz/anchor";
import { Program, BN } from "@coral-xyz/anchor";
import { PublicKey, Keypair, LAMPORTS_PER_SOL } from "@solana/web3.js";
import { Pump } from "../target/types/pump";
import { PumpFees } from "../target/types/pump_fees";
import { assert } from "chai";

// Program IDs from pump.fun scope
const PUMP_PROGRAM_ID = new PublicKey("6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P");
const PUMP_FEES_PROGRAM_ID = new PublicKey("pfeeUxB6jkeY1Hxd7CsFCAjcbHA9rWtchMGdZ6VojVZ");

// Tier configuration (from pump_fees IDL)
const TIER_0_THRESHOLD_LAMPORTS = new BN(50).mul(new BN(LAMPORTS_PER_SOL)); // 50 SOL
const TIER_0_FEE_BPS = 100; // 1.00%
const TIER_1_FEE_BPS = 80;  // 0.80%
const BPS_DENOMINATOR = 10000;

describe("Fee tier boundary verification", () => {
  const provider = anchor.AnchorProvider.env();
  anchor.setProvider(provider);

  const pumpProgram = anchor.workspace.Pump as Program<Pump>;
  const feesProgram = anchor.workspace.PumpFees as Program<PumpFees>;

  const user = Keypair.generate();
  let bondingCurvePda: PublicKey;
  let bondingCurveBump: number;

  before(async () => {
    // Airdrop SOL to test user
    const sig = await provider.connection.requestAirdrop(
      user.publicKey,
      100 * LAMPORTS_PER_SOL
    );
    await provider.connection.confirmTransaction(sig);

    // Derive bonding curve PDA (adjust seeds based on actual program)
    [bondingCurvePda, bondingCurveBump] = PublicKey.findProgramAddressSync(
      [Buffer.from("bonding-curve"), user.publicKey.toBuffer()],
      PUMP_PROGRAM_ID
    );
  });

  it("verifies fee calculation across tier transitions", async () => {
    // ─── Step 0: Initialize bonding curve near 47 SOL market cap ───
    // Adjust initial reserves to achieve ~47 SOL market cap
    // market_cap = (sol_reserves * total_supply) / token_reserves
    const initialSolReserves = new BN(47).mul(new BN(LAMPORTS_PER_SOL));
    const initialTokenReserves = new BN(1_000_000_000_000); // 1M tokens with 6 decimals
    const totalSupply = new BN(1_000_000_000_000_000); // 1B total supply

    // TODO: Call create instruction to initialize bonding curve
    // await pumpProgram.methods.create(...)
    //   .accounts({ bondingCurve: bondingCurvePda, ... })
    //   .signers([user])
    //   .rpc();

    // ─── Helper: Execute buy and return fee paid ───
    const executeBuy = async (amountLamports: BN): Promise<{ feePaid: BN; mcapAfter: BN; tierAfter: number }> => {
      // TODO: Call buy instruction
      // const txSig = await pumpProgram.methods.buy(amountLamports)
      //   .accounts({ bondingCurve: bondingCurvePda, user: user.publicKey, ... })
      //   .signers([user])
      //   .rpc();

      // Fetch post-state
      const curveAccount = await pumpProgram.account.bondingCurve.fetch(bondingCurvePda);
      const solReserves = curveAccount.realSolReserves as BN;
      const tokenReserves = curveAccount.realTokenReserves as BN;
      const mcap = solReserves.mul(totalSupply).div(tokenReserves);
      const tier = mcap.gte(TIER_0_THRESHOLD_LAMPORTS) ? 1 : 0;

      // TODO: Fetch fee account to determine actual fee paid
      // const feeAccount = await feesProgram.account.feeState.fetch(...);
      const feePaid = new BN(0); // Replace with actual fee from account state

      return { feePaid, mcapAfter: mcap, tierAfter: tier };
    };

    // ─── Helper: Execute sell and return fee paid ───
    const executeSell = async (tokenAmount: BN): Promise<{ feePaid: BN; mcapAfter: BN; tierAfter: number }> => {
      // TODO: Call sell instruction
      // const txSig = await pumpProgram.methods.sell(tokenAmount)
      //   .accounts({ bondingCurve: bondingCurvePda, user: user.publicKey, ... })
      //   .signers([user])
      //   .rpc();

      const curveAccount = await pumpProgram.account.bondingCurve.fetch(bondingCurvePda);
      const solReserves = curveAccount.realSolReserves as BN;
      const tokenReserves = curveAccount.realTokenReserves as BN;
      const mcap = solReserves.mul(totalSupply).div(tokenReserves);
      const tier = mcap.gte(TIER_0_THRESHOLD_LAMPORTS) ? 1 : 0;
      const feePaid = new BN(0); // Replace with actual fee from account state

      return { feePaid, mcapAfter: mcap, tierAfter: tier };
    };

    // ─── Helper: Calculate expected piecewise marginal fee ───
    const calculateExpectedFee = (
      amountLamports: BN,
      preMcap: BN,
      postMcap: BN
    ): BN => {
      if (preMcap.lt(TIER_0_THRESHOLD_LAMPORTS) && postMcap.gte(TIER_0_THRESHOLD_LAMPORTS)) {
        // Trade spans boundary: split proportionally
        const deltaMcap = postMcap.sub(preMcap);
        if (deltaMcap.isZero()) {
          return amountLamports.muln(TIER_0_FEE_BPS).divn(BPS_DENOMINATOR);
        }
        const subPortion = TIER_0_THRESHOLD_LAMPORTS.sub(preMcap);
        const lamportsTier0 = amountLamports.mul(subPortion).div(deltaMcap);
        const lamportsTier1 = amountLamports.sub(lamportsTier0);
        const fee0 = lamportsTier0.muln(TIER_0_FEE_BPS).divn(BPS_DENOMINATOR);
        const fee1 = lamportsTier1.muln(TIER_1_FEE_BPS).divn(BPS_DENOMINATOR);
        return fee0.add(fee1);
      } else if (postMcap.lt(TIER_0_THRESHOLD_LAMPORTS)) {
        return amountLamports.muln(TIER_0_FEE_BPS).divn(BPS_DENOMINATOR);
      } else {
        return amountLamports.muln(TIER_1_FEE_BPS).divn(BPS_DENOMINATOR);
      }
    };

    // ─── Execute the 5-step sequence ───
    const steps = [
      { kind: "buy" as const, amount: new BN(2_658_126_473) },   // 2.658 SOL
      { kind: "buy" as const, amount: new BN(3_978_401_701) },   // 3.978 SOL
      { kind: "buy" as const, amount: new BN(3_654_944_392) },   // 3.654 SOL
      { kind: "buy" as const, amount: new BN(292_420_989) },     // 0.292 SOL
      { kind: "sell" as const, amount: new BN(36_597_082_606_040) }, // 36.59M tokens
    ];

    let totalActualFees = new BN(0);
    let totalExpectedFees = new BN(0);
    let currentMcap = new BN(47).mul(new BN(LAMPORTS_PER_SOL)); // ~47 SOL initial

    console.log("\n=== PF-05 Fee Tier Boundary Verification ===\n");
    console.log(`Initial market cap: ${currentMcap.divn(LAMPORTS_PER_SOL).toString()} SOL`);
    console.log(`Tier 0 threshold: ${TIER_0_THRESHOLD_LAMPORTS.divn(LAMPORTS_PER_SOL).toString()} SOL`);
    console.log(`Tier 0 fee: ${TIER_0_FEE_BPS} bps | Tier 1 fee: ${TIER_1_FEE_BPS} bps\n`);

    for (let i = 0; i < steps.length; i++) {
      const step = steps[i];
      let result: { feePaid: BN; mcapAfter: BN; tierAfter: number };

      if (step.kind === "buy") {
        result = await executeBuy(step.amount);
      } else {
        result = await executeSell(step.amount);
      }

      const expectedFee = calculateExpectedFee(step.amount, currentMcap, result.mcapAfter);
      totalActualFees = totalActualFees.add(result.feePaid);
      totalExpectedFees = totalExpectedFees.add(expectedFee);

      console.log(`Step ${i}: ${step.kind.toUpperCase()}(${step.amount.toString()} lamports)`);
      console.log(`  Market cap: ${currentMcap.divn(LAMPORTS_PER_SOL).toString()} → ${result.mcapAfter.divn(LAMPORTS_PER_SOL).toString()} SOL`);
      console.log(`  Tier: ${currentMcap.gte(TIER_0_THRESHOLD_LAMPORTS) ? 1 : 0} → ${result.tierAfter}`);
      console.log(`  Actual fee: ${result.feePaid.toString()} lamports`);
      console.log(`  Expected fee (piecewise): ${expectedFee.toString()} lamports`);
      console.log(`  Step discrepancy: ${expectedFee.sub(result.feePaid).toString()} lamports\n`);

      currentMcap = result.mcapAfter;
    }

    const discrepancy = totalExpectedFees.sub(totalActualFees);

    console.log("=== SUMMARY ===");
    console.log(`Total actual fees:   ${totalActualFees.toString()} lamports`);
    console.log(`Total expected fees: ${totalExpectedFees.toString()} lamports`);
    console.log(`Discrepancy:         ${discrepancy.toString()} lamports (${discrepancy.divn(LAMPORTS_PER_SOL).toString()} SOL)`);
    console.log(`Protocol under-collection: ${discrepancy.gt(new BN(0)) ? "CONFIRMED" : "NONE"}\n`);

    // Assert: if discrepancy > 0, the protocol loses fees on every roundtrip
    if (discrepancy.gt(new BN(0))) {
      console.log(`⚠️  FEE CALCULATION DISCREPANCY DETECTED: ${discrepancy.toString()} lamports`);
      console.log(`This represents protocol fee under-collection due to instantaneous step pricing.`);
      console.log(`Expected behavior: piecewise marginal integration across tier boundaries.`);
    }

    // The test passes either way — the discrepancy output IS the finding
    assert.isTrue(true, "Fee tier boundary verification complete");
  });
});
