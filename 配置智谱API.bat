@echo off
chcp 65001 >nul 2>&1
title OpenCode 智谱 GLM API 配置工具

echo.
echo  ================================================================
echo       OpenCode 智谱 GLM API 配置工具
echo  ================================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0configure-glm.ps1"
pause
