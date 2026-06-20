# CustomProfile — install directly from GitHub (no zip needed)
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File install-from-github.ps1 -RepoUrl "https://github.com/you/vc-custom-profile.git"
#
# Optional:
#   -Branch ptb    (stable, ptb, canary, or all — default is all)

param(
    [string]$RepoUrl = "https://github.com/forevershy/vc-custom-profile.git",
    [ValidateSet("stable", "ptb", "canary", "all")]
    [string]$Branch = "all"
)

$ErrorActionPreference = "Stop"
$TempDir = Join-Path $env:TEMP "vc-custom-profile-install"

function Write-Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

function Test-Command($name) {
    return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

if ($RepoUrl -like "*REPLACE_ME*") {
    Write-Host "Set your GitHub repo URL, or pass -RepoUrl." -ForegroundColor Yellow
    Write-Host 'Example: powershell -ExecutionPolicy Bypass -File install-from-github.ps1 -RepoUrl "https://github.com/yourname/vc-custom-profile.git"'
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "CustomProfile installer (from GitHub)" -ForegroundColor Green

if (-not (Test-Command git)) {
    Write-Step "Git is required. Installing..."
    if (-not (Test-Command winget)) {
        throw "Install Git from https://git-scm.com/download/win and run this script again."
    }
    winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements
    if (-not (Test-Command git)) {
        throw "Git was installed but is not on PATH yet. Open a new PowerShell and run this script again."
    }
}

Write-Step "Downloading CustomProfile from GitHub..."
if (Test-Path $TempDir) { Remove-Item -Recurse -Force $TempDir }
git clone --depth 1 $RepoUrl $TempDir

$installScript = Join-Path $TempDir "install.ps1"
if (-not (Test-Path $installScript)) {
    throw "install.ps1 was not found in the downloaded repo."
}

& $installScript -Branch $Branch
