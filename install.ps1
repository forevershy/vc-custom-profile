# CustomProfile — one-click Vencord installer (Windows)
# Double-click install.bat, or run:
#   powershell -ExecutionPolicy Bypass -File install.ps1

param(
    [ValidateSet("stable", "ptb", "canary", "all", "auto")]
    [string]$Branch = "all"
)

$ErrorActionPreference = "Stop"
$LogFile = Join-Path $env:TEMP "customprofile-install.log"

$VencordDir = Join-Path $env:USERPROFILE "Vencord"
$PluginName = "vc-custom-profile"
$ScriptDir = $PSScriptRoot
$PluginDest = Join-Path $VencordDir "src\userplugins\$PluginName"

$DiscordBranches = [ordered]@{
    stable = @{ Label = "Discord"; Path = Join-Path $env:LOCALAPPDATA "Discord" }
    ptb    = @{ Label = "Discord PTB"; Path = Join-Path $env:LOCALAPPDATA "DiscordPTB" }
    canary = @{ Label = "Discord Canary"; Path = Join-Path $env:LOCALAPPDATA "DiscordCanary" }
}

$ExcludeCopyDirs = @("registry", ".git", "sharedCustomProfiles-plugin", "node_modules")
$ExcludeCopyFiles = @(
    "install.ps1", "install.bat", "install-easy.ps1", "install-from-github.ps1",
    "publish-to-github.ps1", "GITHUB-SETUP.md", "INSTALL-FRIEND.md", "README.md"
)

function Write-Log($msg) {
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg" | Out-File -FilePath $LogFile -Append -Encoding utf8
}

function Write-Step($msg) {
    Write-Host ""
    Write-Host "==> $msg" -ForegroundColor Cyan
    Write-Log $msg
}

function Refresh-Path {
    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $user = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machine;$user"
}

function Test-Command($name) {
    return $null -ne (Get-Command $name -ErrorAction SilentlyContinue)
}

function Find-CommandPath($name, $fallbacks) {
    Refresh-Path
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    foreach ($path in $fallbacks) {
        if (Test-Path $path) { return $path }
    }
    return $null
}

function Ensure-Command($name, $wingetId, $label, $fallbacks) {
    if (Find-CommandPath $name $fallbacks) { return }
    Write-Step "Installing $label (one-time setup)..."
    if (-not (Test-Command winget)) {
        throw "$label is not installed and winget is not available.`nInstall $label manually, then run the installer again.`nLog: $LogFile"
    }
    winget install --id $wingetId -e --accept-package-agreements --accept-source-agreements
    Refresh-Path
    if (-not (Find-CommandPath $name $fallbacks)) {
        throw "$label was installed but is not ready yet.`nClose PowerShell, open a new window, and run the installer again.`nLog: $LogFile"
    }
}

function Invoke-Pnpm {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Args)
    Refresh-Path
    if (Test-Command pnpm) {
        & pnpm @Args
        return
    }
    if (Test-Command corepack) {
        Write-Step "Enabling pnpm via corepack..."
        & corepack enable 2>$null
        & corepack prepare pnpm@latest --activate 2>$null
        if (Test-Command pnpm) {
            & pnpm @Args
            return
        }
    }
    Write-Step "Running pnpm via npx (no global install needed)..."
    & npx --yes pnpm@latest @Args
}

function Test-DiscordBranchInstalled($branchKey) {
    $path = $DiscordBranches[$branchKey].Path
    return (Test-Path $path) -and (Get-ChildItem $path -Directory -Filter "app-*" -ErrorAction SilentlyContinue)
}

function Get-TargetBranches {
    if ($Branch -eq "auto") {
        return @("__auto__")
    }

    if ($Branch -ne "all") {
        if (-not (Test-DiscordBranchInstalled $Branch)) {
            Write-Host ""
            Write-Host "Could not find $($DiscordBranches[$Branch].Label) in the usual install folder." -ForegroundColor Yellow
            Write-Host "Trying Vencord auto-detect instead..." -ForegroundColor Yellow
            return @("__auto__")
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
        Write-Host ""
        Write-Host "Could not find Discord in the usual folders (maybe Microsoft Store install)." -ForegroundColor Yellow
        Write-Host "Trying Vencord auto-detect instead..." -ForegroundColor Yellow
        return @("__auto__")
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

function Copy-PluginFiles {
    Write-Step "Copying CustomProfile plugin..."
    New-Item -ItemType Directory -Force -Path (Split-Path $PluginDest) | Out-Null
    if (Test-Path $PluginDest) {
        Remove-Item -Recurse -Force $PluginDest
    }
    New-Item -ItemType Directory -Force -Path $PluginDest | Out-Null

    Get-ChildItem $ScriptDir -Force | ForEach-Object {
        if ($ExcludeCopyDirs -contains $_.Name) { return }
        if ($ExcludeCopyFiles -contains $_.Name) { return }
        Copy-Item -Recurse -Force $_.FullName (Join-Path $PluginDest $_.Name)
    }
}

function Build-Vencord {
    $git = Find-CommandPath git @("C:\Program Files\Git\cmd\git.exe", "C:\Program Files (x86)\Git\cmd\git.exe")
    if (-not $git) { throw "Git was not found. Log: $LogFile" }

    if (-not (Test-Path $VencordDir)) {
        Write-Step "Cloning Vencord (first time only, may take a minute)..."
        & $git clone https://github.com/Vendicated/Vencord.git $VencordDir
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to clone Vencord. Check your internet connection.`nLog: $LogFile"
        }
    }

    Push-Location $VencordDir
    try {
        if (-not (Test-Path "node_modules")) {
            Write-Step "Installing Vencord dependencies (first time only, can take several minutes)..."
            Invoke-Pnpm install
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to install Vencord dependencies.`nLog: $LogFile"
            }
        }

        Write-Step "Building Vencord with CustomProfile..."
        Invoke-Pnpm build
        if ($LASTEXITCODE -ne 0) {
            throw "Vencord build failed.`nLog: $LogFile"
        }

        $installer = Join-Path $VencordDir "dist\Installer\VencordInstallerCli.exe"
        if (-not (Test-Path $installer)) {
            throw "Installer not found at $installer`nLog: $LogFile"
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
        if ($target -eq "__auto__") {
            Write-Step "Installing into Discord (auto-detect)..."
            & $installer -install -branch auto
        }
        else {
            $label = $DiscordBranches[$target].Label
            Write-Step "Installing into $label..."
            & $installer -install -branch $target
        }
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install into Discord.`nLog: $LogFile"
        }
    }
}

try {
    if (Test-Path $LogFile) { Remove-Item $LogFile -Force }
    Write-Log "CustomProfile install started"

    Write-Host ""
    Write-Host "CustomProfile installer" -ForegroundColor Green
    Write-Host "Sets up Vencord with the CustomProfile plugin." -ForegroundColor DarkGray
    Write-Host "Log file: $LogFile" -ForegroundColor DarkGray

    $targetBranches = Get-TargetBranches
    if ($targetBranches -contains "__auto__") {
        Write-Host "Target: Discord (auto-detect)" -ForegroundColor DarkGray
    }
    else {
        $labels = $targetBranches | ForEach-Object { $DiscordBranches[$_].Label }
        Write-Host "Target: $($labels -join ', ')" -ForegroundColor DarkGray
    }

    Close-DiscordClients

    Ensure-Command git Git.Git "Git" @(
        "C:\Program Files\Git\cmd\git.exe",
        "C:\Program Files (x86)\Git\cmd\git.exe"
    )
    Ensure-Command node OpenJS.NodeJS.LTS "Node.js" @(
        "C:\Program Files\nodejs\node.exe",
        "$env:ProgramFiles\nodejs\node.exe"
    )

    Copy-PluginFiles
    $installer = Build-Vencord
    Inject-Vencord $installer $targetBranches

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
    Write-Log "Install completed successfully"
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Install failed:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Send this log file to your friend who shared the plugin:" -ForegroundColor Yellow
    Write-Host $LogFile -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Also see INSTALL-FRIEND.md -> Troubleshooting"
    exit 1
}

Read-Host "Press Enter to exit"
