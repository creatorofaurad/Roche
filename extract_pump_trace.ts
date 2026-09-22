// extract_pump_trace.ts
import { Connection, PublicKey, ParsedTransactionWithMeta, VersionedTransactionResponse } from "@solana/web3.js";
import * as fs from "fs";

export const PUMP_PROGRAM_ID = new PublicKey("6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P");
export const PUMP_FEES_PROGRAM_ID = new PublicKey("pfeeUxB6jkeY1Hxd7CsFCAjcbHA9rWtchMGdZ6VojVZ");

const BONDING_CURVE_DISCRIMINATOR = Buffer.from([0x17, 0xb7, 0xf8, 0x37, 0x60, 0xd8, 0xac, 0x60]);
const TRADE_EVENT_DISCRIMINATOR = Buffer.from([0xbd, 0xdb, 0x7f, 0xd3, 0x4e, 0xe6, 0x61, 0xee]);
const SCALE_FACTOR = 1000000000000000000n; // 1e18

export interface DecodedBondingCurve {
  virtualTokenReserves: bigint;
  virtualSolReserves: bigint;
  realTokenReserves: bigint;
  realSolReserves: bigint;
  tokenTotalSupply: bigint;
  complete: boolean;
}

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

export function decodeBondingCurveAccount(buffer: Buffer): DecodedBondingCurve {
  if (buffer.length < 49) {
    throw new Error(`Invalid buffer length for BondingCurve account: ${buffer.length} bytes (expected >= 49)`);
  }

  const discriminator = buffer.subarray(0, 8);
  if (!discriminator.equals(BONDING_CURVE_DISCRIMINATOR)) {
    throw new Error(`Invalid account discriminator: ${discriminator.toString("hex")}`);
  }

  let offset = 8;
  const virtualTokenReserves = buffer.readBigUInt64LE(offset);
  offset += 8;
  const virtualSolReserves = buffer.readBigUInt64LE(offset);
  offset += 8;
  const realTokenReserves = buffer.readBigUInt64LE(offset);
  offset += 8;
  const realSolReserves = buffer.readBigUInt64LE(offset);
  offset += 8;
  const tokenTotalSupply = buffer.readBigUInt64LE(offset);
  offset += 8;
  const complete = buffer.readUInt8(offset) === 1;

  return {
    virtualTokenReserves,
    virtualSolReserves,
    realTokenReserves,
    realSolReserves,
    tokenTotalSupply,
    complete,
  };
}

export function parseTradeEvent(b64: string) {
  try {
    const buf = Buffer.from(b64, "base64");
    if (buf.length < 160) return null;
    const disc = buf.subarray(0, 8);
    if (!disc.equals(TRADE_EVENT_DISCRIMINATOR)) return null;

    let o = 8 + 32; // skip disc + mint
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
      sol_amount,
      token_amount,
      virtual_sol,
      virtual_token,
      fee,
    };
  } catch {
    return null;
  }
}

async function fetchWithRetry<T>(fn: () => Promise<T>, retries = 3, delayMs = 500): Promise<T> {
  let attempt = 0;
  while (attempt < retries) {
    try {
      return await fn();
    } catch (err: any) {
      attempt++;
      if (attempt >= retries) throw err;
      const waitTime = delayMs * Math.pow(2, attempt);
      await new Promise((res) => setTimeout(res, waitTime));
    }
  }
  throw new Error("Exhausted retries");
}

export async function extractBondingCurveState(
  bondingCurveStr: string,
  rpcUrl = "https://solana-rpc.publicnode.com",
  txLimit = 25
): Promise<InvariantEngineStateJSON> {
  const connection = new Connection(rpcUrl, { commitment: "confirmed" });
  const bondingCurvePubkey = new PublicKey(bondingCurveStr);

  const accountInfo = await fetchWithRetry(() => connection.getAccountInfo(bondingCurvePubkey));
  if (!accountInfo || !accountInfo.data) {
    throw new Error(`BondingCurve account not found at ${bondingCurvePubkey.toBase58()}`);
  }

  const curveData = decodeBondingCurveAccount(accountInfo.data);

  const signatures = await fetchWithRetry(() =>
    connection.getSignaturesForAddress(bondingCurvePubkey, { limit: txLimit })
  );

  const transitions: StateTransitionJSON[] = [];
  let totalFeeExtracted = 0n;

  for (const sigInfo of signatures) {
    let logMessages: string[] | null | undefined = null;
    let err: any = null;

    try {
      const parsedTx: ParsedTransactionWithMeta | null = await fetchWithRetry(() =>
        connection.getParsedTransaction(sigInfo.signature, {
          maxSupportedTransactionVersion: 1,
          commitment: "confirmed",
        })
      );
      if (parsedTx && parsedTx.meta) {
        logMessages = parsedTx.meta.logMessages;
        err = parsedTx.meta.err;
      }
    } catch (parseError: any) {
      process.stderr.write(`[WARN] getParsedTransaction failed for ${sigInfo.signature}: ${parseError.message}. Attempting raw fallback...\n`);
    }

    if (!logMessages) {
      try {
        const rawTx: VersionedTransactionResponse | null = await fetchWithRetry(() =>
          connection.getTransaction(sigInfo.signature, {
            maxSupportedTransactionVersion: 1,
            commitment: "confirmed",
          })
        );
        if (rawTx && rawTx.meta) {
          logMessages = rawTx.meta.logMessages;
          err = rawTx.meta.err;
        }
      } catch (rawError: any) {
        process.stderr.write(`[ERROR] Raw fallback getTransaction failed for ${sigInfo.signature}: ${rawError.message}\n`);
      }
    }

    if (err || !logMessages) continue;

    for (const log of logMessages) {
      if (log.startsWith("Program data: ")) {
        const payload = log.substring("Program data: ".length).trim();
        const trade = parseTradeEvent(payload);
        if (trade) {
          const priceWad =
            trade.virtual_token > 0n
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
  }

  transitions.reverse();

  const migrationReserves = curveData.complete ? curveData.realSolReserves.toString() : "0";
  const migratedLiquidity = curveData.complete ? curveData.realSolReserves.toString() : "0";

  return {
    transitions,
    protocol_fee_pool_balance: totalFeeExtracted.toString(),
    is_migrated: curveData.complete,
    migration_virtual_reserves: migrationReserves,
    migrated_target_liquidity: migratedLiquidity,
  };
}

async function main() {
  const args = process.argv.slice(2);
  if (args.length === 0) {
    process.stderr.write("Usage: ts-node extract_pump_trace.ts <bondingCurveAddress> [rpcUrl] [outputJsonPath]\n");
    process.exit(1);
  }

  const bondingCurveAddress = args[0];
  const rpcUrl = args[1] || process.env.SOLANA_RPC_URL || "https://solana-rpc.publicnode.com";
  const outputPath = args[2];

  try {
    const state = await extractBondingCurveState(bondingCurveAddress, rpcUrl);
    const jsonOutput = JSON.stringify(state, null, 2);

    if (outputPath) {
      fs.writeFileSync(outputPath, jsonOutput);
      process.stdout.write(`Extracted trace written to ${outputPath}\n`);
    } else {
      process.stdout.write(jsonOutput + "\n");
    }
  } catch (error: any) {
    process.stderr.write(`Execution failed: ${error.message}\n`);
    process.exit(1);
  }
}

if (require.main === module) {
  main();
}