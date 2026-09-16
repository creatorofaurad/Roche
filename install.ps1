# Volta Universal One-Line Installer for Windows
# Usage: irm https://raw.githubusercontent.com/creatorofaurad/volta/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

Write-Host @"
`e[38;2;0;255;136m
╦  ╦╔═╗╦  ╔╦╗╔═╗
╚╗╔╝║ ║║   ║ ╠═╣
 ╚╝ ╚═╝╩═╝ ╩ ╩ ╩  v1.0.0-beta
The Bare-Silicon EVM Security Suite
`e[0m
"@

$voltaDir = "$env:USERPROFILE\.volta\bin"
if (-not (Test-Path $voltaDir)) {
    New-Item -ItemType Directory -Path $voltaDir -Force | Out-Null
}

Write-Host "[*] Checking for native Zig environment..." -ForegroundColor Cyan
$hasZig = Get-Command "zig" -ErrorAction SilentlyContinue

if (-not $hasZig) {
    Write-Host "[+] Installing Zig toolchain via winget..." -ForegroundColor Yellow
    winget install zig.zig -e --accept-source-agreements --accept-package-agreements
}

Write-Host "[*] Compiling & Installing Volta to $voltaDir..." -ForegroundColor Cyan
if (Test-Path ".\build.zig") {
    zig build -Doptimize=ReleaseFast
    Copy-Item ".\zig-out\bin\volta.exe" "$voltaDir\volta.exe" -Force
} else {
    # If installed remotely, clone and build
    $tempDir = [System.IO.Path]::GetTempPath() + "volta_build_" + [System.Guid]::NewGuid().ToString().Substring(0,8)
    git clone https://github.com/creatorofaurad/volta.git $tempDir
    Push-Location $tempDir
    zig build -Doptimize=ReleaseFast
    Copy-Item ".\zig-out\bin\volta.exe" "$voltaDir\volta.exe" -Force
    Pop-Location
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue
}

# Add to User PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$voltaDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$voltaDir", "User")
    $env:Path += ";$voltaDir"
}

Write-Host "[✓] Volta successfully installed to $voltaDir\volta.exe!" -ForegroundColor Green
Write-Host "Run 'volta help' to get started." -ForegroundColor Gray
