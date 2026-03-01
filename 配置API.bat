@echo off
chcp 65001 >nul 2>&1
title Claude Code API 配置工具

echo.
echo  ================================================================
echo       Claude Code API 配置工具
echo  ================================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0configure-api.ps1"
pause
