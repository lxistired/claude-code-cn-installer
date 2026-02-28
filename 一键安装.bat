@echo off
chcp 65001 >nul 2>&1
title Claude Code 一键安装工具

echo.
echo  ================================================================
echo       Claude Code 一键安装工具 (Windows 中国版)
echo  ================================================================
echo.
echo  本工具将以管理员权限运行安装脚本
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% == 0 (
    echo  [信息] 已拥有管理员权限
    echo.
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
    pause
) else (
    echo  [信息] 正在请求管理员权限...
    echo.
    powershell -Command "Start-Process powershell -ArgumentList '-NoExit -NoProfile -ExecutionPolicy Bypass -File \"%~dp0install.ps1\"' -Verb RunAs"
)
