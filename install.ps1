# ============================================================================
# Claude Code 一键安装脚本 (Windows)
# 面向中国用户 - 支持国产大模型 API
# ============================================================================

# 要求以管理员权限运行
#Requires -RunAsAdministrator

# Ensure UTF-8 output in both GBK and UTF-8 consoles
chcp 65001 | Out-Null
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ---------------------------------------------------------------------------
# 全局配置
# ---------------------------------------------------------------------------
$NODEJS_VERSION   = "22.13.1"    # LTS 版本
$NODEJS_URL       = "https://npmmirror.com/mirrors/node/v${NODEJS_VERSION}/node-v${NODEJS_VERSION}-x64.msi"
$GIT_VERSION      = "2.47.1"
$GIT_URL          = "https://registry.npmmirror.com/-/binary/git-for-windows/v${GIT_VERSION}.windows.1/Git-${GIT_VERSION}-64-bit.exe"
$NPM_MIRROR       = "https://registry.npmmirror.com"
$INSTALL_LOG      = "$env:TEMP\claude-code-install.log"

# ---------------------------------------------------------------------------
# 辅助函数
# ---------------------------------------------------------------------------
function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "  $Message" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Add-Content -Path $INSTALL_LOG -Value "[$(Get-Date)] $Message"
}

function Write-Info {
    param([string]$Message)
    Write-Host "  [信息] $Message" -ForegroundColor Green
    Add-Content -Path $INSTALL_LOG -Value "[$(Get-Date)] INFO: $Message"
}

function Write-Warn {
    param([string]$Message)
    Write-Host "  [警告] $Message" -ForegroundColor Yellow
    Add-Content -Path $INSTALL_LOG -Value "[$(Get-Date)] WARN: $Message"
}

function Write-Err {
    param([string]$Message)
    Write-Host "  [错误] $Message" -ForegroundColor Red
    Add-Content -Path $INSTALL_LOG -Value "[$(Get-Date)] ERROR: $Message"
}

function Refresh-Path {
    # 刷新当前会话的 PATH 变量
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath    = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path    = "$machinePath;$userPath"
}

function Test-CommandExists {
    param([string]$Command)
    $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
}

function Download-File {
    param(
        [string]$Url,
        [string]$OutFile,
        [string]$Description
    )
    Write-Info "正在下载 $Description ..."
    Write-Info "下载地址: $Url"

    # 使用 BITS 或 WebClient 下载，更适合中国网络环境
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $Url -OutFile $OutFile -UseBasicParsing -TimeoutSec 300
        $ProgressPreference = 'Continue'
        Write-Info "$Description 下载完成"
    }
    catch {
        Write-Warn "Invoke-WebRequest 下载失败，尝试使用 WebClient ..."
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($Url, $OutFile)
            Write-Info "$Description 下载完成 (WebClient)"
        }
        catch {
            Write-Err "$Description 下载失败: $_"
            Write-Err "请手动下载: $Url"
            return $false
        }
    }
    return $true
}

# ---------------------------------------------------------------------------
# 欢迎界面
# ---------------------------------------------------------------------------
Clear-Host
Write-Host ""
Write-Host "  ================================================================" -ForegroundColor Magenta
Write-Host "       Claude Code 一键安装工具 (Windows 中国版)" -ForegroundColor Magenta
Write-Host "  ================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  本工具将自动完成以下操作:" -ForegroundColor White
Write-Host "    1. 检查并安装 Node.js (使用国内镜像)" -ForegroundColor White
Write-Host "    2. 检查并安装 Git     (使用国内镜像)" -ForegroundColor White
Write-Host "    3. 配置 npm 国内镜像源" -ForegroundColor White
Write-Host "    4. 安装 Claude Code (npm)" -ForegroundColor White
Write-Host "    5. 配置智谱 GLM API" -ForegroundColor White
Write-Host ""
Write-Host "  注意: 本脚本需要以 管理员身份 运行" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "  按 Enter 继续安装，输入 Q 退出"
if ($confirm -eq 'Q' -or $confirm -eq 'q') {
    Write-Host "  安装已取消。" -ForegroundColor Yellow
    exit 0
}

# 初始化日志
"[$(Get-Date)] Claude Code 安装开始" | Out-File -FilePath $INSTALL_LOG -Encoding UTF8

# ---------------------------------------------------------------------------
# 步骤 1: 安装 Node.js
# ---------------------------------------------------------------------------
Write-Step "步骤 1/5: 检查 Node.js"

if (Test-CommandExists "node") {
    $nodeVer = & node --version 2>$null
    Write-Info "Node.js 已安装: $nodeVer"

    # 检查版本是否 >= 18
    $majorVersion = [int]($nodeVer -replace 'v(\d+)\..*', '$1')
    if ($majorVersion -lt 18) {
        Write-Warn "Node.js 版本过低 (需要 >= 18)，将升级..."
    }
    else {
        Write-Info "Node.js 版本满足要求，跳过安装"
        $skipNode = $true
    }
}

if (-not $skipNode) {
    $nodeMsi = "$env:TEMP\nodejs-installer.msi"
    $downloaded = Download-File -Url $NODEJS_URL -OutFile $nodeMsi -Description "Node.js v${NODEJS_VERSION}"

    if ($downloaded) {
        Write-Info "正在安装 Node.js (静默安装)..."
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$nodeMsi`" /qn /norestart" -Wait -PassThru
        if ($process.ExitCode -eq 0) {
            Write-Info "Node.js 安装成功"
        }
        else {
            Write-Err "Node.js 安装失败 (退出代码: $($process.ExitCode))"
            Write-Err "请手动下载安装: https://npmmirror.com/mirrors/node/"
        }
        Remove-Item -Path $nodeMsi -Force -ErrorAction SilentlyContinue
    }

    Refresh-Path
}

# ---------------------------------------------------------------------------
# 步骤 2: 安装 Git
# ---------------------------------------------------------------------------
Write-Step "步骤 2/5: 检查 Git"

if (Test-CommandExists "git") {
    $gitVer = & git --version 2>$null
    Write-Info "Git 已安装: $gitVer"
    Write-Info "跳过 Git 安装"
}
else {
    $gitExe = "$env:TEMP\git-installer.exe"
    $downloaded = Download-File -Url $GIT_URL -OutFile $gitExe -Description "Git v${GIT_VERSION}"

    if ($downloaded) {
        Write-Info "正在安装 Git (静默安装)..."
        $process = Start-Process -FilePath $gitExe -ArgumentList "/VERYSILENT /NORESTART /NOCANCEL /SP- /CLOSEAPPLICATIONS /RESTARTAPPLICATIONS /COMPONENTS=`"icons,ext\reg\shellhere,assoc,assoc_sh`"" -Wait -PassThru
        if ($process.ExitCode -eq 0) {
            Write-Info "Git 安装成功"
        }
        else {
            Write-Err "Git 安装失败 (退出代码: $($process.ExitCode))"
            Write-Err "请手动下载安装: https://registry.npmmirror.com/binary.html?path=git-for-windows/"
        }
        Remove-Item -Path $gitExe -Force -ErrorAction SilentlyContinue
    }

    Refresh-Path
}

# ---------------------------------------------------------------------------
# 步骤 3: 配置 npm 镜像源
# ---------------------------------------------------------------------------
Write-Step "步骤 3/5: 配置 npm 国内镜像源"

if (Test-CommandExists "npm") {
    Write-Info "设置 npm 镜像源为: $NPM_MIRROR"
    & npm config set registry $NPM_MIRROR
    Write-Info "npm 镜像源配置完成"

    # 验证配置
    $currentRegistry = & npm config get registry
    Write-Info "当前 npm 镜像源: $currentRegistry"
}
else {
    Write-Err "npm 未找到，请确保 Node.js 安装成功后重试"
    Write-Err "您可以关闭此窗口，重新以管理员身份运行本安装程序"
}

# ---------------------------------------------------------------------------
# 步骤 4: 安装 Claude Code
# ---------------------------------------------------------------------------
Write-Step "步骤 4/5: 安装 Claude Code"

if (Test-CommandExists "npm") {
    Write-Info "正在通过 npm 安装 Claude Code ..."
    Write-Info "（使用国内镜像源，请耐心等待）"

    try {
        & npm install -g @anthropic-ai/claude-code 2>&1 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
        Refresh-Path

        if (Test-CommandExists "claude") {
            $claudeVer = & claude --version 2>$null
            Write-Info "Claude Code 安装成功: $claudeVer"
        }
        else {
            Write-Warn "claude 命令未找到，可能需要重启终端"
            Write-Info "安装完成后请打开新的 PowerShell 窗口运行 'claude' 命令"
        }
    }
    catch {
        Write-Err "Claude Code 安装失败: $_"
        Write-Err "请手动运行: npm install -g @anthropic-ai/claude-code"
    }
}
else {
    Write-Err "npm 不可用，无法安装 Claude Code"
}

# ---------------------------------------------------------------------------
# 步骤 5: 配置智谱 GLM API
# ---------------------------------------------------------------------------
Write-Step "步骤 5/5: 配置智谱 GLM API"

Write-Host ""
Write-Host "  ================================================================" -ForegroundColor Yellow
Write-Host "   配置智谱 GLM API，让 Claude Code 通过 GLM 模型运行" -ForegroundColor Yellow
Write-Host "  ================================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  获取 API Key: https://open.bigmodel.cn -> 右上角头像 -> API 密钥 -> 创建" -ForegroundColor Cyan
Write-Host ""
Write-Host "  可用模型:" -ForegroundColor White
Write-Host "    [1] glm-5        - 旗舰模型 745B MoE，最强（对标 Claude Opus）  ← 推荐" -ForegroundColor White
Write-Host "    [2] glm-4.7      - 编程增强 SWE-bench 73.8（对标 Claude Sonnet）" -ForegroundColor White
Write-Host "    [3] glm-4.5      - Agent 基座，工具调用优化" -ForegroundColor White
Write-Host "    [4] glm-4.7-flash - 30B MoE 轻量快速（对标 Claude Haiku）" -ForegroundColor White
Write-Host "    [5] glm-4-flash  - 免费模型，轻量任务" -ForegroundColor White
Write-Host "    [6] 暂时跳过，稍后手动配置" -ForegroundColor White
Write-Host ""

$glmModels = @("glm-5", "glm-4.7", "glm-4.5", "glm-4.7-flash", "glm-4-flash")
$providerChoice = Read-Host "  请输入选项编号 (1-6)"

if ($providerChoice -ge "1" -and $providerChoice -le "5") {
    Write-Host ""

    $openBrowser = Read-Host "  是否打开浏览器获取 API Key? (Y/n)"
    if ($openBrowser -ne 'n' -and $openBrowser -ne 'N') {
        Start-Process "https://open.bigmodel.cn/usercenter/apikeys"
        Write-Info "已打开浏览器，请获取您的 API Key"
        Write-Host ""
    }

    $apiKey = Read-Host "  请输入您的 GLM API Key"

    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Warn "未输入 API Key，跳过配置"
        Write-Warn "您可以稍后运行 configure-api.ps1 进行配置"
    }
    else {
        $modelIndex  = [int]$providerChoice - 1
        $opusModel   = $glmModels[$modelIndex]          # 用户选择的主力模型
        $sonnetModel = if ($modelIndex -le 1) { "glm-4.7" } else { $glmModels[$modelIndex] }
        $haikuModel  = "glm-4.5-air"

        # 智谱 GLM 专用 Anthropic 兼容端点
        $glmBaseUrl = "https://open.bigmodel.cn/api/anthropic"

        # 创建 Claude Code 配置文件（官方推荐方式：通过 env 字段做模型映射）
        $claudeConfigDir = "$env:USERPROFILE\.claude"
        if (-not (Test-Path $claudeConfigDir)) {
            New-Item -ItemType Directory -Path $claudeConfigDir -Force | Out-Null
        }

        $settingsObj = [ordered]@{
            env = [ordered]@{
                ANTHROPIC_BASE_URL             = $glmBaseUrl
                ANTHROPIC_API_KEY              = $apiKey
                ANTHROPIC_DEFAULT_HAIKU_MODEL  = $haikuModel
                ANTHROPIC_DEFAULT_SONNET_MODEL = $sonnetModel
                ANTHROPIC_DEFAULT_OPUS_MODEL   = $opusModel
            }
        }
        $settingsObj | ConvertTo-Json -Depth 5 | Out-File -FilePath "$claudeConfigDir\settings.json" -Encoding UTF8 -Force

        Write-Info "配置完成:"
        Write-Host "    ANTHROPIC_BASE_URL             = $glmBaseUrl" -ForegroundColor Gray
        Write-Host "    ANTHROPIC_API_KEY              = $($apiKey.Substring(0, [Math]::Min(8, $apiKey.Length)))****" -ForegroundColor Gray
        Write-Host "    ANTHROPIC_DEFAULT_OPUS_MODEL   = $opusModel" -ForegroundColor Gray
        Write-Host "    ANTHROPIC_DEFAULT_SONNET_MODEL = $sonnetModel" -ForegroundColor Gray
        Write-Host "    ANTHROPIC_DEFAULT_HAIKU_MODEL  = $haikuModel" -ForegroundColor Gray
        Write-Info "Claude Code 配置文件已写入: $claudeConfigDir\settings.json"
    }
}
else {
    Write-Info "跳过 API 配置"
    Write-Info "您可以稍后运行 configure-api.ps1 进行配置"
}

# ---------------------------------------------------------------------------
# 安装完成
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "  ================================================================" -ForegroundColor Green
Write-Host "       安装完成!" -ForegroundColor Green
Write-Host "  ================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  使用方法:" -ForegroundColor White
Write-Host "    1. 打开一个新的 PowerShell 或 CMD 窗口" -ForegroundColor White
Write-Host "    2. 切换到您的项目目录" -ForegroundColor White
Write-Host "    3. 运行命令: claude" -ForegroundColor White
Write-Host ""
Write-Host "  常用命令:" -ForegroundColor White
Write-Host "    claude              - 启动 Claude Code 交互模式" -ForegroundColor Gray
Write-Host "    claude --help       - 查看帮助信息" -ForegroundColor Gray
Write-Host "    claude --version    - 查看版本信息" -ForegroundColor Gray
Write-Host ""
Write-Host "  如需重新配置 API:" -ForegroundColor White
Write-Host "    运行 configure-api.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "  安装日志: $INSTALL_LOG" -ForegroundColor Gray
Write-Host ""

# 检测安装结果
Write-Host "  安装状态检测:" -ForegroundColor White

# 刷新 PATH
Refresh-Path

if (Test-CommandExists "node") {
    Write-Host "    [OK] Node.js $(& node --version 2>$null)" -ForegroundColor Green
} else {
    Write-Host "    [!!] Node.js 未检测到 (请重启终端后再试)" -ForegroundColor Red
}

if (Test-CommandExists "git") {
    Write-Host "    [OK] $(& git --version 2>$null)" -ForegroundColor Green
} else {
    Write-Host "    [!!] Git 未检测到 (请重启终端后再试)" -ForegroundColor Red
}

if (Test-CommandExists "claude") {
    Write-Host "    [OK] Claude Code 已安装" -ForegroundColor Green
} else {
    Write-Host "    [!!] Claude Code 未检测到 (请重启终端后运行 'claude')" -ForegroundColor Yellow
}

if ($env:ANTHROPIC_API_KEY -or $env:OPENAI_API_KEY) {
    Write-Host "    [OK] API Key 已配置" -ForegroundColor Green
} else {
    Write-Host "    [!!] API Key 未配置 (请运行 configure-api.ps1)" -ForegroundColor Yellow
}

Write-Host ""
Read-Host "  按 Enter 键退出安装程序"
