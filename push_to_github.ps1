<#
.SYNOPSIS
    Automated GitHub push script for AgriInsight Platform
.DESCRIPTION
    Initializes git, stages all files, commits with a professional message,
    configures the GitHub remote origin, and pushes to the main branch.
.PARAMETER RepoUrl
    Optional GitHub repository remote URL (e.g., https://github.com/username/AgriInsight.git)
#>

param (
    [string]$RepoUrl = ""
)

Write-Host "===============================================================================" -ForegroundColor Green
Write-Host "               AGRIINSIGHT: GITHUB REPOSITORY PUSH AUTOMATION                  " -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Green
Write-Host ""

# 1. Verify Git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "[ERROR] Git is not installed or not in system PATH." -ForegroundColor Red
    Write-Host "Please install Git from https://git-scm.com/ and try again." -ForegroundColor Yellow
    exit 1
}

# 2. Check Git Repo
Write-Host "[1/5] Checking Git repository initialization..." -ForegroundColor Cyan
if (-not (Test-Path ".git")) {
    git init
    git branch -M main
    Write-Host "Initialized empty repository on branch 'main'." -ForegroundColor Green
} else {
    git branch -M main
    Write-Host "Repository verified on branch 'main'." -ForegroundColor Green
}

# 3. Stage Files
Write-Host "`n[2/5] Staging files..." -ForegroundColor Cyan
git add .
Write-Host "All project files staged." -ForegroundColor Green

# 4. Commit
Write-Host "`n[3/5] Committing changes..." -ForegroundColor Cyan
git commit -m "feat: Initial release of AgriInsight Agricultural Yield & Productivity Analytics Platform"
if ($LASTEXITCODE -eq 0) {
    Write-Host "Commit created successfully." -ForegroundColor Green
} else {
    Write-Host "No changes to commit or working tree clean." -ForegroundColor Yellow
}

# 5. Remote Configuration
Write-Host "`n[4/5] Checking GitHub Remote Origin..." -ForegroundColor Cyan
$existingRemote = git remote get-url origin 2>$null

if (-not $existingRemote) {
    if (-not $RepoUrl) {
        Write-Host "No remote origin configured yet." -ForegroundColor Yellow
        Write-Host "Create a new repository on GitHub: https://github.com/new" -ForegroundColor Cyan
        $RepoUrl = Read-Host "Enter your GitHub Repository URL (e.g. https://github.com/username/AgriInsight.git)"
    }
    
    if ($RepoUrl) {
        git remote add origin $RepoUrl
        Write-Host "Remote origin added: $RepoUrl" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] No remote URL provided. Commit created locally. Push skipped." -ForegroundColor Yellow
        exit 0
    }
} else {
    Write-Host "Current remote origin: $existingRemote" -ForegroundColor Green
    if ($RepoUrl -and ($RepoUrl -ne $existingRemote)) {
        git remote set-url origin $RepoUrl
        Write-Host "Updated remote origin to: $RepoUrl" -ForegroundColor Green
    }
}

# 6. Push
Write-Host "`n[5/5] Pushing branch 'main' to GitHub origin..." -ForegroundColor Cyan
git push -u origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n===============================================================================" -ForegroundColor Green
    Write-Host "[SUCCESS] AgriInsight platform successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "===============================================================================" -ForegroundColor Green
} else {
    Write-Host "`n[NOTICE] Push did not complete directly." -ForegroundColor Yellow
    Write-Host "If your GitHub repository was created with a README or License file, run:" -ForegroundColor Cyan
    Write-Host "    git pull origin main --rebase" -ForegroundColor White
    Write-Host "    git push -u origin main" -ForegroundColor White
}
