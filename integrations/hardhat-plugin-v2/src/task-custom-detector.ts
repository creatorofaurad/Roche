import { task } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import * as fs from "fs";
import * as path from "path";
import * as readline from "readline";

function promptQuestion(query: string): Promise<string> {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) =>
    rl.question(query, (ans) => {
      rl.close();
      resolve(ans.trim());
    })
  );
}

task("detector:create", "Interactive prompt CLI to build custom Roche EVM vulnerability detectors")
  .addOptionalParam("outDir", "Output directory for the custom detector", "detectors")
  .setAction(async (taskArgs, hre: HardhatRuntimeEnvironment) => {
    console.log("=== Roche Custom Detector Builder ===");

    const detectorName = await promptQuestion("Enter Detector Name (e.g. ReentrancyGuardChecker): ");
    const detectorId = await promptQuestion("Enter Detector ID (e.g. ROCHE-CUSTOM-001): ");
    const severity = await promptQuestion("Enter Severity (CRITICAL/HIGH/MEDIUM/LOW/INFO) [HIGH]: ") || "HIGH";
    const description = await promptQuestion("Enter Description: ");

    const zigTemplate = `// Roche Custom Detector: ${detectorName} (${detectorId})
const std = @import("std");

pub const Detector = struct {
    id: []const u8 = "${detectorId}",
    name: []const u8 = "${detectorName}",
    severity: []const u8 = "${severity}",
    description: []const u8 = "${description}",

    pub fn inspectBytecode(self: *@This(), bytecode: []const u8) bool {
        _ = self;
        // Search pattern or opcode sequence invariant
        return std.mem.indexOf(u8, bytecode, "\x55\x56") != null;
    }
};
`;

    const targetDir = path.resolve(hre.config.paths.root, taskArgs.outDir);
    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
    }

    const filePath = path.join(targetDir, `${detectorName.toLowerCase()}.zig`);
    fs.writeFileSync(filePath, zigTemplate, "utf-8");

    console.log(`[Roche] Successfully generated custom detector template at: ${filePath}`);
  });
