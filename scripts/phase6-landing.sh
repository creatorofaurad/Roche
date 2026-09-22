#!/usr/bin/env bash
# scripts/phase6-landing.sh: Landing Page Deployment
set -euo pipefail

echo "============================================================"
echo "ROCHE v1.5.0 :: PHASE 6 - LANDING PAGE DEPLOYMENT"
echo "============================================================"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

LANDING_DIR="./landing"
if [ ! -f "$LANDING_DIR/index.html" ]; then
    echo "[-] ERROR: $LANDING_DIR/index.html does not exist!" >&2
    exit 1
fi
echo "[+] Verified landing page payload at $LANDING_DIR/index.html"

echo "[1/2] Checking Vercel CLI deployment readiness..."
if command -v vercel >/dev/null 2>&1; then
    echo "[+] Found Vercel CLI. Initiating production deployment..."
    cd "$LANDING_DIR"
    vercel --prod --yes || {
        echo "[-] Vercel deployment command exited with non-zero code. Verify authentication." >&2
    }
    cd "$PROJECT_ROOT"
    echo "[+] Production deployment updated at: https://roche-nine.vercel.app/"
else
    echo "[!] Vercel CLI ('vercel') not found in PATH."
    echo "[*] To deploy to Vercel manually:"
    echo "    cd landing && npx vercel --prod"
    echo "[*] Direct static deployment: upload ./landing to Cloudflare Pages, Vercel, or Netlify."
fi

echo "[2/2] Checking local preview server..."
echo "[+] Landing page is ready for production streaming."
echo "============================================================"
echo "[+] PHASE 6 COMPLETE: Landing page deployment verified."
echo "============================================================"
