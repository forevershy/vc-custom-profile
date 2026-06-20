# CustomProfile — one-click Vencord installer (Windows)
# Double-click install.bat, or run:
#   powershell -ExecutionPolicy Bypass -File install.ps1
#
# Optional: install to one Discord only
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Branch ptb

param(
    [ValidateSet("stable", "ptb", "canary", "all")]
    [string]$Branch = "all"
)

$ErrorActionPreference = "Stop"

$VencordDir = Join-Path $env:USERPROFILE "Vencord"
$PluginName = "vc-custom-profile"
$ScriptDir = $PSScriptRoot
$PluginDest = Join-Path $VencordDir "src\userplugins\$PluginName"

$DiscordBranches = [ordered]@{
    stable = @{ Label = "Discord"; Path = Join-Path $env:LOCALAPPDATA "Discord" }
    ptb    = @{ Label = "Discord PTB"; Path = Join-Path $env:LOCALAPPDATA "DiscordPTB" }
    canary = @{ Label = "Discord Canary"; Path = Join-Path $env:LOCALAPPDATA "DiscordCanary" }
}

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
        throw "$label was installed but is not on PATH yet. Close this window, open a new PowerShell, and run the installer again."
    }
}

function Test-DiscordBranchInstalled($branchKey) {
    $path = $DiscordBranches[$branchKey].Path
    return (Test-Path $path) -and (Get-ChildItem $path -Directory -Filter "app-*" -ErrorAction SilentlyContinue)
}

function Get-TargetBranches {
    if ($Branch -ne "all") {
        if (-not (Test-DiscordBranchInstalled $Branch)) {
            throw "$($DiscordBranches[$Branch].Label) was not found. Install it from https://discord.com/download first."
        }
        return @($Branch)
    }

    $found = @()
    foreach ($key in $DiscordBranches.Keys) {
        if (Test-DiscordBranchInstalled $key) {
            $found += $key
        }
    }
    if ($found.Count -eq 0) {
        throw "No Discord installs found. Install Discord from https://discord.com/download first."
    }
    return $found
}

function Close-DiscordClients {
    $names = @("Discord", "DiscordPTB", "DiscordCanary")
    $procs = Get-Process -Name $names -ErrorAction SilentlyContinue
    if (-not $procs) { return }

    Write-Step "Closing Discord (required for install)..."
    $procs | Stop-Process -Force
    Start-Sleep -Seconds 2
}

function Install-PluginFiles {
    Write-Step "Copying CustomProfile plugin..."
    New-Item -ItemType Directory -Force -Path (Split-Path $PluginDest) | Out-Null
    if (Test-Path $PluginDest) {
        Remove-Item -Recurse -Force $PluginDest
    }
    Copy-Item -Recurse -Force $ScriptDir $PluginDest
}

function Build-Vencord {
    if (-not (Test-Path $VencordDir)) {
        Write-Step "Cloning Vencord (first time only, may take a minute)..."
        git clone https://github.com/Vendicated/Vencord.git $VencordDir
    }

    Push-Location $VencordDir
    try {
        if (-not (Test-Path "node_modules")) {
            Write-Step "Installing Vencord dependencies (first time only)..."
            pnpm install
        }

        Write-Step "Building Vencord with CustomProfile..."
        pnpm build

        $installer = Join-Path $VencordDir "dist\Installer\VencordInstallerCli.exe"
        if (-not (Test-Path $installer)) {
            throw "Installer not found at $installer"
        }
        return $installer
    }
    finally {
        Pop-Location
    }
}

function Inject-Vencord($installer, $targetBranches) {
    $env:VENCORD_USER_DATA_DIR = $VencordDir
    $env:VENCORD_DEV_INSTALL = "1"

    foreach ($target in $targetBranches) {
        $label = $DiscordBranches[$target].Label
        Write-Step "Installing into $label..."
        & $installer -install -branch $target
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install into $label"
        }
    }
}

Write-Host ""
Write-Host "CustomProfile installer" -ForegroundColor Green
Write-Host "Sets up Vencord with the CustomProfile plugin." -ForegroundColor DarkGray

$targetBranches = Get-TargetBranches
$labels = $targetBranches | ForEach-Object { $DiscordBranches[$_].Label }
Write-Host "Target: $($labels -join ', ')" -ForegroundColor DarkGray

Close-DiscordClients

Ensure-Command git Git.Git "Git"
Ensure-Command node OpenJS.NodeJS.LTS "Node.js"

if (-not (Test-Command pnpm)) {
    Write-Step "Installing pnpm..."
    npm install -g pnpm
    if (-not (Test-Command pnpm)) {
        throw "pnpm install failed. Try running: npm install -g pnpm"
    }
}

Install-PluginFiles
$installer = Build-Vencord
Inject-Vencord $installer $targetBranches

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps (do this in each Discord you use):"
Write-Host "  1. Open Discord"
Write-Host "  2. Settings -> Vencord -> Plugins"
Write-Host "  3. Enable CustomProfile"
Write-Host "  4. Restart Discord"
Write-Host ""
Write-Host "Open the editor: Plugins -> CustomProfile -> Open Custom Profile Editor"
Write-Host ""
Read-Host "Press Enter to exit"
