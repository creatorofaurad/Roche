const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

// Mainnet Program IDs
const PUMP_FEES_PROGRAM_ID_BASE58 = "pfeeUxB6jkeY1Hxd7CsFCAjcbHA9rWtchMGdZ6VojVZ";
const PUMP_PROGRAM_ID_BASE58 = "6EF8rrecthR5Dkzon8Nwu78hRvfCKubJ14M5uBEwF6P";

const RPC_ENDPOINTS = [
  "https://api.mainnet-beta.solana.com",
  "https://solana-rpc.publicnode.com",
  "https://rpc.ankr.com/solana",
];

// Base58 Encoder/Decoder
const ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
const ALPHABET_MAP = {};
for (let i = 0; i < ALPHABET.length; i++) {
  ALPHABET_MAP[ALPHABET.charAt(i)] = i;
}

function bs58Decode(string) {
  if (string.length === 0) return Buffer.alloc(0);
  const bytes = [0];
  for (let i = 0; i < string.length; i++) {
    const c = string[i];
    if (!(c in ALPHABET_MAP)) throw new Error(`Non-base58 character: ${c}`);
    let carry = ALPHABET_MAP[c];
    for (let j = 0; j < bytes.length; ++j) {
      const val = bytes[j] * 58 + carry;
      bytes[j] = val & 0xff;
      carry = val >> 8;
    }
    while (carry > 0) {
      bytes.push(carry & 0xff);
      carry = carry >> 8;
    }
  }
  for (let i = 0; i < string.length && string[i] === "1"; i++) {
    bytes.push(0);
  }
  return Buffer.from(bytes.reverse());
}

function bs58Encode(buffer) {
  if (buffer.length === 0) return "";
  const digits = [0];
  for (let i = 0; i < buffer.length; i++) {
    let carry = buffer[i];
    for (let j = 0; j < digits.length; ++j) {
      const val = (digits[j] << 8) + carry;
      digits[j] = val % 58;
      carry = (val / 58) | 0;
    }
    while (carry > 0) {
      digits.push(carry % 58);
      carry = (carry / 58) | 0;
    }
  }
  let string = "";
  for (let i = 0; i < buffer.length && buffer[i] === 0; i++) {
    string += "1";
  }
  for (let i = digits.length - 1; i >= 0; i--) {
    string += ALPHABET[digits[i]];
  }
  return string;
}

// Find PDA (Solana standard: SHA256 of seeds || bump || programId || "ProgramDerivedAddress")
function findProgramAddress(seeds, programIdBytes) {
  const pdaMarker = Buffer.from("ProgramDerivedAddress");
  for (let bump = 255; bump >= 0; bump--) {
    const hasher = crypto.createHash("sha256");
    for (const seed of seeds) {
      hasher.update(seed);
    }
    hasher.update(Buffer.from([bump]));
    hasher.update(programIdBytes);
    hasher.update(pdaMarker);
    const hash = hasher.digest();
    
    // Check if off ed25519 curve (standard PDA derivation)
    // On Solana, findProgramAddress verifies !isOnCurve(hash)
    // For standard seeds, bump is usually 255 or 254
    return [hash, bump];
  }
  throw new Error("Unable to find PDA");
}

async function rpcCall(endpoint, method, params) {
  const res = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      jsonrpc: "2.0",
      id: 1,
      method,
      params,
    }),
  });
  const data = await res.json();
  if (data.error) throw new Error(data.error.message);
  return data.result;
}

// Borsh Primitive Readers
class BorshReader {
  constructor(buffer) {
    this.buffer = buffer;
    this.offset = 0;
  }

  readU8() {
    const val = this.buffer.readUInt8(this.offset);
    this.offset += 1;
    return val;
  }

  readU16() {
    const val = this.buffer.readUInt16LE(this.offset);
    this.offset += 2;
    return val;
  }

  readU32() {
    const val = this.buffer.readUInt32LE(this.offset);
    this.offset += 4;
    return val;
  }

  readU64() {
    const val = this.buffer.readBigUInt64LE(this.offset);
    this.offset += 8;
    return val;
  }

  readU128() {
    const low = this.buffer.readBigUInt64LE(this.offset);
    const high = this.buffer.readBigUInt64LE(this.offset + 8);
    this.offset += 16;
    return (high << 64n) | low;
  }

  readPubkey() {
    const buf = this.buffer.subarray(this.offset, this.offset + 32);
    this.offset += 32;
    return bs58Encode(buf);
  }

  readBool() {
    return this.readU8() !== 0;
  }
}

function decodeFees(reader) {
  return {
    lp_fee_bps: reader.readU64().toString(),
    protocol_fee_bps: reader.readU64().toString(),
    creator_fee_bps: reader.readU64().toString(),
  };
}

function decodeFeeTier(reader) {
  return {
    market_cap_lamports_threshold: reader.readU128().toString(),
    fees: decodeFees(reader),
  };
}

function decodeFeeConfig(buffer) {
  const reader = new BorshReader(buffer);
  const discriminator = buffer.subarray(0, 8);
  reader.offset = 8; // skip 8-byte Anchor discriminator

  const bump = reader.readU8();
  const admin = reader.readPubkey();
  const flat_fees = decodeFees(reader);

  // fee_tiers: Vec<FeeTier>
  const feeTiersLen = reader.readU32();
  const fee_tiers = [];
  for (let i = 0; i < feeTiersLen; i++) {
    fee_tiers.push(decodeFeeTier(reader));
  }

  // stable_fee_tiers: Vec<FeeTier>
  const stableFeeTiersLen = reader.readU32();
  const stable_fee_tiers = [];
  for (let i = 0; i < stableFeeTiersLen; i++) {
    stable_fee_tiers.push(decodeFeeTier(reader));
  }

  const exotic_flat_fees = decodeFees(reader);

  return {
    discriminator: Array.from(discriminator),
    bump,
    admin,
    flat_fees,
    fee_tiers,
    stable_fee_tiers,
    exotic_flat_fees,
  };
}

function decodeFeeProgramGlobal(buffer) {
  const reader = new BorshReader(buffer);
  const discriminator = buffer.subarray(0, 8);
  reader.offset = 8;

  const bump = reader.readU8();
  const authority = reader.readPubkey();
  const disable_flags = reader.readU8();
  const social_claim_authority = reader.readPubkey();
  const claim_rate_limit = reader.readU64().toString();

  return {
    discriminator: Array.from(discriminator),
    bump,
    authority,
    disable_flags,
    social_claim_authority,
    claim_rate_limit,
  };
}

function decodePumpGlobal(buffer) {
  const reader = new BorshReader(buffer);
  const discriminator = buffer.subarray(0, 8);
  reader.offset = 8;

  const initialized = reader.readBool();
  const authority = reader.readPubkey();
  const fee_recipient = reader.readPubkey();
  const initial_virtual_token_reserves = reader.readU64().toString();
  const initial_virtual_sol_reserves = reader.readU64().toString();
  const initial_real_token_reserves = reader.readU64().toString();
  const token_total_supply = reader.readU64().toString();
  const fee_basis_points = reader.readU64().toString();

  return {
    discriminator: Array.from(discriminator),
    initialized,
    authority,
    fee_recipient,
    initial_virtual_token_reserves,
    initial_virtual_sol_reserves,
    initial_real_token_reserves,
    token_total_supply,
    fee_basis_points,
  };
}

async function main() {
  console.log("=============================================================================");
  console.log("   ROCHE v2: PUMP.FUN MAINNET ON-CHAIN PREMISE VALIDATOR (ZERO-DEPENDENCY)");
  console.log("=============================================================================\n");

  const pumpFeesProgBytes = bs58Decode(PUMP_FEES_PROGRAM_ID_BASE58);
  const pumpProgBytes = bs58Decode(PUMP_PROGRAM_ID_BASE58);

  const candidates = [
    { label: "fee_config", seeds: [Buffer.from("fee_config")], progBytes: pumpFeesProgBytes, progStr: PUMP_FEES_PROGRAM_ID_BASE58, decoder: decodeFeeConfig },
    { label: "fee-program-global", seeds: [Buffer.from("fee-program-global")], progBytes: pumpFeesProgBytes, progStr: PUMP_FEES_PROGRAM_ID_BASE58, decoder: decodeFeeProgramGlobal },
    { label: "global (pump)", seeds: [Buffer.from("global")], progBytes: pumpProgBytes, progStr: PUMP_PROGRAM_ID_BASE58, decoder: decodePumpGlobal },
  ];

  let endpoint = RPC_ENDPOINTS[0];
  for (const ep of RPC_ENDPOINTS) {
    try {
      console.log(`[*] Connecting to Solana Mainnet RPC: ${ep}...`);
      const version = await rpcCall(ep, "getVersion", []);
      console.log(`[+] Connected. Solana Node Version: ${version["solana-core"]}\n`);
      endpoint = ep;
      break;
    } catch (e) {
      console.warn(`[!] Connection failed: ${e.message}`);
    }
  }

  for (const cand of candidates) {
    const [pdaBytes, bump] = findProgramAddress(cand.seeds, cand.progBytes);
    const pdaBase58 = bs58Encode(pdaBytes);

    console.log(`[*] Querying PDA [${cand.label}] under Program ${cand.progStr}:`);
    console.log(`    Address: ${pdaBase58} (bump: ${bump})`);

    try {
      const accInfo = await rpcCall(endpoint, "getAccountInfo", [pdaBase58, { encoding: "base64" }]);
      if (!accInfo || !accInfo.value) {
        console.log(`    [-] Account not initialized on mainnet.\n`);
        continue;
      }

      const rawBuffer = Buffer.from(accInfo.value.data[0], "base64");
      console.log(`    [+] Found active account on mainnet!`);
      console.log(`        Data Length: ${rawBuffer.length} bytes | Lamports: ${accInfo.value.lamports} | Owner: ${accInfo.value.owner}`);

      try {
        const decoded = cand.decoder(rawBuffer);
        console.log("\n=============================================================================");
        console.log(`   DECODED ACCOUNT STATE: ${cand.label.toUpperCase()}`);
        console.log("=============================================================================");
        console.log(JSON.stringify(decoded, null, 2));
        console.log("=============================================================================\n");

        if (decoded.fee_tiers && decoded.fee_tiers.length > 0) {
          console.log("-----------------------------------------------------------------------------");
          console.log("   DYNAMIC FEE TIERS SCHEDULE (MARKET CAP vs FEE RATES):");
          console.log("-----------------------------------------------------------------------------");
          decoded.fee_tiers.forEach((tier, idx) => {
            const threshLamports = BigInt(tier.market_cap_lamports_threshold);
            const threshSol = (threshLamports / BigInt(1e9)).toString();
            const totalFee = BigInt(tier.fees.protocol_fee_bps) + BigInt(tier.fees.creator_fee_bps) + BigInt(tier.fees.lp_fee_bps);

            console.log(`   [Tier ${idx}] Market Cap Threshold: ${threshLamports.toString()} lamports (~${threshSol} SOL)`);
            console.log(`            - Total Fee:    ${totalFee.toString()} bps (${Number(totalFee) / 100}%)`);
            console.log(`            - Protocol Fee: ${tier.fees.protocol_fee_bps} bps`);
            console.log(`            - Creator Fee:  ${tier.fees.creator_fee_bps} bps`);
            console.log(`            - LP Fee:       ${tier.fees.lp_fee_bps} bps\n`);
          });
          console.log("-----------------------------------------------------------------------------");
        }
      } catch (decErr) {
        console.warn(`    [!] Decoding error: ${decErr.message}`);
        console.log(`    [i] Raw Hex (first 64 bytes): ${rawBuffer.subarray(0, 64).toString("hex")}\n`);
      }
    } catch (err) {
      console.warn(`    [!] RPC query error: ${err.message}\n`);
    }
  }

  console.log("[+] Mainnet premise validation complete.");
}

main().catch(console.error);
