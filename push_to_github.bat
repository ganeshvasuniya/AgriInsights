@echo off
setlocal enabledelayedexpansion

echo ===============================================================================
echo                AGRIINSIGHT: GITHUB REPOSITORY PUSH SCRIPT
echo ===============================================================================
echo.

REM Verify Git is installed
where git >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Git is not installed or not in your system PATH.
    echo Please install Git from https://git-scm.com/ and try again.
    pause
    exit /b 1
)

REM Navigate to script directory
cd /d "%~dp0"

echo [1/5] Checking Git repository initialization...
if not exist ".git" (
    echo Initializing new Git repository...
    git init
    git branch -M main
) else (
    echo Git repository already initialized.
    git branch -M main
)
echo.

echo [2/5] Staging all project files...
git add .
echo Staging complete.
echo.

echo [3/5] Committing changes...
git commit -m "feat: Initial commit for AgriInsight Agricultural Yield & Productivity Analytics Platform"
if %ERRORLEVEL% equ 0 (
    echo Changes committed successfully.
) else (
    echo Working tree clean or commit already up to date.
)
echo.

echo [4/5] Checking GitHub Remote Origin...
git remote -v | findstr "origin" >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo No remote origin detected.
    echo Please create a new empty repository on GitHub (e.g., https://github.com/new).
    echo.
    set /p REPO_URL="Enter your GitHub Repository URL (e.g., https://github.com/username/AgriInsight.git): "
    if "!REPO_URL!"=="" (
        echo [ERROR] No repository URL provided. Aborting remote configuration.
        pause
        exit /b 1
    )
    git remote add origin !REPO_URL!
    echo Remote origin set to: !REPO_URL!
) else (
    echo Remote origin already configured:
    git remote -v
    echo.
    set /p UPDATE_REMOTE="Do you want to change the remote URL? (y/N): "
    if /i "!UPDATE_REMOTE!"=="y" (
        set /p REPO_URL="Enter new GitHub Repository URL: "
        git remote set-url origin !REPO_URL!
        echo Updated remote origin to: !REPO_URL!
    )
)
echo.

echo [5/5] Pushing to GitHub (main branch)...
git push -u origin main

if %ERRORLEVEL% equ 0 (
    echo.
    echo ===============================================================================
    echo [SUCCESS] AgriInsight repository successfully pushed to GitHub!
    echo ===============================================================================
) else (
    echo.
    echo [WARNING] Direct push failed. Attempting force push or pull resolution...
    echo If this is an existing remote repository with README/license, run:
    echo     git pull origin main --rebase
    echo     git push -u origin main
)

echo.
pause
