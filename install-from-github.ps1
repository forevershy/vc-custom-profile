# CustomProfile — install directly from GitHub (no zip needed)
# Close Discord completely before running.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File install-from-github.ps1
#
# Optional: pass a fork URL
#   powershell -ExecutionPolicy Bypass -File install-from-github.ps1 -RepoUrl "https://github.com/you/vc-custom-profile.git"

param(
    [string]$RepoUrl = "https://github.com/REPLACE_ME/vc-custom-profile.git"
)

$ErrorActionPreference = "Stop"

$VencordDir = Join-Path $env:USERPROFILE "Vencord"
$PluginName = "vc-custom-profile"
$PluginDest = Join-Path $VencordDir "src\userplugins\$PluginName"
$DiscordPath = Join-Path $env:LOCALAPPDATA "Discord"
$TempDir = Join-Path $env:TEMP "vc-custom-profile-install"

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
        throw "$label is missing and winget is not available. Install $label manually."
    }
    winget install --id $wingetId -e --accept-package-agreements --accept-source-agreements
    if (-not (Test-Command $name)) {
        throw "$label was installed but is not on PATH yet. Open a new PowerShell and run this script again."
    }
}

if ($RepoUrl -like "*REPLACE_ME*") {
    Write-Host "Set your GitHub repo URL in install-from-github.ps1, or pass -RepoUrl." -ForegroundColor Yellow
    Write-Host 'Example: powershell -ExecutionPolicy Bypass -File install-from-github.ps1 -RepoUrl "https://github.com/yourname/vc-custom-profile.git"'
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "CustomProfile installer (from GitHub)" -ForegroundColor Green

if (Get-Process Discord -ErrorAction SilentlyContinue) {
    Write-Host "Please close Discord completely, then run this script again." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Ensure-Command git Git.Git "Git"
Ensure-Command node OpenJS.NodeJS.LTS "Node.js"

if (-not (Test-Command pnpm)) {
    Write-Step "Installing pnpm..."
    npm install -g pnpm
}

if (-not (Test-Path $VencordDir)) {
    Write-Step "Cloning Vencord..."
    git clone https://github.com/Vendicated/Vencord.git $VencordDir
}

Write-Step "Downloading CustomProfile from GitHub..."
if (Test-Path $TempDir) { Remove-Item -Recurse -Force $TempDir }
git clone --depth 1 $RepoUrl $TempDir

Write-Step "Installing plugin..."
New-Item -ItemType Directory -Force -Path (Split-Path $PluginDest) | Out-Null
if (Test-Path $PluginDest) { Remove-Item -Recurse -Force $PluginDest }
Copy-Item -Recurse -Force $TempDir $PluginDest
Remove-Item -Recurse -Force $TempDir

Push-Location $VencordDir
try {
    if (-not (Test-Path "node_modules")) {
        Write-Step "Installing Vencord dependencies..."
        pnpm install
    }

    Write-Step "Building Vencord..."
    pnpm build

    Write-Step "Injecting into Discord..."
    $env:VENCORD_USER_DATA_DIR = $VencordDir
    $env:VENCORD_DEV_INSTALL = "1"
    & (Join-Path $VencordDir "dist\Installer\VencordInstallerCli.exe") -install -location $DiscordPath
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Done! Open Discord -> Settings -> Vencord -> Plugins -> enable CustomProfile -> restart." -ForegroundColor Green
Read-Host "Press Enter to exit"
