# Installing Roche on Windows

## System Requirements

- OS: Windows 10 / Windows 11 (64-bit)
- PowerShell 7.0+ or Command Prompt

## Step-by-Step Instructions

### 1. Install Zig Compiler

Download Zig 0.16.0 from [ziglang.org](https://ziglang.org/download/) and extract it to `C:\zig`.
Add `C:\zig` to your System `PATH` Environment Variable.

### 2. Build Roche Engine

Open PowerShell:

```powershell
git clone https://github.com/creatorofaurad/Roche.git
cd Roche
zig build -Doptimize=ReleaseFast
```

The binary will be generated at `.\zig-out\bin\roche.exe`.

### 3. Verify Binary

```powershell
.\zig-out\bin\roche.exe --version
```
