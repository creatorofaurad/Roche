# ROCHE Universal One-Line Installer for Windows
# Usage: irm https://raw.githubusercontent.com/creatorofaurad/ROCHE/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

Write-Host @"
`e[38;2;0;255;136m
â•¦  â•¦â•”â•â•—â•¦  â•”â•¦â•—â•”â•â•—
â•šâ•—â•”â•â•‘ â•‘â•‘   â•‘ â• â•â•£
 â•šâ• â•šâ•â•â•©â•â• â•© â•© â•©  v1.0.0-beta
The Bare-Silicon EVM Security Suite
`e[0m
"@

$ROCHEDir = "$env:USERPROFILE\.ROCHE\bin"
if (-not (Test-Path $ROCHEDir)) {
    New-Item -ItemType Directory -Path $ROCHEDir -Force | Out-Null
}

Write-Host "[*] Checking for native Zig environment..." -ForegroundColor Cyan
$hasZig = Get-Command "zig" -ErrorAction SilentlyContinue

if (-not $hasZig) {
    Write-Host "[+] Installing Zig toolchain via winget..." -ForegroundColor Yellow
    winget install zig.zig -e --accept-source-agreements --accept-package-agreements
}

Write-Host "[*] Compiling & Installing ROCHE to $ROCHEDir..." -ForegroundColor Cyan
if (Test-Path ".\build.zig") {
    zig build -Doptimize=ReleaseFast
    Copy-Item ".\zig-out\bin\ROCHE.exe" "$ROCHEDir\ROCHE.exe" -Force
} else {
    # If installed remotely, clone and build
    $tempDir = [System.IO.Path]::GetTempPath() + "ROCHE_build_" + [System.Guid]::NewGuid().ToString().Substring(0,8)
    git clone https://github.com/creatorofaurad/ROCHE.git $tempDir
    Push-Location $tempDir
    zig build -Doptimize=ReleaseFast
    Copy-Item ".\zig-out\bin\ROCHE.exe" "$ROCHEDir\ROCHE.exe" -Force
    Pop-Location
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
}

# Add to User PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$ROCHEDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$ROCHEDir", "User")
    $env:Path += ";$ROCHEDir"
}

Write-Host "[âœ“] ROCHE successfully installed to $ROCHEDir\ROCHE.exe!" -ForegroundColor Green
Write-Host "Run 'ROCHE help' to get started." -ForegroundColor Gray
