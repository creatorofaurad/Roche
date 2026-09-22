const fs = require("fs");
const https = require("https");

const TRADE_EVENT_DISCRIMINATOR = Buffer.from([0xbd, 0xdb, 0x7f, 0xd3, 0x4e, 0xe6, 0x61, 0xee]);
const SCALE_FACTOR = 1000000000000000000n; // 1e18

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

async function extract() {
  const curveAddress = process.argv[2] || "8HVKpHVwhrUmVJr2ZS7hsFz87oGZc7E7b3xNDsdapfh1";
  const rpcUrl = process.argv[3] || "https://api.mainnet-beta.solana.com";
  const outputPath = process.argv[4] || "pump_trace.json";

  console.log(`Extracting live mainnet trace for curve: ${curveAddress}`);

  const signatures = await rpcCall("getSignaturesForAddress", [curveAddress, { limit: 20 }], rpcUrl);
  console.log(`Fetched ${signatures.length} recent signatures from Solana RPC.`);

  const transitions = [];
  let totalFeeExtracted = 0n;

  for (const sigInfo of signatures) {
    try {
      const tx = await rpcCall(
        "getTransaction",
        [sigInfo.signature, { encoding: "jsonParsed", maxSupportedTransactionVersion: 0 }],
        rpcUrl
      );
      if (!tx || !tx.meta || !tx.meta.logMessages) continue;

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
      console.warn(`Skip sig ${sigInfo.signature}: ${e.message}`);
    }
  }

  // Reverse to make chronological
  transitions.reverse();

  const output = {
    transitions,
    protocol_fee_pool_balance: totalFeeExtracted.toString(),
    is_migrated: false,
    migration_virtual_reserves: "0",
    migrated_target_liquidity: "0",
  };

  fs.writeFileSync(outputPath, JSON.stringify(output, null, 2));
  console.log(`Successfully extracted ${transitions.length} live transitions into ${outputPath}`);
}

extract().catch((err) => {
  console.error("Extraction error:", err);
  process.exit(1);
});
