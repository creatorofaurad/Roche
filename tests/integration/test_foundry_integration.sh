#!/usr/bin/env bash
set -euo pipefail

echo "[Test] Verifying Foundry Integration files..."

SCRIPT_PATH="integrations/foundry-integration-v2/roche-verify.sh"
CONTRACT_PATH="integrations/foundry-integration-v2/RocheChecker.sol"

if [ ! -f "$SCRIPT_PATH" ]; then
    echo "FAILED: $SCRIPT_PATH not found"
    exit 1
fi

if [ ! -f "$CONTRACT_PATH" ]; then
    echo "FAILED: $CONTRACT_PATH not found"
    exit 1
fi

echo "SUCCESS: Foundry integration files verified."
