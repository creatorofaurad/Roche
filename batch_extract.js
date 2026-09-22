const fs = require("fs");
const path = require("path");
const https = require("https");

const TRADE_EVENT_DISCRIMINATOR = Buffer.from([0xbd, 0xdb, 0x7f, 0xd3, 0x4e, 0xe6, 0x61, 0xee]);
const SCALE_FACTOR = 1000000000000000000n; // 1e18

const TRACES_DIR = path.resolve(process.cwd(), "traces");
const CONCURRENCY_LIMIT = 3;
const RPC_DELAY_MS = 400;
const API_URL = "https://frontend-api-v3.pump.fun/coins?offset=0&limit=50&sort=last_trade_timestamp&order=DESC&includeNsfw=false";

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function rpcCall(method, params, rpcUrl) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method,
      params,
    });

    const url = new URL(rpcUrl);
    const req = https.request(
      {
        hostname: url.hostname,
        path: url.pathname + url.search,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(postData),
        },
      },
      (res) => {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => {
          try {
            const parsed = JSON.parse(data);
            if (parsed.error) return reject(new Error(parsed.error.message));
            resolve(parsed.result);
          } catch (e) {
            reject(e);
          }
        });
      }
    );

    req.on("error", reject);
    req.write(postData);
    req.end();
  });
}

function parseTradeEvent(b64) {
  try {
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
  } catch (e) {
    return null;
  }
}

async function extractBondingCurveState(curveAddress, rpcUrl) {
  const signatures = await rpcCall("getSignaturesForAddress", [curveAddress, { limit: 25 }], rpcUrl);
  const transitions = [];
  let totalFeeExtracted = 0n;

  for (const sigInfo of signatures) {
    try {
      await sleep(100);
      let tx = null;
      try {
        tx = await rpcCall(
          "getTransaction",
          [sigInfo.signature, { encoding: "jsonParsed", maxSupportedTransactionVersion: 1 }],
          rpcUrl
        );
      } catch (parseErr) {
        // Fallback to base64 raw transaction
        tx = await rpcCall(
          "getTransaction",
          [sigInfo.signature, { encoding: "base64", maxSupportedTransactionVersion: 1 }],
          rpcUrl
        );
      }

      if (!tx || !tx.meta || tx.meta.err || !tx.meta.logMessages) continue;

      for (const log of tx.meta.logMessages) {
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
    } catch (e) {
      // Ignore individual tx fetch failure
    }
  }

  transitions.reverse();

  return {
    transitions,
    protocol_fee_pool_balance: totalFeeExtracted.toString(),
    is_migrated: false,
    migration_virtual_reserves: "0",
    migrated_target_liquidity: "0",
  };
}

function fetchTopCoins() {
  return new Promise((resolve, reject) => {
    const url = new URL(API_URL);
    https.get(
      {
        hostname: url.hostname,
        path: url.pathname + url.search,
        headers: {
          "User-Agent": "Mozilla/5.0",
        },
      },
      (res) => {
        let data = "";
        res.on("data", (c) => (data += c));
        res.on("end", () => {
          try {
            const list = JSON.parse(data);
            resolve(list.filter((c) => c && c.mint && c.bonding_curve));
          } catch (e) {
            reject(e);
          }
        });
      }
    ).on("error", reject);
  });
}

async function runBatch() {
  if (!fs.existsSync(TRACES_DIR)) {
    fs.mkdirSync(TRACES_DIR, { recursive: true });
  }

  const rpcUrl = process.argv[2] || process.env.SOLANA_RPC_URL || "https://solana-rpc.publicnode.com";
  console.log(`Starting batch trace extractor. Output: ${TRACES_DIR}, RPC: ${rpcUrl}`);

  let coins = [];
  try {
    coins = await fetchTopCoins();
    console.log(`Discovered ${coins.length} potential target bonding curves.`);
  } catch (err) {
    console.error(`Fatal error querying pump.fun API: ${err.message}`);
    process.exit(1);
  }

  let index = 0;
  const workers = Array(CONCURRENCY_LIMIT).fill(0).map(async () => {
    while (index < coins.length) {
      const currentIdx = index++;
      const coin = coins[currentIdx];
      const outputPath = path.join(TRACES_DIR, `${coin.mint}.json`);

      if (fs.existsSync(outputPath)) {
        console.log(`[${currentIdx + 1}/${coins.length}] Trace already exists: ${coin.mint}`);
        continue;
      }

      try {
        console.log(`[${currentIdx + 1}/${coins.length}] Fetching curve: ${coin.bonding_curve} (${coin.symbol})`);
        await sleep(RPC_DELAY_MS);
        const state = await extractBondingCurveState(coin.bonding_curve, rpcUrl);
        if (state.transitions.length > 0) {
          fs.writeFileSync(outputPath, JSON.stringify(state, null, 2), "utf-8");
          console.log(`[${currentIdx + 1}/${coins.length}] Saved ${state.transitions.length} transitions -> ${coin.mint}.json`);
        } else {
          console.log(`[${currentIdx + 1}/${coins.length}] No decoded trade events for ${coin.mint}`);
        }
      } catch (err) {
        console.warn(`[${currentIdx + 1}/${coins.length}] Skipped ${coin.mint}: ${err.message}`);
      }
    }
  });

  await Promise.all(workers);
  console.log("Batch extraction complete.");
}

if (require.main === module) {
  runBatch().catch(console.error);
}

module.exports = { extractBondingCurveState };
