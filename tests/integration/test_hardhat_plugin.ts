import * as fs from "fs";
import * as path from "path";

console.log("[Test] Testing Hardhat plugin tasks and integration files...");

const tasksFile = path.resolve(__dirname, "../../integrations/hardhat-plugin-v2/src/task-verify-invariants.ts");
const detectorFile = path.resolve(__dirname, "../../integrations/hardhat-plugin-v2/src/task-custom-detector.ts");
const reporterFile = path.resolve(__dirname, "../../integrations/hardhat-plugin-v2/src/github-action-reporter.ts");

if (!fs.existsSync(tasksFile)) {
  console.error("FAILED: task-verify-invariants.ts does not exist.");
  process.exit(1);
}

if (!fs.existsSync(detectorFile)) {
  console.error("FAILED: task-custom-detector.ts does not exist.");
  process.exit(1);
}

if (!fs.existsSync(reporterFile)) {
  console.error("FAILED: github-action-reporter.ts does not exist.");
  process.exit(1);
}

console.log("SUCCESS: All Hardhat plugin v2 integration files verified.");
