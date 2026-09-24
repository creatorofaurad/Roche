import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { execSync } from "child_process";
import * as fs from "fs";
import * as path from "path";

task("verify-invariants", "Compiles Solidity contracts and verifies invariants using Roche EVM Security Engine")
  .addOptionalParam("rocheBin", "Path to Roche executable binary", "roche")
  .addOptionalParam("apiUrl", "Roche Security Engine API endpoint URL", "http://localhost:8080/api/v1/audit")
  .addFlag("json", "Output results as JSON format")
  .setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
    console.log("[Roche] Compiling Solidity contracts...");
    await hre.run("compile");

    const artifactsPath = hre.config.paths.artifacts;
    const buildInfoPath = path.join(artifactsPath, "build-info");

    if (!fs.existsSync(buildInfoPath)) {
      console.error("[Roche Error] No build-info directory found. Compilation failed or produced no output.");
      process.exit(1);
    }

    const buildFiles = fs.readdirSync(buildInfoPath).filter(f => f.endsWith(".json"));
    if (buildFiles.length === 0) {
      console.error("[Roche Error] No compilation output JSON files found in build-info.");
      process.exit(1);
    }

    console.log(`[Roche] Found ${buildFiles.length} build-info standard JSON file(s). Preparing invariant analysis...`);

    let violationsFound = 0;
    for (const file of buildFiles) {
      const fullPath = path.join(buildInfoPath, file);
      console.log(`[Roche] Analyzing artifact: ${file}`);
      
      try {
        const cmd = `${taskArgs.rocheBin} audit --input "${fullPath}" --api "${taskArgs.apiUrl}" ${taskArgs.json ? "--json" : ""}`;
        const output = execSync(cmd, { encoding: "utf-8" });
        console.log(output);
      } catch (err: any) {
        violationsFound++;
        console.error(`[Roche Violation] Invariant verification failure for ${file}:`);
        if (err.stdout) console.log(err.stdout);
        if (err.stderr) console.error(err.stderr);
      }
    }

    if (violationsFound > 0) {
      console.error(`[Roche Summary] Verification completed with ${violationsFound} invariant violation(s).`);
      process.exit(1);
    } else {
      console.log("[Roche Summary] All invariants successfully verified clean.");
    }
  });
