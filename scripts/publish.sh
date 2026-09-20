#!/usr/bin/env bash
# Roche Registry Publishing Script
# Publishes @creatorofaurad/hardhat-roche to npm and roche-rs to crates.io

set -euo pipefail

echo "=== ROCHE PACKAGE PUBLISHER ==="

# 1. Publish Hardhat Plugin to npm
echo "[+] Publishing @creatorofaurad/hardhat-roche to npm..."
cd crates/roche-hardhat
npm publish --access public
cd ../..

# 2. Publish Rust FFI to crates.io
echo "[+] Publishing roche-rs to crates.io..."
cd crates/roche-rs
cargo publish
cd ../..

echo "[✓] All Roche packages published successfully."
