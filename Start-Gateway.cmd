@echo off
setlocal
cd /d "%~dp0"
title CodeBuddy Gateway - close this window to stop
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Gateway.ps1"
if errorlevel 1 pause
endlocal
