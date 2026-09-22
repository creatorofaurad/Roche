// batch_extract.ts
import * as fs from "fs";
import * as path from "path";
// @ts-ignore
const { extractBondingCurveState } = require("./extract_pump_trace.ts");

interface PumpCoin {
  mint: string;
  bonding_curve: string;
  complete: boolean;
  virtual_sol_reserves?: number;
  virtual_token_reserves?: number;
}

const TRACES_DIR = path.resolve(process.cwd(), "traces");
const CONCURRENCY_LIMIT = 3;
const RPC_DELAY_MS = 400;
const API_URL =
  "https://frontend-api-v3.pump.fun/coins?offset=0&limit=50&sort=last_trade_timestamp&order=DESC&includeNsfw=false";

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

class SimpleQueue {
  private queue: (() => Promise<void>)[] = [];
  private activeCount = 0;

  constructor(private concurrency: number) {}

  add(task: () => Promise<void>): void {
    this.queue.push(task);
    this.next();
  }

  private next(): void {
    while (this.activeCount < this.concurrency && this.queue.length > 0) {
      const task = this.queue.shift();
      if (!task) break;

      this.activeCount++;
      task().finally(() => {
        this.activeCount--;
        this.next();
      });
    }
  }

  async onIdle(): Promise<void> {
    while (this.activeCount > 0 || this.queue.length > 0) {
      await sleep(100);
    }
  }
}

async function fetchTopCoins(): Promise<PumpCoin[]> {
  const response = await fetch(API_URL, {
    headers: {
      "User-Agent":
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
    },
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch pump.fun coins: ${response.status} ${response.statusText}`);
  }

  const data = (await response.json()) as PumpCoin[];
  return data.filter((c) => c && c.mint && c.bonding_curve);
}

async function processCurve(
  coin: PumpCoin,
  rpcUrl: string,
  index: number,
  total: number
): Promise<void> {
  const outputPath = path.join(TRACES_DIR, `${coin.mint}.json`);

  if (fs.existsSync(outputPath)) {
    process.stdout.write(`[${index}/${total}] Skipping existing trace: ${coin.mint}\n`);
    return;
  }

  try {
    process.stdout.write(`[${index}/${total}] Fetching curve: ${coin.bonding_curve} (${coin.mint})\n`);
    await sleep(RPC_DELAY_MS);

    const state = await extractBondingCurveState(coin.bonding_curve, rpcUrl);
    if (state.transitions && state.transitions.length > 0) {
      fs.writeFileSync(outputPath, JSON.stringify(state, null, 2), "utf-8");
      process.stdout.write(`[${index}/${total}] Saved ${state.transitions.length} transitions: ${outputPath}\n`);
    } else {
      process.stdout.write(`[${index}/${total}] No decoded trade events for ${coin.mint}\n`);
    }
  } catch (err: any) {
    process.stderr.write(`[${index}/${total}] Failed curve ${coin.bonding_curve} (${coin.mint}): ${err.message}\n`);
  }
}

async function runBatch(): Promise<void> {
  if (!fs.existsSync(TRACES_DIR)) {
    fs.mkdirSync(TRACES_DIR, { recursive: true });
  }

  const rpcUrl = process.argv[2] || process.env.SOLANA_RPC_URL || "https://solana-rpc.publicnode.com";
  process.stdout.write(`Starting batch trace extractor. Concurrency: ${CONCURRENCY_LIMIT}, RPC: ${rpcUrl}\n`);

  let coins: PumpCoin[] = [];
  try {
    coins = await fetchTopCoins();
    process.stdout.write(`Discovered ${coins.length} target bonding curves.\n`);
  } catch (err: any) {
    process.stderr.write(`Fatal error querying pump.fun API: ${err.message}\n`);
    process.exit(1);
  }

  const queue = new SimpleQueue(CONCURRENCY_LIMIT);

  coins.forEach((coin, idx) => {
    queue.add(() => processCurve(coin, rpcUrl, idx + 1, coins.length));
  });

  await queue.onIdle();
  process.stdout.write("Batch extraction completed successfully.\n");
}

if (require.main === module) {
  runBatch().catch((err) => {
    process.stderr.write(`Unhandled runtime rejection: ${err.message}\n`);
    process.exit(1);
  });
}
