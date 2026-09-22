#!/usr/bin/env bash
# scripts/phase4-docs.sh: Documentation Refresh & Validation
set -euo pipefail

echo "============================================================"
echo "ROCHE v1.5.0 :: PHASE 4 - DOCUMENTATION REFRESH & VALIDATION"
echo "============================================================"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "[1/4] Verifying required documentation assets..."
DOC_FILES=(
    "README.md"
    "SECURITY.md"
    "RELEASE_NOTES.md"
    "CONTRIBUTORS.md"
    "CHANGELOG.md"
    "VERSION.txt"
    "docs/ARCHITECTURE.md"
    "docs/INSTITUTIONAL.md"
    "docs/ROCHE_MASTER_KNOWLEDGE_BASE.md"
)

for file in "${DOC_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "[-] ERROR: Missing documentation asset: $file" >&2
        exit 1
    fi
    echo "[+] Verified: $file ($(wc -l < "$file") lines)"
done

echo "[2/4] Verifying documentation link integrity..."
# Check for broken internal links in README.md
grep -o "docs/[a-zA-Z0-9_.-]*\.md" README.md | while read -r link; do
    if [ ! -f "$link" ]; then
        echo "[-] WARNING: Unresolved doc link in README.md: $link" >&2
    else
        echo "[+] Valid link target: $link"
    fi
done

echo "[3/4] Staging and committing updated documentation..."
git add README.md SECURITY.md docs/ RELEASE_NOTES.md CONTRIBUTORS.md CHANGELOG.md VERSION.txt

if git diff --cached --quiet; then
    echo "[!] Documentation already fully committed."
else
    git commit -m "docs: synchronize institutional knowledge base, architecture spec, and security disclosure policies"
    echo "[+] Documentation updates committed."
    
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    git push origin "$CURRENT_BRANCH" || echo "[!] Push to origin deferred or requires auth."
fi

echo "[4/4] Documentation audit complete."
echo "============================================================"
echo "[+] PHASE 4 COMPLETE: Documentation refreshed and aligned."
echo "============================================================"
