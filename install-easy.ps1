# CustomProfile — one-command GitHub installer
# Friends paste this in PowerShell:
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm 'https://raw.githubusercontent.com/forevershy/vc-custom-profile/master/install-easy.ps1')"

param(
    [string]$Repo = "forevershy/vc-custom-profile",
    [string]$Branch = "master",
    [ValidateSet("stable", "ptb", "canary", "all", "auto")]
    [string]$DiscordBranch = "all"
)

$ErrorActionPreference = "Stop"

# Older Windows PowerShell can fail GitHub downloads without TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
Write-Host ""
Write-Host "Tip: use Windows PowerShell or PowerShell 7 — not Command Prompt." -ForegroundColor DarkGray

if (Test-Path $TempRoot) {
    Remove-Item -Recurse -Force $TempRoot
}
New-Item -ItemType Directory -Force -Path $TempRoot | Out-Null

Write-Step "Downloading from GitHub..."
try {
    Invoke-WebRequest -Uri $RepoZipUrl -OutFile $ZipPath -UseBasicParsing
}
catch {
    throw @"
Could not download from GitHub.
- Make sure you are connected to the internet
- Try again in a few minutes
- Or download the zip from https://github.com/$Repo and double-click install.bat

URL: $RepoZipUrl
"@
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
