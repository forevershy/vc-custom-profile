# CustomProfile — one-click Vencord installer (Windows)
# Double-click or run:  powershell -ExecutionPolicy Bypass -File install.ps1
# Close Discord completely before running.

$ErrorActionPreference = "Stop"

$VencordDir = Join-Path $env:USERPROFILE "Vencord"
$PluginName = "vc-custom-profile"
$ScriptDir = $PSScriptRoot
$PluginDest = Join-Path $VencordDir "src\userplugins\$PluginName"
$DiscordPath = Join-Path $env:LOCALAPPDATA "Discord"

function Write-Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

function Test-Command($name) {
    return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

function Ensure-Command($name, $wingetId, $label) {
    if (Test-Command $name) { return }
    Write-Step "Installing $label..."
    if (-not (Test-Command winget)) {
        throw "$label is missing and winget is not available. Install $label manually: $wingetId"
    }
    winget install --id $wingetId -e --accept-package-agreements --accept-source-agreements
    if (-not (Test-Command $name)) {
        throw "$label was installed but is not on PATH yet. Close this window, open a new PowerShell, and run install.ps1 again."
    }
}

Write-Host ""
Write-Host "CustomProfile installer" -ForegroundColor Green
Write-Host "This will set up Vencord with the CustomProfile plugin." -ForegroundColor DarkGray

if (Get-Process Discord -ErrorAction SilentlyContinue) {
    Write-Host ""
    Write-Host "Please close Discord completely, then run this script again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Ensure-Command git Git.Git "Git"
Ensure-Command node OpenJS.NodeJS.LTS "Node.js"

if (-not (Test-Command pnpm)) {
    Write-Step "Installing pnpm..."
    npm install -g pnpm
    if (-not (Test-Command pnpm)) {
        throw "pnpm install failed. Try running: npm install -g pnpm"
    }
}

if (-not (Test-Path $VencordDir)) {
    Write-Step "Cloning Vencord (first time only, may take a minute)..."
    git clone https://github.com/Vendicated/Vencord.git $VencordDir
}

Write-Step "Copying CustomProfile plugin..."
New-Item -ItemType Directory -Force -Path (Split-Path $PluginDest) | Out-Null
if (Test-Path $PluginDest) {
    Remove-Item -Recurse -Force $PluginDest
}
Copy-Item -Recurse -Force $ScriptDir $PluginDest

Write-Step "Installing dependencies (first time only)..."
Push-Location $VencordDir
try {
    if (-not (Test-Path "node_modules")) {
        pnpm install
    }

    Write-Step "Building Vencord with CustomProfile..."
    pnpm build

    Write-Step "Injecting into Discord..."
    $env:VENCORD_USER_DATA_DIR = $VencordDir
    $env:VENCORD_DEV_INSTALL = "1"
    $installer = Join-Path $VencordDir "dist\Installer\VencordInstallerCli.exe"
    if (-not (Test-Path $installer)) {
        throw "Installer not found at $installer"
    }
    & $installer -install -location $DiscordPath
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Open Discord"
Write-Host "  2. Settings -> Vencord -> Plugins"
Write-Host "  3. Enable CustomProfile"
Write-Host "  4. Restart Discord"
Write-Host ""
Write-Host "Open the editor: Plugins -> CustomProfile -> Open Custom Profile Editor"
Write-Host ""
Read-Host "Press Enter to exit"
