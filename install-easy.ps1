# CustomProfile — one-command GitHub installer
# Friends paste this in PowerShell (no zip, no git needed):
#   irm https://raw.githubusercontent.com/forevershy/vc-custom-profile/master/install-easy.ps1 | iex
#
# Optional (power users):
#   & ([scriptblock]::Create((irm https://raw.githubusercontent.com/forevershy/vc-custom-profile/master/install-easy.ps1))) -DiscordBranch ptb

param(
    [string]$Repo = "forevershy/vc-custom-profile",
    [string]$Branch = "master",
    [ValidateSet("stable", "ptb", "canary", "all")]
    [string]$DiscordBranch = "all"
)

$ErrorActionPreference = "Stop"

$RepoZipUrl = "https://github.com/$Repo/archive/refs/heads/$Branch.zip"
$TempRoot = Join-Path $env:TEMP "vc-custom-profile-easy-install"
$ZipPath = Join-Path $TempRoot "repo.zip"
$ExtractRoot = Join-Path $TempRoot "extracted"

function Write-Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "CustomProfile — easy installer" -ForegroundColor Green
Write-Host "Repo: https://github.com/$Repo" -ForegroundColor DarkGray

if (Test-Path $TempRoot) {
    Remove-Item -Recurse -Force $TempRoot
}
New-Item -ItemType Directory -Force -Path $TempRoot | Out-Null

Write-Step "Downloading from GitHub..."
try {
    Invoke-WebRequest -Uri $RepoZipUrl -OutFile $ZipPath -UseBasicParsing
}
catch {
    throw "Could not download the plugin from GitHub. Check your internet connection and try again.`n$RepoZipUrl"
}

Write-Step "Extracting..."
Expand-Archive -Path $ZipPath -DestinationPath $ExtractRoot -Force

$repoFolder = Get-ChildItem $ExtractRoot -Directory | Select-Object -First 1
if (-not $repoFolder) {
    throw "Download succeeded but the zip was empty."
}

$installScript = Join-Path $repoFolder.FullName "install.ps1"
if (-not (Test-Path $installScript)) {
    throw "install.ps1 was not found in the downloaded repo."
}

Write-Step "Running installer..."
& $installScript -Branch $DiscordBranch
