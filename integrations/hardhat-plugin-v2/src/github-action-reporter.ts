import * as fs from "fs";

export interface RocheFinding {
  ruleId: string;
  severity: "CRITICAL" | "HIGH" | "MEDIUM" | "LOW" | "INFO";
  file: string;
  line: number;
  message: string;
}

export function generateGitHubAnnotations(findings: RocheFinding[]): void {
  for (const finding of findings) {
    let level = "notice";
    if (finding.severity === "CRITICAL" || finding.severity === "HIGH") {
      level = "error";
    } else if (finding.severity === "MEDIUM" || finding.severity === "LOW") {
      level = "warning";
    }

    // GitHub Actions Workflow Command syntax for inline PR annotations
    console.log(`::${level} file=${finding.file},line=${finding.line},title=${finding.ruleId}::${finding.message}`);
  }
}

export function parseAndReportRocheResults(jsonReportPath: string): void {
  if (!fs.existsSync(jsonReportPath)) {
    console.error(`[Roche Reporter] Report file not found at ${jsonReportPath}`);
    return;
  }

  const raw = fs.readFileSync(jsonReportPath, "utf-8");
  try {
    const findings: RocheFinding[] = JSON.parse(raw);
    generateGitHubAnnotations(findings);
  } catch (err: any) {
    console.error("[Roche Reporter] Failed to parse JSON report:", err.message);
  }
}
