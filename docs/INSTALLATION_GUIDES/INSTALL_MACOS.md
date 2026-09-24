# Installing Roche on macOS

## System Requirements

- OS: macOS 13 (Ventura) or higher
- Architecture: Apple Silicon (M1/M2/M3/M4) or Intel x86_64

## Installation via Homebrew or Source

### Option A: Building from Source

```bash
# Install Zig 0.16.0
brew install zig

# Clone and Build Roche Engine
git clone https://github.com/creatorofaurad/Roche.git
cd Roche
zig build -Doptimize=ReleaseFast
cp ./zig-out/bin/roche /usr/local/bin/
```

### Verification

```bash
roche --version
```
