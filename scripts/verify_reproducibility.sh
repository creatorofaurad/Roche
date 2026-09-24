#!/usr/bin/env bash
set -euo pipefail

echo "[ROCHE] Verifying build reproducibility across compilation passes..."

mkdir -p build_a build_b

echo "Performing compilation Pass A..."
zig build -Doptimize=ReleaseFast --prefix build_a/out

echo "Performing compilation Pass B..."
zig build -Doptimize=ReleaseFast --prefix build_b/out

echo "Comparing binary hashes..."
HASH_A=$(sha256sum build_a/out/bin/roche | awk '{print $1}')
HASH_B=$(sha256sum build_b/out/bin/roche | awk '{print $1}')

rm -rf build_a build_b

if [ "$HASH_A" = "$HASH_B" ]; then
    echo "[SUCCESS] Reproducible build verified! Binary Hash: $HASH_A"
    exit 0
else
    echo "[ERROR] Mismatch in reproducible build hashes!"
    echo "Hash A: $HASH_A"
    echo "Hash B: $HASH_B"
    exit 1
fi
