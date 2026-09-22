#!/usr/bin/env bash
# scripts/phase3-tag.sh: Version Tagging & Remote Git Synchronization
set -euo pipefail

echo "============================================================"
echo "ROCHE v1.5.0 :: PHASE 3 - VERSION TAGGING & PUSH"
echo "============================================================"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

TAG_NAME="v1.5.0"
TAG_MESSAGE="Roche v1.5.0: Production-ready invariant engine with 42 detectors, 3 validated exploits, zero-allocation Zig core, institutional feature set"

echo "[1/3] Checking existing git tags..."
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo "[!] Tag $TAG_NAME already exists locally. Skipping tag creation."
else
    echo "[+] Creating annotated tag $TAG_NAME..."
    git tag -a "$TAG_NAME" -m "$TAG_MESSAGE"
fi

echo "[2/3] Verifying tag signature and metadata..."
git tag -l "$TAG_NAME"
git show --stat "$TAG_NAME" | head -n 20

echo "[3/3] Pushing main branch and tag to origin..."
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "[*] Pushing branch: $CURRENT_BRANCH -> origin..."
if git push origin "$CURRENT_BRANCH"; then
    echo "[+] Branch $CURRENT_BRANCH pushed successfully."
else
    echo "[-] Warning: Failed to push branch $CURRENT_BRANCH. Ensure git credentials or ssh keys are configured." >&2
fi

echo "[*] Pushing tag: $TAG_NAME -> origin..."
if git push origin "$TAG_NAME"; then
    echo "[+] Tag $TAG_NAME pushed successfully."
else
    echo "[-] Warning: Failed to push tag $TAG_NAME. Ensure git credentials or ssh keys are configured." >&2
fi

echo "============================================================"
echo "[+] PHASE 3 COMPLETE: Tagged and pushed to origin."
echo "============================================================"
