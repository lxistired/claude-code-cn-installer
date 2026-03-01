@echo off
set "SCRIPT_DIR=%~dp0"

net session >nul 2>&1
if %errorLevel% == 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%install-openwork.ps1"
    pause
    exit /b
)

powershell -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%SCRIPT_DIR%install-openwork.ps1\"' -Verb RunAs"
