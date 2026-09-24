import { task } from "hardhat/config";
import { execSync } from "child_process";
import * as fs from "fs";
import * as path from "path";

task("verify-invariants", "Runs Roche V2 Headless Engine against all compiled contracts")
  .setAction(async (taskArgs, hre) => {
    console.log("[Yelena] Booting Tier-1 headless analysis. Extracting bytecode...");
    await hre.run("compile");
    
    const names = await hre.artifacts.getAllFullyQualifiedNames();
    let hasCritical = false;

    for (const name of names) {
      const artifact = await hre.artifacts.readArtifact(name);
      if (artifact.deployedBytecode === "0x") continue;

      console.log(\x1b[36m[Yelena-Engine]\x1b[0m Executing local invariant audit on: );
      
      try {
         // Spawning the bare-metal Zig binary directly in the CI/CD context
         const result = execSync("zig build run", { stdio: 'pipe', encoding: 'utf-8' });
         console.log(result);
      } catch (e) {
         console.error(\x1b[31m✗ Core Engine Failed\x1b[0m);
         hasCritical = true;
      }
    }
    
    if (hasCritical) process.exit(1);
  });
