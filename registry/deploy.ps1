# Deploy CustomProfile registry to Cloudflare Workers and configure Vencord.
$ErrorActionPreference = "Stop"
$RegistryDir = $PSScriptRoot
$SettingsPath = Join-Path $env:APPDATA "Vencord\settings\settings.json"

Set-Location $RegistryDir

if (-not (Test-Path "node_modules\wrangler")) {
    Write-Host "Installing wrangler..."
    npm install
}

Write-Host "Checking Cloudflare login..."
$whoami = npx wrangler whoami 2>&1 | Out-String
if ($whoami -match "not authenticated") {
    Write-Host ""
    Write-Host "Opening browser for Cloudflare login — approve the request, then press Enter here."
    npx wrangler login
}

Write-Host "Creating KV namespace (skip if you already have one)..."
$kvOut = npx wrangler kv namespace create PROFILES 2>&1 | Out-String
if ($kvOut -match 'id = "([^"]+)"') {
    $kvId = $Matches[1]
    Write-Host "KV namespace id: $kvId"
    $toml = Get-Content "wrangler.toml" -Raw
    $toml = $toml -replace 'id = "REPLACE_WITH_YOUR_KV_NAMESPACE_ID"', "id = `"$kvId`""
    Set-Content "wrangler.toml" $toml -NoNewline
} else {
    Write-Host $kvOut
}

Write-Host "Deploying worker..."
$deployOut = npx wrangler deploy 2>&1 | Out-String
Write-Host $deployOut

if ($deployOut -match "https://[^\s]+\.workers\.dev") {
    $url = $Matches[0].TrimEnd("/")
    Write-Host ""
    Write-Host "Registry URL: $url"

    if (Test-Path $SettingsPath) {
        $settings = Get-Content $SettingsPath -Raw | ConvertFrom-Json
        if (-not $settings.plugins.CustomProfile) {
            $settings.plugins | Add-Member -NotePropertyName "CustomProfile" -NotePropertyValue (@{}) -Force
        }
        $settings.plugins.CustomProfile.registryBaseUrl = $url
        $settings.plugins.CustomProfile.sharePublicly = $true
        $settings.plugins.CustomProfile.syncProfilesFromOthers = $true
        $settings | ConvertTo-Json -Depth 100 | Set-Content $SettingsPath
        Write-Host "Updated Vencord settings: registryBaseUrl = $url"
        Write-Host "Restart Discord for settings to load."
    }
} else {
    Write-Host "Deploy may have failed — check output above."
    exit 1
}
