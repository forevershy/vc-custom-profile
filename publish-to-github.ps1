# Creates a public GitHub repo and pushes CustomProfile (requires: gh auth login)
param(
    [string]$RepoName = "vc-custom-profile",
    [ValidateSet("public", "private")]
    [string]$Visibility = "public"
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot

Push-Location $Root
try {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "GitHub CLI (gh) is not installed. Run: winget install GitHub.cli"
    }

    $auth = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "You are not logged into GitHub." -ForegroundColor Yellow
        Write-Host "Run: gh auth login"
        exit 1
    }

    if (-not (Test-Path ".git")) {
        git init
    }

    if (-not (git rev-parse HEAD 2>$null)) {
        git add -A
        git -c user.name="CustomProfile" -c user.email="customprofile@local" commit -m "Initial release of CustomProfile Vencord userplugin."
    }

    $remote = git remote get-url origin 2>$null
    if (-not $remote) {
        Write-Host "Creating GitHub repo: $RepoName ($Visibility)..." -ForegroundColor Cyan
        gh repo create $RepoName --$Visibility --source=. --remote=origin --push
    }
    else {
        Write-Host "Remote already set: $remote" -ForegroundColor Cyan
        Write-Host "Pushing latest changes..."
        git push -u origin HEAD
    }

    $url = gh repo view --json url -q .url
    Write-Host ""
    Write-Host "Done! Repo URL:" -ForegroundColor Green
    Write-Host $url
    Write-Host ""
    Write-Host "Share this one-liner with friends (easiest):"
    $user = gh api user -q .login
    $branch = git branch --show-current
    if (-not $branch) { $branch = "master" }
    Write-Host "irm https://raw.githubusercontent.com/$user/$RepoName/$branch/install-easy.ps1 | iex"
    Write-Host "powershell -NoProfile -ExecutionPolicy Bypass -Command `"iex (irm 'https://raw.githubusercontent.com/$user/$RepoName/$branch/install-easy.ps1')`"" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Or link them to INSTALL-FRIEND.md on GitHub."
}
finally {
    Pop-Location
}
