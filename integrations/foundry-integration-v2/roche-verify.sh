#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo " Roche EVM Security Engine - Foundry Verification "
echo "=================================================="

ROCHE_BIN="${ROCHE_BIN:-roche}"
ROCHE_API="${ROCHE_API:-http://localhost:8080/api/v1/audit}"

echo "[1/2] Executing Forge Build..."
forge build --extra-output-files abi devdoc userdoc storageLayout

if [ ! -d "out" ]; then
    echo "[Error] Forge build output directory 'out' not found!"
    exit 1
fi

echo "[2/2] Running Roche Invariant Verification..."
"$ROCHE_BIN" audit --input out --api "$ROCHE_API" "$@"

echo "=================================================="
echo " Verification finished successfully.              "
echo "=================================================="
