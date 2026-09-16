$tools = "C:\Users\srija\Projects\tools_bin"
if (!(Test-Path $tools)) {
    New-Item -ItemType Directory -Path $tools -Force | Out-Null
}

Write-Host "Downloading Foundry (nightly)..." -ForegroundColor Cyan
$fUrl = "https://github.com/foundry-rs/foundry/releases/download/nightly/foundry_nightly_win32_amd64.tar.gz"
$fTar = "$tools\foundry.tar.gz"
Invoke-WebRequest -Uri $fUrl -OutFile $fTar -UseBasicParsing
tar -xzf $fTar -C $tools
Remove-Item $fTar -Force -ErrorAction SilentlyContinue

Write-Host "Downloading Echidna (v2.2.5)..." -ForegroundColor Cyan
$eUrl = "https://github.com/crytic/echidna/releases/download/v2.2.5/echidna-2.2.5-x86_64-windows.zip"
$eZip = "$tools\echidna.zip"
Invoke-WebRequest -Uri $eUrl -OutFile $eZip -UseBasicParsing
Expand-Archive -Path $eZip -DestinationPath $tools -Force
Remove-Item $eZip -Force -ErrorAction SilentlyContinue

Write-Host "Available binaries in $tools :" -ForegroundColor Green
Get-ChildItem $tools
