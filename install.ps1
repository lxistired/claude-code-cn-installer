# ============================================================================
# Claude Code 一键安装脚本 (Windows)
# 面向中国用户 - 支持国产大模型 API
# ============================================================================

# 要求以管理员权限运行
#Requires -RunAsAdministrator

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
Write-Host "    5. 配置国产大模型 API (DeepSeek/Qwen/GLM/Kimi/ERNIE)" -ForegroundColor White
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
# 步骤 5: 配置国产大模型 API
# ---------------------------------------------------------------------------
Write-Step "步骤 5/5: 配置国产大模型 API"

Write-Host ""
Write-Host "  ================================================================" -ForegroundColor Yellow
Write-Host "   由于网络限制，中国用户无法直接使用 Anthropic Claude API" -ForegroundColor Yellow
Write-Host "   您需要配置一个兼容 OpenAI 格式的国产大模型 API" -ForegroundColor Yellow
Write-Host "  ================================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "  请选择您要使用的 API 提供商:" -ForegroundColor White
Write-Host ""
Write-Host "    [1] 智谱 GLM (glm-5 旗舰)       - https://open.bigmodel.cn" -ForegroundColor White
Write-Host "    [2] DeepSeek (V3.2 最新)        - https://platform.deepseek.com" -ForegroundColor White
Write-Host "    [3] 月之暗面 Kimi (K2.5 旗舰)   - https://platform.moonshot.cn" -ForegroundColor White
Write-Host "    [4] 阿里通义千问 (Qwen3.5 最新) - https://dashscope.aliyuncs.com" -ForegroundColor White
Write-Host "    [5] 百度文心 ERNIE (4.5 旗舰)   - https://qianfan.baidubce.com" -ForegroundColor White
Write-Host "    [6] OpenAI 兼容的其他接口 (自定义)" -ForegroundColor White
Write-Host "    [7] 暂时跳过，稍后手动配置" -ForegroundColor White
Write-Host ""

$providerChoice = Read-Host "  请输入选项编号 (1-7)"

# 定义各提供商的配置信息
$providers = @{
    "1" = @{
        Name       = "智谱 GLM"
        BaseUrl    = "https://open.bigmodel.cn/api/paas/v4"
        Model      = "glm-5"
        KeyName    = "GLM API Key"
        GetKeyUrl  = "https://open.bigmodel.cn/usercenter/apikeys"
        GetKeyHelp = @"
  获取 API Key 的步骤:
    1. 打开浏览器访问 https://open.bigmodel.cn
    2. 注册/登录您的账号
    3. 点击右上角头像 -> 'API 密钥'
    4. 点击 '创建 API Key'
    5. 复制生成的 Key
"@
        Models     = @("glm-5", "glm-4.7", "glm-4.5", "glm-4.7-flash", "glm-4-flash")
        ModelDescs = @("旗舰模型 745B MoE，最强", "编程增强 SWE-bench 73.8", "Agent基座，工具调用优化", "30B MoE 轻量快速", "免费模型")
    }
    "2" = @{
        Name       = "DeepSeek"
        BaseUrl    = "https://api.deepseek.com"
        Model      = "deepseek-chat"
        KeyName    = "DeepSeek API Key"
        GetKeyUrl  = "https://platform.deepseek.com/api_keys"
        GetKeyHelp = @"
  获取 API Key 的步骤:
    1. 打开浏览器访问 https://platform.deepseek.com
    2. 注册/登录您的账号
    3. 进入 'API Keys' 页面
    4. 点击 '创建 API Key'
    5. 复制生成的 Key
"@
        Models     = @("deepseek-chat", "deepseek-reasoner")
        ModelDescs = @("V3.2 通用对话+工具调用，最强", "V3.2 深度推理/数学/代码")
    }
    "3" = @{
        Name       = "月之暗面 (Kimi)"
        BaseUrl    = "https://api.moonshot.cn/v1"
        Model      = "kimi-k2.5"
        KeyName    = "Kimi API Key"
        GetKeyUrl  = "https://platform.moonshot.cn/console/api-keys"
        GetKeyHelp = @"
  获取 API Key 的步骤:
    1. 打开浏览器访问 https://platform.moonshot.cn
    2. 注册/登录您的账号
    3. 进入控制台 -> 'API Key 管理'
    4. 点击 '新建 API Key'
    5. 复制生成的 Key
"@
        Models     = @("kimi-k2.5", "kimi-k2", "moonshot-v1-128k", "moonshot-v1-32k")
        ModelDescs = @("最新旗舰 1T MoE 多模态+Agent", "K2 推理增强 256K上下文", "经典长文本 128K", "经典 32K")
    }
    "4" = @{
        Name       = "阿里通义千问 (Qwen)"
        BaseUrl    = "https://dashscope.aliyuncs.com/compatible-mode/v1"
        Model      = "qwen3.5-plus"
        KeyName    = "DashScope API Key"
        GetKeyUrl  = "https://dashscope.console.aliyun.com/apiKey"
        GetKeyHelp = @"
  获取 API Key 的步骤:
    1. 打开浏览器访问 https://dashscope.console.aliyun.com
    2. 注册/登录您的阿里云账号
    3. 开通 DashScope 服务
    4. 进入 'API-KEY 管理'
    5. 点击 '创建新的 API-KEY'
    6. 复制生成的 Key
"@
        Models     = @("qwen3.5-plus", "qwen3-max", "qwq-plus", "qwen-plus", "qwen-turbo")
        ModelDescs = @("最新旗舰 397B MoE，最强", "Qwen3 旗舰，万亿参数", "深度推理模型", "性价比之选", "轻量快速低成本")
    }
    "5" = @{
        Name       = "百度文心 (ERNIE)"
        BaseUrl    = "https://qianfan.baidubce.com/v2"
        Model      = "ernie-4.5"
        KeyName    = "千帆 API Key"
        GetKeyUrl  = "https://console.bce.baidu.com/qianfan/ais/console/applicationConsole/application"
        GetKeyHelp = @"
  获取 API Key 的步骤:
    1. 打开浏览器访问 https://qianfan.baidubce.com
    2. 注册/登录您的百度智能云账号
    3. 创建应用，获取 API Key 和 Secret Key
    4. 复制 API Key
"@
        Models     = @("ernie-4.5", "ernie-4.5-turbo", "ernie-4.0-turbo", "ernie-3.5")
        ModelDescs = @("最新旗舰 300B MoE，最强", "快速版 128K上下文", "4.0 系列快速版", "经济实惠")
    }
}

if ($providerChoice -ge "1" -and $providerChoice -le "5") {
    $provider = $providers[$providerChoice]
    Write-Host ""
    Write-Info "您选择了: $($provider.Name)"
    Write-Host ""
    Write-Host $provider.GetKeyHelp -ForegroundColor Cyan
    Write-Host ""

    # 提示打开浏览器
    $openBrowser = Read-Host "  是否打开浏览器获取 API Key? (Y/n)"
    if ($openBrowser -ne 'n' -and $openBrowser -ne 'N') {
        Start-Process $provider.GetKeyUrl
        Write-Info "已打开浏览器，请获取您的 API Key"
        Write-Host ""
    }

    # 获取 API Key
    $apiKey = Read-Host "  请输入您的 $($provider.KeyName)"

    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        Write-Warn "未输入 API Key，跳过配置"
        Write-Warn "您可以稍后运行 configure-api.ps1 进行配置"
    }
    else {
        # 选择模型
        Write-Host ""
        Write-Host "  可用模型:" -ForegroundColor White
        for ($i = 0; $i -lt $provider.Models.Count; $i++) {
            $defaultTag = if ($i -eq 0) { " (推荐)" } else { "" }
            $desc = ""
            if ($provider.ModelDescs -and $i -lt $provider.ModelDescs.Count) {
                $desc = " - $($provider.ModelDescs[$i])"
            }
            Write-Host "    [$($i+1)] $($provider.Models[$i])$desc$defaultTag" -ForegroundColor White
        }
        Write-Host ""
        $modelChoice = Read-Host "  请选择模型编号 (默认 1)"
        if ([string]::IsNullOrWhiteSpace($modelChoice)) { $modelChoice = "1" }
        $modelIndex = [int]$modelChoice - 1
        if ($modelIndex -lt 0 -or $modelIndex -ge $provider.Models.Count) { $modelIndex = 0 }
        $selectedModel = $provider.Models[$modelIndex]

        # 写入环境变量
        Write-Info "正在配置环境变量..."

        # ANTHROPIC_BASE_URL - Claude Code 使用的基础 URL
        [System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $provider.BaseUrl, "User")
        $env:ANTHROPIC_BASE_URL = $provider.BaseUrl

        # API Key - 设置多种格式以确保兼容性
        [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $apiKey, "User")
        $env:ANTHROPIC_API_KEY = $apiKey

        # OpenAI 兼容格式 (部分提供商需要)
        [System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", $apiKey, "User")
        $env:OPENAI_API_KEY = $apiKey
        [System.Environment]::SetEnvironmentVariable("OPENAI_BASE_URL", $provider.BaseUrl, "User")
        $env:OPENAI_BASE_URL = $provider.BaseUrl

        # 模型配置
        [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_USE_OPENAI", "1", "User")
        $env:CLAUDE_CODE_USE_OPENAI = "1"
        [System.Environment]::SetEnvironmentVariable("CLAUDE_MODEL", $selectedModel, "User")
        $env:CLAUDE_MODEL = $selectedModel

        Write-Info "环境变量配置完成:"
        Write-Host "    ANTHROPIC_BASE_URL = $($provider.BaseUrl)" -ForegroundColor Gray
        Write-Host "    ANTHROPIC_API_KEY  = $($apiKey.Substring(0, [Math]::Min(8, $apiKey.Length)))****" -ForegroundColor Gray
        Write-Host "    OPENAI_BASE_URL    = $($provider.BaseUrl)" -ForegroundColor Gray
        Write-Host "    CLAUDE_MODEL       = $selectedModel" -ForegroundColor Gray

        # 创建 Claude Code 配置文件
        $claudeConfigDir = "$env:USERPROFILE\.claude"
        if (-not (Test-Path $claudeConfigDir)) {
            New-Item -ItemType Directory -Path $claudeConfigDir -Force | Out-Null
        }

        # 写入 settings 文件
        $settingsContent = @"
{
  "apiProvider": "third-party",
  "apiBaseUrl": "$($provider.BaseUrl)",
  "model": "$selectedModel",
  "apiKeySource": "env:ANTHROPIC_API_KEY"
}
"@
        $settingsContent | Out-File -FilePath "$claudeConfigDir\settings.json" -Encoding UTF8 -Force
        Write-Info "Claude Code 配置文件已写入: $claudeConfigDir\settings.json"
    }
}
elseif ($providerChoice -eq "6") {
    # 自定义 API 配置
    Write-Host ""
    Write-Info "自定义 OpenAI 兼容接口配置"
    Write-Host ""

    $customBaseUrl = Read-Host "  请输入 API Base URL (例如: https://api.example.com/v1)"
    $customApiKey  = Read-Host "  请输入 API Key"
    $customModel   = Read-Host "  请输入模型名称 (例如: gpt-4)"

    if (-not [string]::IsNullOrWhiteSpace($customBaseUrl) -and -not [string]::IsNullOrWhiteSpace($customApiKey)) {
        [System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $customBaseUrl, "User")
        [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $customApiKey, "User")
        [System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", $customApiKey, "User")
        [System.Environment]::SetEnvironmentVariable("OPENAI_BASE_URL", $customBaseUrl, "User")
        [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_USE_OPENAI", "1", "User")

        if (-not [string]::IsNullOrWhiteSpace($customModel)) {
            [System.Environment]::SetEnvironmentVariable("CLAUDE_MODEL", $customModel, "User")
        }

        Write-Info "自定义 API 配置完成"
    }
    else {
        Write-Warn "配置信息不完整，跳过"
    }
}
else {
    Write-Info "跳过 API 配置"
    Write-Info "您可以稍后运行 configure-api.ps1 或手动设置环境变量"
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
