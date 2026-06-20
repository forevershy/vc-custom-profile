@echo off
title CustomProfile Installer
cd /d "%~dp0"

echo.
echo  CustomProfile - Vencord plugin installer
echo  This may take a few minutes the first time.
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
if errorlevel 1 (
    echo.
    echo  Install failed. Read the messages above and try again.
    echo.
)

pause
