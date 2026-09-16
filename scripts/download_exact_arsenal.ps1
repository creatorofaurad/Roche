$tools = "C:\Users\srija\Projects\tools_bin"
if (!(Test-Path $tools)) {
    New-Item -ItemType Directory -Path $tools -Force | Out-Null
}

Write-Host "`n[1/3] Downloading Foundry (v1.8.3 - Forge, Cast, Anvil, Chisel)..." -ForegroundColor Cyan
$fUrl = "https://github.com/foundry-rs/foundry/releases/download/v1.8.3/foundry_v1.8.3_win32_amd64.zip"
$fZip = "$tools\foundry.zip"
Invoke-WebRequest -Uri $fUrl -OutFile $fZip -UseBasicParsing
Expand-Archive -Path $fZip -DestinationPath $tools -Force
Remove-Item $fZip -Force -ErrorAction SilentlyContinue
Write-Host "  [+] Foundry Installed to $tools" -ForegroundColor Green

Write-Host "`n[2/3] Downloading Echidna (v2.3.3 - Property Fuzzer)..." -ForegroundColor Cyan
$eUrl = "https://github.com/crytic/echidna/releases/download/v2.3.3/echidna-2.3.3-x86_64-windows.zip"
$eZip = "$tools\echidna.zip"
Invoke-WebRequest -Uri $eUrl -OutFile $eZip -UseBasicParsing
Expand-Archive -Path $eZip -DestinationPath $tools -Force
Remove-Item $eZip -Force -ErrorAction SilentlyContinue
Write-Host "  [+] Echidna Installed to $tools" -ForegroundColor Green

Write-Host "`n[3/3] Installing Aderyn via Cargo..." -ForegroundColor Cyan
cargo install aderyn --locked

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "   🔥 All Web3 Security Binaries Successfully Installed! 🔥" -ForegroundColor Green
Write-Host "============================================================`n" -ForegroundColor Cyan

Get-ChildItem $tools
