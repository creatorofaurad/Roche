Write-Host "Installing Foundryup for Windows..." -ForegroundColor Cyan
Invoke-RestMethod https://raw.githubusercontent.com/foundry-rs/foundry/master/foundryup/install.ps1 | Invoke-Expression

$foundryup = "$HOME\.foundry\bin\foundryup.exe"
if (Test-Path $foundryup) {
    Write-Host "Running foundryup to fetch forge, cast, anvil, chisel..." -ForegroundColor Green
    & $foundryup
} else {
    Write-Host "Foundryup downloaded to $HOME\.foundry\bin" -ForegroundColor Yellow
}
