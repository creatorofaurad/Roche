# Installing Roche on Linux

## System Requirements

- OS: Ubuntu 22.04 LTS+, Debian 12+, Fedora 38+, Arch Linux
- Architecture: x86_64, aarch64
- Memory: 4 GB minimum

## Step-by-Step Installation

### 1. Install Dependencies & Zig 0.16.0

```bash
sudo apt update && sudo apt install -y build-essential git curl
curl -O https://ziglang.org/builds/zig-linux-x86_64-0.16.0-dev.tar.xz
tar -xf zig-linux-x86_64-0.16.0-dev.tar.xz
sudo mv zig-linux-x86_64-0.16.0-dev /usr/local/zig
export PATH="/usr/local/zig:$PATH"
```

### 2. Build Roche Engine

```bash
git clone https://github.com/creatorofaurad/Roche.git
cd Roche
zig build -Doptimize=ReleaseFast
sudo cp ./zig-out/bin/roche /usr/local/bin/
```

### 3. Verify Installation

```bash
roche --version
```
