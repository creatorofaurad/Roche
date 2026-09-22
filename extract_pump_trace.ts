import { Connection, PublicKey } from "@solana/web3.js";
import * as fs from "fs";

const TRADE_EVENT_DISCRIMINATOR = Buffer.from([0xbd, 0xdb, 0x7f, 0xd3, 0x4e, 0xe6, 0x61, 0xee]);
const SCALE_FACTOR = 1000000000000000000n; // 1e18

export interface StateTransitionJSON {
  transition_type: number; // 0=Buy, 1=Sell, 2=Migration
  virtual_sol_reserves: string;
  virtual_token_reserves: string;
  marginal_fee: string;
  price_wad: string;
}

export interface InvariantEngineStateJSON {
  transitions: StateTransitionJSON[];
  protocol_fee_pool_balance: string;
  is_migrated: boolean;
  migration_virtual_reserves: string;
  migrated_target_liquidity: string;
}

function parseTradeEvent(b64: string) {
  const buf = Buffer.from(b64, "base64");
  if (buf.length < 160) return null;
  const disc = buf.subarray(0, 8);
  if (!disc.equals(TRADE_EVENT_DISCRIMINATOR)) return null;

  let o = 8;
  o += 32; // mint
  const sol_amount = buf.readBigUInt64LE(o); o += 8;
  const token_amount = buf.readBigUInt64LE(o); o += 8;
  const is_buy = buf.readUInt8(o) === 1; o += 1;
  o += 32; // user
  const timestamp = buf.readBigInt64LE(o); o += 8;
  const virtual_sol = buf.readBigUInt64LE(o); o += 8;
  const virtual_token = buf.readBigUInt64LE(o); o += 8;
  const real_sol = buf.readBigUInt64LE(o); o += 8;
  const real_token = buf.readBigUInt64LE(o); o += 8;
  o += 32; // fee_recipient
  const fee_basis_points = buf.readBigUInt64LE(o); o += 8;
  const fee = buf.readBigUInt64LE(o); o += 8;

  return {
    is_buy,
    virtual_sol,
    virtual_token,
    fee,
  };
}

async function extract() {
  const curveAddress = process.argv[2] || "8HVKpHVwhrUmVJr2ZS7hsFz87oGZc7E7b3xNDsdapfh1";
  const rpcUrl = process.argv[3] || "https://api.mainnet-beta.solana.com";
  const outputPath = process.argv[4] || "pump_trace.json";

  const conn = new Connection(rpcUrl, "confirmed");
  const pubkey = new PublicKey(curveAddress);

  console.log(`Extracting live mainnet trace for curve: ${pubkey.toBase58()}`);

  const signatures = await conn.getSignaturesForAddress(pubkey, { limit: 20 });
  console.log(`Fetched ${signatures.length} recent signatures.`);

  const transitions: StateTransitionJSON[] = [];
  let totalFeeExtracted = 0n;

  for (const sigInfo of signatures) {
    try {
      const tx = await conn.getTransaction(sigInfo.signature, {
        maxSupportedTransactionVersion: 0,
        commitment: "confirmed",
      });
      if (!tx || !tx.meta || !tx.meta.logMessages) continue;

      for (const log of tx.meta.logMessages) {
        if (log.startsWith("Program data: ")) {
          const payload = log.substring("Program data: ".length).trim();
          const trade = parseTradeEvent(payload);
          if (trade) {
            const priceWad = trade.virtual_token > 0n 
              ? (trade.virtual_sol * SCALE_FACTOR) / trade.virtual_token 
              : 0n;

            transitions.push({
              transition_type: trade.is_buy ? 0 : 1,
              virtual_sol_reserves: trade.virtual_sol.toString(),
              virtual_token_reserves: trade.virtual_token.toString(),
              marginal_fee: trade.fee.toString(),
              price_wad: priceWad.toString(),
            });
            totalFeeExtracted += trade.fee;
          }
        }
      }
    } catch (e: any) {
      console.warn(`Skip sig ${sigInfo.signature}: ${e.message}`);
    }
  }

  // Reverse to make chronological
  transitions.reverse();

  const output: InvariantEngineStateJSON = {
    transitions,
    protocol_fee_pool_balance: totalFeeExtracted.toString(),
    is_migrated: false,
    migration_virtual_reserves: "0",
    migrated_target_liquidity: "0",
  };

  fs.writeFileSync(outputPath, JSON.stringify(output, null, 2));
  console.log(`Extracted ${transitions.length} live transitions saved to ${outputPath}`);
}

extract().catch(console.error);
