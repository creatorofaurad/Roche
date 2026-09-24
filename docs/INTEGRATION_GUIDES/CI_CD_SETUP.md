# Generic CI/CD Pipeline Integration Setup

## Core Principles for CI/CD

1. **Deterministic Exit Codes**:
   - `0`: Scan clean, no high/critical vulnerabilities.
   - `1`: High or Critical severity findings detected.
   - `2`: Internal execution error or bad CLI arguments.

2. **JSON & SARIF Output**:
   Roche generates standards-compliant SARIF reports for direct integration into GitLab CI, Bitbucket Pipelines, and Jenkins.

## GitLab CI Example (`.gitlab-ci.yml`)

```yaml
roche_security_job:
  stage: test
  image: creatorofaurad/roche:v2.0
  script:
    - roche audit --target ./contracts --json roche-findings.json
  artifacts:
    reports:
      codequality: roche-findings.json
```
