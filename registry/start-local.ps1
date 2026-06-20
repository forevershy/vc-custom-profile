# Start local registry + public tunnel (URL changes each run — use deploy.ps1 for a permanent URL).
$ErrorActionPreference = "Stop"
$RegistryDir = $PSScriptRoot
$SettingsPath = Join-Path $env:APPDATA "Vencord\settings\settings.json"

Set-Location $RegistryDir
if (-not (Test-Path "node_modules")) { npm install }

$serverJob = Start-Job -ScriptBlock {
    Set-Location $using:RegistryDir
    node server.mjs
}

Start-Sleep -Seconds 2

Write-Host "Starting Cloudflare quick tunnel..."
$tunnelProc = Start-Process -FilePath "npx" -ArgumentList @("--yes", "cloudflared", "tunnel", "--url", "http://127.0.0.1:8787") -NoNewWindow -PassThru -RedirectStandardOutput "tunnel-out.log" -RedirectStandardError "tunnel-err.log"

$deadline = (Get-Date).AddSeconds(45)
$url = $null
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds 2
    $log = @()
    if (Test-Path "tunnel-out.log") { $log += Get-Content "tunnel-out.log" -ErrorAction SilentlyContinue }
    if (Test-Path "tunnel-err.log") { $log += Get-Content "tunnel-err.log" -ErrorAction SilentlyContinue }
    $joined = $log -join "`n"
    if ($joined -match "(https://[a-z0-9-]+\.trycloudflare\.com)") {
        $url = $Matches[1]
        break
    }
}

if (-not $url) {
    Write-Host "Could not read tunnel URL. Check tunnel-err.log"
    Stop-Job $serverJob -ErrorAction SilentlyContinue
    exit 1
}

Write-Host "Public registry URL: $url"
Write-Host "Keep this window open while sharing profiles."

if (Test-Path $SettingsPath) {
    $settings = Get-Content $SettingsPath -Raw | ConvertFrom-Json
    $settings.plugins.CustomProfile.registryBaseUrl = $url
    $settings | ConvertTo-Json -Depth 100 | Set-Content $SettingsPath
    Write-Host "Updated Vencord settings. Restart Discord, then save your profile."
}

Wait-Process -Id $tunnelProc.Id
