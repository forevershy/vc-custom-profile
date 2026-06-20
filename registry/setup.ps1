# Download everything needed for CustomProfile registry (no Cloudflare login required).
$ErrorActionPreference = "Stop"
$RegistryDir = $PSScriptRoot

Write-Host "CustomProfile registry setup" -ForegroundColor Green
Set-Location $RegistryDir

Write-Host "Installing npm packages (wrangler)..."
npm install

Write-Host "Downloading cloudflared..."
npx --yes cloudflared --version | Out-Null

Write-Host "Verifying wrangler..."
npx wrangler --version

Write-Host ""
Write-Host "All downloads complete." -ForegroundColor Green
Write-Host ""
Write-Host "Next:"
Write-Host "  Temporary URL (PC must stay on):  .\start-local.ps1"
Write-Host "  Permanent URL (Cloudflare, free):  .\deploy.ps1"
