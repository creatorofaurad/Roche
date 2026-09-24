#!/usr/bin/env bash
set -euo pipefail

echo "[ROCHE] Generating API documentation and Markdown indexes..."

if command -v typedoc &> /dev/null; then
    echo "Building TypeDoc API reference..."
    typedoc --out docs/ts-api src/index.ts
fi

echo "[ROCHE] Documentation bundle generation complete."
