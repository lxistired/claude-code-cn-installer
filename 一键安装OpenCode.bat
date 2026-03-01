@echo off
chcp 65001 >nul 2>&1
title OpenCode 一键安装工具

echo.
echo  ================================================================
echo       OpenCode 一键安装工具 (Windows 中国版)
echo       接入智谱 GLM - 无需翻墙，开箱即用
echo  ================================================================
echo.
echo  本工具将以管理员权限运行安装脚本
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% == 0 (
    echo  [信息] 已拥有管理员权限
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-opencode.ps1"
) else (
    echo  [信息] 正在请求管理员权限...
    echo.
    set "SCRIPT_DIR=%~dp0"
    powershell -Command "Start-Process cmd -ArgumentList '/c chcp 65001 >nul 2>&1 & powershell -NoProfile -ExecutionPolicy Bypass -File \"%SCRIPT_DIR%install-opencode.ps1\" & pause' -Verb RunAs"
)
pause
