#!/usr/bin/env bash
set -euo pipefail

echo "[ROCHE] Building Roche EVM Security Engine v2.0 (Zig 0.16.0)..."

# Ensure Zig binary is available
if ! command -v zig &> /dev/null; then
    echo "[ERROR] Zig 0.16.0 compiler not found in PATH."
    exit 1
fi

echo "[ROCHE] Compiling native ReleaseFast binary..."
zig build -Doptimize=ReleaseFast

echo "[ROCHE] Build succeeded! Executable located at ./zig-out/bin/roche"
