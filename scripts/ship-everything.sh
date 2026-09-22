#!/usr/bin/env bash
# scripts/ship-everything.sh: Master Roche v1.5.0 Release Pipeline Orchestrator
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "================================================================================"
echo "                   ROCHE v1.5.0 MASTER RELEASE PIPELINE                        "
echo "        Zero-Allocation EVM Invariant Engine - Pure Zig 0.16.0 Release          "
echo "================================================================================"
echo ""

echo "[1/7] Phase 1: Local Build Verification & Artifact Preparation"
bash "$SCRIPT_DIR/phase1-build.sh"
echo ""

echo "[2/7] Phase 2: Git Staging & Atomic Commit"
bash "$SCRIPT_DIR/phase2-stage.sh"
echo ""

echo "[3/7] Phase 3: Version Tagging & Remote Synchronization"
bash "$SCRIPT_DIR/phase3-tag.sh"
echo ""

echo "[4/7] Phase 4: Documentation Refresh & Validation"
bash "$SCRIPT_DIR/phase4-docs.sh"
echo ""

echo "[5/7] Phase 5: GitHub Release Publication"
bash "$SCRIPT_DIR/phase5-release.sh"
echo ""

echo "[6/7] Phase 6: Landing Page Deployment"
bash "$SCRIPT_DIR/phase6-landing.sh"
echo ""

echo "[7/7] Phase 7: Notification & Broadcast"
bash "$SCRIPT_DIR/phase7-notify.sh"
echo ""

echo "================================================================================"
echo "               [+] ROCHE v1.5.0 SUCCESSFULLY SHIPPED TO PRODUCTION!            "
echo "================================================================================"
echo ""
echo "Release URL:   https://github.com/creatorofaurad/Roche/releases/tag/v1.5.0"
echo "Landing Page:  https://roche-nine.vercel.app/"
echo "Documentation: https://github.com/creatorofaurad/Roche/tree/main/docs"
echo ""
echo "Strategic Next Steps for Charles:"
echo "1. Verify release assets on GitHub: https://github.com/creatorofaurad/Roche/releases"
echo "2. Monitor institutional email responses (Certora, Uniswap Labs, Ethereum Foundation)"
echo "3. Cantina Agglayer submission trigger: September 23, 2026 (12:03 AM)"
echo "4. Initiate Tier 2 Reth IPC streaming engineering sprint"
echo "================================================================================"
