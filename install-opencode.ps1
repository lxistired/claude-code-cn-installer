# ============================================================================
# OpenCode 一键安装脚本 (Windows)
# 面向中国用户 - 接入智谱 GLM Coding Plan
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
$NPM_MIRROR       = "https://registry.npmmirror.com"
$INSTALL_LOG      = "$env:TEMP\opencode-install.log"

# 智谱 GLM 配置
$GLM_CODING_API   = "https://open.bigmodel.cn/api/coding/paas/v4"
$GLM_GENERAL_API  = "https://open.bigmodel.cn/api/paas/v4"
$GLM_REGISTER_URL = "https://open.bigmodel.cn"
$GLM_APIKEY_URL   = "https://open.bigmodel.cn/usercenter/apikeys"
$GLM_CODING_URL   = "https://open.bigmodel.cn/glm-coding"

# 可用模型列表
$GLM_MODELS = @(
    @{ Id = "glm-5";        Name = "GLM-5";        Desc = "旗舰 745B MoE，最强（对标 Claude Opus）"; Context = 128000; Output = 65536; Default = $true }
    @{ Id = "glm-4.7";      Name = "GLM-4.7";      Desc = "编程增强，SWE-bench 73.8（对标 Sonnet）"; Context = 128000; Output = 128000; Default = $false }
    @{ Id = "glm-4.5";      Name = "GLM-4.5";      Desc = "Agent 基座，工具调用优化"; Context = 128000; Output = 16384; Default = $false }
    @{ Id = "glm-4.7-flash"; Name = "GLM-4.7-Flash"; Desc = "30B MoE 轻量快速（对标 Haiku）"; Context = 128000; Output = 16384; Default = $false }
    @{ Id = "glm-4-flash";  Name = "GLM-4-Flash";  Desc = "免费模型，轻量任务"; Context = 128000; Output = 4096; Default = $false }
)

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
Write-Host "       OpenCode 一键安装工具 (Windows 中国版)" -ForegroundColor Magenta
Write-Host "       接入智谱 GLM Coding Plan - 无需翻墙" -ForegroundColor Magenta
Write-Host "  ================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  本工具将自动完成以下操作:" -ForegroundColor White
Write-Host "    1. 安装 Node.js     (使用国内镜像)" -ForegroundColor White
Write-Host "    2. 配置 npm 国内镜像源" -ForegroundColor White
Write-Host "    3. 安装 OpenCode    (通过 npm)" -ForegroundColor White
Write-Host "    4. 配置智谱 GLM API (选择模型 + 填写 API Key)" -ForegroundColor White
Write-Host ""
Write-Host "  安装完成后即可直接使用，开箱即用！" -ForegroundColor Yellow
Write-Host ""
Write-Host "  注意: 本脚本需要以 管理员身份 运行" -ForegroundColor Yellow
Write-Host ""

$confirm = Read-Host "  按 Enter 继续安装，输入 Q 退出"
if ($confirm -eq 'Q' -or $confirm -eq 'q') {
    Write-Host "  安装已取消。" -ForegroundColor Yellow
    exit 0
}

# 初始化日志
"[$(Get-Date)] OpenCode 安装开始" | Out-File -FilePath $INSTALL_LOG -Encoding UTF8

# ---------------------------------------------------------------------------
# 步骤 1: 安装 Node.js
# ---------------------------------------------------------------------------
Write-Step "步骤 1/4: 检查 Node.js"

$skipNode = $false
if (Test-CommandExists "node") {
    $nodeVer = & node --version 2>$null
    Write-Info "Node.js 已安装: $nodeVer"

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
        Write-Info "正在安装 Node.js (静默安装，请稍候)..."
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$nodeMsi`" /qn /norestart" -Wait -PassThru
        if ($process.ExitCode -eq 0) {
            Write-Info "Node.js 安装成功"
        }
        else {
            Write-Err "Node.js 安装失败 (退出代码: $($process.ExitCode))"
            Write-Err "请手动下载安装: https://npmmirror.com/mirrors/node/"
            Write-Host ""
            Read-Host "  按 Enter 键退出"
            exit 1
        }
        Remove-Item -Path $nodeMsi -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-Err "Node.js 下载失败，无法继续安装"
        Read-Host "  按 Enter 键退出"
        exit 1
    }

    Refresh-Path
}

# ---------------------------------------------------------------------------
# 步骤 2: 配置 npm 镜像源
# ---------------------------------------------------------------------------
Write-Step "步骤 2/4: 配置 npm 国内镜像源"

if (Test-CommandExists "npm") {
    Write-Info "设置 npm 镜像源为: $NPM_MIRROR"
    & npm config set registry $NPM_MIRROR 2>$null
    Write-Info "npm 镜像源配置完成"

    $currentRegistry = & npm config get registry 2>$null
    Write-Info "当前 npm 镜像源: $currentRegistry"
}
else {
    Write-Err "npm 未找到，请确保 Node.js 安装成功后重试"
    Write-Err "您可以关闭此窗口，重新以管理员身份运行安装程序"
    Read-Host "  按 Enter 键退出"
    exit 1
}

# ---------------------------------------------------------------------------
# 步骤 3: 安装 OpenCode
# ---------------------------------------------------------------------------
Write-Step "步骤 3/4: 安装 OpenCode"

if (Test-CommandExists "npm") {
    Write-Info "正在通过 npm 安装 OpenCode ..."
    Write-Info "（使用国内镜像源，请耐心等待）"

    try {
        & npm install -g opencode-ai@latest 2>&1 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
        Refresh-Path

        if (Test-CommandExists "opencode") {
            Write-Info "OpenCode 安装成功!"
        }
        else {
            Write-Warn "opencode 命令未立即生效，可能需要重启终端"
            Write-Info "安装完成后请打开新的 PowerShell 窗口运行 'opencode' 命令"
        }
    }
    catch {
        Write-Err "OpenCode 安装失败: $_"
        Write-Err "请手动运行: npm install -g opencode-ai@latest"
    }
}
else {
    Write-Err "npm 不可用，无法安装 OpenCode"
    Read-Host "  按 Enter 键退出"
    exit 1
}

# ---------------------------------------------------------------------------
# 步骤 4: 配置智谱 GLM API
# ---------------------------------------------------------------------------
Write-Step "步骤 4/4: 配置智谱 GLM API"

Write-Host ""
Write-Host "  ================================================================" -ForegroundColor Yellow
Write-Host "   配置智谱 GLM API，让 OpenCode 使用国产大模型" -ForegroundColor Yellow
Write-Host "  ================================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  智谱 GLM 提供与 OpenCode 完全兼容的 API" -ForegroundColor White
Write-Host "  无需翻墙，国内直连！" -ForegroundColor White
Write-Host ""
Write-Host "  首先，您需要获取 API Key:" -ForegroundColor Cyan
Write-Host "    1. 打开 $GLM_REGISTER_URL 注册账号" -ForegroundColor White
Write-Host "    2. 购买 GLM Coding Plan: $GLM_CODING_URL" -ForegroundColor White
Write-Host "    3. 获取 API Key: 右上角头像 -> API 密钥 -> 创建" -ForegroundColor White
Write-Host ""

# 选择模型
Write-Host "  请选择默认模型:" -ForegroundColor White
Write-Host ""
for ($i = 0; $i -lt $GLM_MODELS.Count; $i++) {
    $m = $GLM_MODELS[$i]
    $tag = if ($m.Default) { " ← 推荐" } else { "" }
    Write-Host "    [$($i+1)] $($m.Name)  - $($m.Desc)$tag" -ForegroundColor White
}
Write-Host "    [$($GLM_MODELS.Count + 1)] 暂时跳过，稍后手动配置" -ForegroundColor White
Write-Host ""

$modelChoice = Read-Host "  请输入选项编号 (默认 1)"
if ([string]::IsNullOrWhiteSpace($modelChoice)) { $modelChoice = "1" }

$modelIdx = 0
try { $modelIdx = [int]$modelChoice - 1 } catch { $modelIdx = 0 }

if ($modelIdx -ge 0 -and $modelIdx -lt $GLM_MODELS.Count) {
    $selectedModel = $GLM_MODELS[$modelIdx]

    Write-Host ""
    Write-Host "  已选择模型: $($selectedModel.Name) - $($selectedModel.Desc)" -ForegroundColor Green
    Write-Host ""

    # 打开浏览器获取 API Key
    $openBrowser = Read-Host "  是否打开浏览器获取 API Key? (Y/n)"
    if ($openBrowser -ne 'n' -and $openBrowser -ne 'N') {
        Start-Process $GLM_APIKEY_URL
        Write-Info "已打开浏览器，请在智谱平台获取 API Key"
        Write-Host ""
    }

    $apiKey = Read-Host "  请输入您的智谱 API Key"

    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Warn "未输入 API Key，跳过配置"
        Write-Warn "您可以稍后运行「配置智谱API.bat」进行配置"
    }
    else {
        # 选择 API 端点类型
        Write-Host ""
        Write-Host "  请选择 API 类型:" -ForegroundColor White
        Write-Host "    [1] GLM Coding Plan (订阅套餐，性价比高) ← 推荐" -ForegroundColor White
        Write-Host "    [2] 通用 API (按量计费)" -ForegroundColor White
        Write-Host ""
        $apiTypeChoice = Read-Host "  请选择 (默认 1)"
        if ([string]::IsNullOrWhiteSpace($apiTypeChoice)) { $apiTypeChoice = "1" }

        $baseUrl = if ($apiTypeChoice -eq "2") { $GLM_GENERAL_API } else { $GLM_CODING_API }

        # 生成 opencode.json 配置文件
        $configDir = "$env:USERPROFILE\.config\opencode"
        if (-not (Test-Path $configDir)) {
            New-Item -ItemType Directory -Path $configDir -Force | Out-Null
        }

        $modelId = $selectedModel.Id
        $configObj = [ordered]@{
            '$schema'  = "https://opencode.ai/config.json"
            provider = [ordered]@{
                zhipu = [ordered]@{
                    npm     = "@ai-sdk/openai-compatible"
                    name    = "Zhipu AI"
                    options = [ordered]@{
                        baseURL = $baseUrl
                        apiKey  = $apiKey
                    }
                    models  = [ordered]@{
                        $modelId = [ordered]@{
                            name  = $selectedModel.Name
                            limit = [ordered]@{
                                context = $selectedModel.Context
                                output  = $selectedModel.Output
                            }
                        }
                    }
                }
            }
            model = "zhipu/$modelId"
        }

        # 如果选了 glm-5，同时添加 glm-4.7 作为备用
        if ($modelId -eq "glm-5") {
            $configObj.provider.zhipu.models["glm-4.7"] = [ordered]@{
                name  = "GLM-4.7"
                limit = [ordered]@{
                    context = 128000
                    output  = 128000
                }
            }
            $configObj.provider.zhipu.models["glm-4.7-flash"] = [ordered]@{
                name  = "GLM-4.7-Flash"
                limit = [ordered]@{
                    context = 128000
                    output  = 16384
                }
            }
        }

        $configJson = $configObj | ConvertTo-Json -Depth 10
        $configPath = "$configDir\opencode.json"
        $configJson | Out-File -FilePath $configPath -Encoding UTF8 -Force

        Write-Host ""
        Write-Info "配置完成!"
        Write-Host ""
        Write-Host "    API 端点    = $baseUrl" -ForegroundColor Gray
        Write-Host "    API Key     = $($apiKey.Substring(0, [Math]::Min(8, $apiKey.Length)))****" -ForegroundColor Gray
        Write-Host "    默认模型    = $($selectedModel.Name)" -ForegroundColor Gray
        Write-Host "    配置文件    = $configPath" -ForegroundColor Gray
        Write-Host ""
    }
}
else {
    Write-Info "跳过 API 配置"
    Write-Info "您可以稍后运行「配置智谱API.bat」或在 OpenCode 中使用 /connect 命令配置"
}

# ---------------------------------------------------------------------------
# 安装完成
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "  ================================================================" -ForegroundColor Green
Write-Host "       安装完成!  OpenCode 已就绪" -ForegroundColor Green
Write-Host "  ================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  使用方法:" -ForegroundColor White
Write-Host "    1. 打开一个 新的 PowerShell 或 CMD 窗口" -ForegroundColor White
Write-Host "    2. 切换到您的项目目录 (cd 您的项目路径)" -ForegroundColor White
Write-Host "    3. 运行命令: opencode" -ForegroundColor White
Write-Host ""
Write-Host "  常用命令:" -ForegroundColor White
Write-Host "    opencode             - 启动 OpenCode 交互界面" -ForegroundColor Gray
Write-Host "    opencode --help      - 查看帮助" -ForegroundColor Gray
Write-Host "    opencode --version   - 查看版本" -ForegroundColor Gray
Write-Host ""
Write-Host "  OpenCode 内部常用操作:" -ForegroundColor White
Write-Host "    /models              - 切换模型" -ForegroundColor Gray
Write-Host "    /connect             - 连接/切换 API 提供商" -ForegroundColor Gray
Write-Host "    /init                - 初始化项目 (生成 AGENTS.md)" -ForegroundColor Gray
Write-Host ""
Write-Host "  如需重新配置智谱 API:" -ForegroundColor White
Write-Host "    运行「配置智谱API.bat」" -ForegroundColor Gray
Write-Host ""
Write-Host "  安装日志: $INSTALL_LOG" -ForegroundColor Gray
Write-Host ""

# 检测安装结果
Write-Host "  安装状态检测:" -ForegroundColor White
Refresh-Path

if (Test-CommandExists "node") {
    Write-Host "    [OK] Node.js $(& node --version 2>$null)" -ForegroundColor Green
} else {
    Write-Host "    [!!] Node.js 未检测到 (请重启终端后再试)" -ForegroundColor Red
}

if (Test-CommandExists "opencode") {
    Write-Host "    [OK] OpenCode 已安装" -ForegroundColor Green
} else {
    Write-Host "    [!!] OpenCode 未检测到 (请重启终端后运行 'opencode')" -ForegroundColor Yellow
}

$configPath = "$env:USERPROFILE\.config\opencode\opencode.json"
if (Test-Path $configPath) {
    Write-Host "    [OK] 智谱 GLM 已配置" -ForegroundColor Green
} else {
    Write-Host "    [!!] API 未配置 (请运行「配置智谱API.bat」)" -ForegroundColor Yellow
}

Write-Host ""
Read-Host "  按 Enter 键退出安装程序"
