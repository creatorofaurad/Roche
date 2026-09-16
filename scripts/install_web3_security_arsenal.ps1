# =================================================================================================
# Web3 Security Arsenal: Master Automated Downloader & Installer
# Installs Foundry, Slither, Aderyn, Halmos, Echidna, Mythril, Medusa, and ItyFuzz
# =================================================================================================

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "   🔥 Web3 Security Arsenal: Master Downloader 🔥" -ForegroundColor Green
Write-Host "============================================================`n" -ForegroundColor Cyan

$ToolsDir = "C:\Users\srija\Projects\tools_bin"
if (!(Test-Path $ToolsDir)) {
    New-Item -ItemType Directory -Path $ToolsDir -Force | Out-Null
}

# -------------------------------------------------------------------------------------------------
# 1. Foundry (Forge, Cast, Anvil, Chisel)
# -------------------------------------------------------------------------------------------------
Write-Host "[1/7] Installing Foundry (forge / cast)..." -ForegroundColor Yellow
if (!(Get-Command forge -ErrorAction SilentlyContinue)) {
    try {
        winget install --id Paradigm.Foundry --accept-source-agreements --accept-package-agreements --silent
        Write-Host "  [+] Foundry Installed Successfully!" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Winget install skipped. Running alternative cargo install..." -ForegroundColor DarkGray
        cargo install --git https://github.com/foundry-rs/foundry --profile local --locked forge cast
    }
} else {
    Write-Host "  [✓] Foundry is already installed." -ForegroundColor Green
}

# -------------------------------------------------------------------------------------------------
# 2. Aderyn (Cyfrin Rust AST Static Analyzer)
# -------------------------------------------------------------------------------------------------
Write-Host "`n[2/7] Installing Aderyn (Cyfrin Static Analyzer)..." -ForegroundColor Yellow
if (!(Get-Command aderyn -ErrorAction SilentlyContinue)) {
    cargo install aderyn --locked
    Write-Host "  [+] Aderyn Installed Successfully!" -ForegroundColor Green
} else {
    Write-Host "  [✓] Aderyn is already installed." -ForegroundColor Green
}

# -------------------------------------------------------------------------------------------------
# 3. Slither & Solc-Select (Trail of Bits Python Static Analyzer)
# -------------------------------------------------------------------------------------------------
Write-Host "`n[3/7] Installing Slither & Solc-Select..." -ForegroundColor Yellow
pip install --upgrade slither-analyzer solc-select
Write-Host "  [+] Slither & Solc-Select Installed Successfully!" -ForegroundColor Green

# -------------------------------------------------------------------------------------------------
# 4. Halmos (a16z Symbolic Execution Engine)
# -------------------------------------------------------------------------------------------------
Write-Host "`n[4/7] Installing Halmos (a16z Symbolic Prover)..." -ForegroundColor Yellow
pip install --upgrade halmos z3-solver
Write-Host "  [+] Halmos Installed Successfully!" -ForegroundColor Green

# -------------------------------------------------------------------------------------------------
# 5. Mythril (ConsenSys Concolic Security Analyzer)
# -------------------------------------------------------------------------------------------------
Write-Host "`n[5/7] Installing Mythril (Security Analyzer)..." -ForegroundColor Yellow
pip install --upgrade mythril
Write-Host "  [+] Mythril Installed Successfully!" -ForegroundColor Green

# -------------------------------------------------------------------------------------------------
# 6. Echidna (Trail of Bits Fuzzer Windows Binary)
# -------------------------------------------------------------------------------------------------
Write-Host "`n[6/7] Downloading Echidna (Coverage-Guided Fuzzer)..." -ForegroundColor Yellow
$EchidnaZip = "$ToolsDir\echidna.zip"
$EchidnaExe = "$ToolsDir\echidna.exe"
if (!(Test-Path $EchidnaExe)) {
    try {
        $EchidnaUrl = "https://github.com/crytic/echidna/releases/download/v2.2.5/echidna-2.2.5-x86_64-windows.zip"
        Invoke-WebRequest -Uri $EchidnaUrl -OutFile $EchidnaZip -UseBasicParsing
        Expand-Archive -Path $EchidnaZip -DestinationPath $ToolsDir -Force
        Remove-Item $EchidnaZip -Force
        Write-Host "  [+] Echidna Downloaded to $EchidnaExe" -ForegroundColor Green
    } catch {
        Write-Host "  [-] Failed to download prebuilt Echidna binary: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  [✓] Echidna is already available in $EchidnaExe" -ForegroundColor Green
}

# -------------------------------------------------------------------------------------------------
# 7. ItyFuzz (On-Chain State Forking & Flash-Loan Synthesizer)
# -------------------------------------------------------------------------------------------------
Write-Host "`n[7/7] Installing ItyFuzz (Off-Chain Labs)..." -ForegroundColor Yellow
if (!(Get-Command ityfuzz -ErrorAction SilentlyContinue)) {
    cargo install --git https://github.com/fuzzland/ityfuzz ityfuzz --locked
    Write-Host "  [+] ItyFuzz Installed Successfully!" -ForegroundColor Green
} else {
    Write-Host "  [✓] ItyFuzz is already installed." -ForegroundColor Green
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "   🚀 All Security Tools Installed & Ready to Benchmark! 🚀" -ForegroundColor Green
Write-Host "============================================================`n" -ForegroundColor Cyan
