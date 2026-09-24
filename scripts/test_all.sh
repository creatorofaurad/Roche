#!/usr/bin/env bash
set -euo pipefail

echo "[ROCHE] Running complete test suite..."

echo "[1/2] Running Zig unit and integration tests..."
zig build test

echo "[2/2] Running TypeScript SDK and Dashboard unit tests..."
if [ -f "package.json" ]; then
    pnpm test || npm test
fi

echo "[ROCHE] All tests passed cleanly!"
