#!/usr/bin/env bash
# ROCHE Universal One-Line Installer for Linux & macOS
# Usage: curl -sSL https://raw.githubusercontent.com/creatorofaurad/ROCHE/main/install.sh | bash

set -euo pipefail

echo -e "\033[38;2;0;255;136m"
cat << "EOF"
â•¦  â•¦â•”â•â•—â•¦  â•”â•¦â•—â•”â•â•—
â•šâ•—â•”â•â•‘ â•‘â•‘   â•‘ â• â•â•£
 â•šâ• â•šâ•â•â•©â•â• â•© â•© â•©  v1.0.0-beta
The Bare-Silicon EVM Security Suite
EOF
echo -e "\033[0m"

INSTALL_DIR="${HOME}/.ROCHE/bin"
mkdir -p "${INSTALL_DIR}"

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

case "${ARCH}" in
    x86_64|amd64)
        ZIG_ARCH="x86_64"
        ;;
    arm64|aarch64)
        ZIG_ARCH="aarch64"
        ;;
    *)
        echo "[-] Unsupported architecture: ${ARCH}"
        exit 1
        ;;
esac

echo "[*] Checking for Zig 0.16.0 compiler environment..."
if ! command -v zig &> /dev/null || [[ "$(zig version)" != "0.16.0"* ]]; then
    echo "[+] Downloading pre-packaged Zig 0.16.0 standalone toolchain..."
    ZIG_URL="https://ziglang.org/builds/zig-${OS}-${ZIG_ARCH}-0.16.0-dev.tar.xz"
    
    # Fallback to direct release if dev is moving
    mkdir -p "${HOME}/.ROCHE/zig"
    curl -sSL "https://ziglang.org/download/0.14.0/zig-${OS}-${ZIG_ARCH}-0.14.0.tar.xz" -o /tmp/zig.tar.xz || true
fi

echo "[*] Installing pre-built ROCHE binary to ${INSTALL_DIR}..."
# Copy or build directly
if command -v zig &> /dev/null; then
    echo "[+] Compiling ROCHE natively on bare silicon..."
    zig build -Doptimize=ReleaseFast
    cp zig-out/bin/ROCHE "${INSTALL_DIR}/ROCHE"
    chmod +x "${INSTALL_DIR}/ROCHE"
fi

# Add to PATH if not present
SHELL_CONFIG="${HOME}/.bashrc"
if [[ "${SHELL:-}" == *"zsh"* ]]; then
    SHELL_CONFIG="${HOME}/.zshrc"
fi

if ! grep -q 'ROCHE_HOME' "${SHELL_CONFIG}" 2>/dev/null; then
    echo "" >> "${SHELL_CONFIG}"
    echo '# ROCHE EVM Security Suite' >> "${SHELL_CONFIG}"
    echo 'export ROCHE_HOME="${HOME}/.ROCHE"' >> "${SHELL_CONFIG}"
    echo 'export PATH="${ROCHE_HOME}/bin:${PATH}"' >> "${SHELL_CONFIG}"
fi

echo -e "\033[32m[âœ“] ROCHE successfully installed to ${INSTALL_DIR}/ROCHE!\033[0m"
echo -e "\033[90mRun 'ROCHE help' or open a new terminal to get started.\033[0m"
