import * as anchor from "@coral-xyz/anchor";
import { Connection, PublicKey } from "@solana/web3.js";
import * as fs from "fs";
import * as path from "path";

// Mainnet Program IDs
const PUMP_FEES_PROGRAM_ID = new PublicKey("pfeeUxB6jkeY1Hxd7CsFCAjcbHA9rWtchMGdZ6VojVZ");
const PUMP_PROGRAM_ID = new PublicKey("6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P");

// Mainnet RPC Endpoints
const RPC_ENDPOINTS = [
  "https://api.mainnet-beta.solana.com",
  "https://solana-rpc.publicnode.com",
  "https://rpc.ankr.com/solana",
];

async function main() {
  console.log("=============================================================================");
  console.log("   ROCHE v2: PUMP_FEES MAINNET GLOBAL CONFIGURATION DECODER");
  console.log("=============================================================================\n");

  // 1. Ingest IDL
  const idlPath = path.resolve(__dirname, "pumpfun_scope/pump-public-docs/idl/pump_fees.json");
  if (!fs.existsSync(idlPath)) {
    console.error(`[-] IDL not found at ${idlPath}`);
    process.exit(1);
  }

  const idlRaw = fs.readFileSync(idlPath, "utf8");
  const idl = JSON.parse(idlRaw);
  console.log(`[+] Loaded IDL for program: ${idl.address || PUMP_FEES_PROGRAM_ID.toBase58()}`);

  // 2. Establish Connection
  let connection: Connection | null = null;
  for (const endpoint of RPC_ENDPOINTS) {
    try {
      console.log(`[*] Connecting to RPC: ${endpoint}...`);
      const conn = new Connection(endpoint, "confirmed");
      const version = await conn.getVersion();
      console.log(`[+] Connected. Solana Node Version: ${version["solana-core"]}`);
      connection = conn;
      break;
    } catch (e: any) {
      console.warn(`[!] RPC connection failed: ${e.message}`);
    }
  }

  if (!connection) {
    console.error("[-] All RPC connections failed.");
    process.exit(1);
  }

  // 3. Derive Candidate PDAs
  const candidateSeeds = [
    { label: "fee_config", seeds: [Buffer.from("fee_config")], programId: PUMP_FEES_PROGRAM_ID },
    { label: "fee-program-global", seeds: [Buffer.from("fee-program-global")], programId: PUMP_FEES_PROGRAM_ID },
    { label: "global (fees)", seeds: [Buffer.from("global")], programId: PUMP_FEES_PROGRAM_ID },
    { label: "global (pump)", seeds: [Buffer.from("global")], programId: PUMP_PROGRAM_ID },
  ];

  const coder = new anchor.BorshCoder(idl as anchor.Idl);

  console.log("\n[*] Searching and Decoding Deployed Global Accounts on Mainnet:\n");

  for (const cand of candidateSeeds) {
    const [pda, bump] = PublicKey.findProgramAddressSync(cand.seeds, cand.programId);
    console.log(`[+] Testing PDA [${cand.label}]: ${pda.toBase58()} (bump: ${bump})`);

    try {
      const accountInfo = await connection.getAccountInfo(pda);
      if (!accountInfo) {
        console.log(`    [-] Account not initialized on mainnet (null data).\n`);
        continue;
      }

      console.log(`    [+] Found active account! Data Length: ${accountInfo.data.length} bytes | Owner: ${accountInfo.owner.toBase58()}`);

      // Attempt decoding via Anchor BorshCoder
      let decoded: any = null;
      const accountTypes = ["FeeConfig", "FeeProgramGlobal", "Global", "SharingConfig"];

      for (const accName of accountTypes) {
        try {
          decoded = coder.accounts.decode(accName, accountInfo.data);
          if (decoded) {
            console.log(`    [+] Successfully decoded as struct: '${accName}'`);
            break;
          }
        } catch (_) {}
      }

      // If Anchor decode fails, attempt raw layout decoding for FeeConfig
      if (!decoded && accountInfo.data.length >= 8) {
        const disc = accountInfo.data.subarray(0, 8);
        console.log(`    [i] Account 8-byte Discriminator: [${Array.from(disc).join(", ")}]`);
      }

      if (decoded) {
        console.log("\n=============================================================================");
        console.log(`   DECODED ACCOUNT STATE (${cand.label}):`);
        console.log("=============================================================================");
        console.log(JSON.stringify(decoded, (key, value) => 
          typeof value === "bigint" ? value.toString() : 
          value && value.toBase58 ? value.toBase58() : 
          value && value.toString && (value._bn || anchor.BN.isBN(value)) ? value.toString() : value, 
          2
        ));
        console.log("=============================================================================\n");

        // Highlight Fee Tier Thresholds if present
        if (decoded.feeTiers || decoded.fee_tiers) {
          const tiers = decoded.feeTiers || decoded.fee_tiers;
          console.log("-----------------------------------------------------------------------------");
          console.log("   DYNAMIC FEE TIERS SCHEDULE (MARKET CAP vs FEE RATES):");
          console.log("-----------------------------------------------------------------------------");
          tiers.forEach((tier: any, idx: number) => {
            const threshLamports = tier.marketCapLamportsThreshold || tier.market_cap_lamports_threshold;
            const threshSol = threshLamports ? (BigInt(threshLamports.toString()) / BigInt(1e9)).toString() : "0";
            const fees = tier.fees;
            const lpFee = fees?.lpFeeBps || fees?.lp_fee_bps || "0";
            const protoFee = fees?.protocolFeeBps || fees?.protocol_fee_bps || "0";
            const creatorFee = fees?.creatorFeeBps || fees?.creator_fee_bps || "0";
            const totalFee = BigInt(lpFee.toString()) + BigInt(protoFee.toString()) + BigInt(creatorFee.toString());

            console.log(`   [Tier ${idx}] Market Cap Threshold: ${threshLamports.toString()} lamports (~${threshSol} SOL)`);
            console.log(`            - Total Fee:    ${totalFee.toString()} bps (${Number(totalFee) / 100}%)`);
            console.log(`            - Protocol Fee: ${protoFee.toString()} bps`);
            console.log(`            - Creator Fee:  ${creatorFee.toString()} bps`);
            console.log(`            - LP Fee:       ${lpFee.toString()} bps\n`);
          });
          console.log("-----------------------------------------------------------------------------");
        }
      }
    } catch (err: any) {
      console.warn(`    [!] Error querying PDA ${pda.toBase58()}: ${err.message}\n`);
    }
  }

  console.log("\n[+] Premise validation scan completed.");
}

main().catch((err) => {
  console.error("[-] Fatal error:", err);
  process.exit(1);
});
