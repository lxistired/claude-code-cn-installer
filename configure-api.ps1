# ============================================================================
# Claude Code API 配置工具
# 用于配置或更换国产大模型 API
# ============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Show-CurrentConfig {
    Write-Host ""
    Write-Host "  当前 API 配置:" -ForegroundColor Cyan
    Write-Host "  ────────────────────────────────────────" -ForegroundColor Gray

    $baseUrl  = [System.Environment]::GetEnvironmentVariable("ANTHROPIC_BASE_URL", "User")
    $apiKey   = [System.Environment]::GetEnvironmentVariable("ANTHROPIC_API_KEY", "User")
    $oaiKey   = [System.Environment]::GetEnvironmentVariable("OPENAI_API_KEY", "User")
    $oaiBase  = [System.Environment]::GetEnvironmentVariable("OPENAI_BASE_URL", "User")
    $model    = [System.Environment]::GetEnvironmentVariable("CLAUDE_MODEL", "User")
    $useOai   = [System.Environment]::GetEnvironmentVariable("CLAUDE_CODE_USE_OPENAI", "User")

    if ($baseUrl) {
        Write-Host "    ANTHROPIC_BASE_URL  = $baseUrl" -ForegroundColor White
    } else {
        Write-Host "    ANTHROPIC_BASE_URL  = (未设置)" -ForegroundColor DarkGray
    }

    if ($apiKey) {
        $masked = $apiKey.Substring(0, [Math]::Min(8, $apiKey.Length)) + "****"
        Write-Host "    ANTHROPIC_API_KEY   = $masked" -ForegroundColor White
    } else {
        Write-Host "    ANTHROPIC_API_KEY   = (未设置)" -ForegroundColor DarkGray
    }

    if ($oaiBase) {
        Write-Host "    OPENAI_BASE_URL     = $oaiBase" -ForegroundColor White
    }

    if ($oaiKey) {
        $masked = $oaiKey.Substring(0, [Math]::Min(8, $oaiKey.Length)) + "****"
        Write-Host "    OPENAI_API_KEY      = $masked" -ForegroundColor White
    }

    if ($model) {
        Write-Host "    CLAUDE_MODEL        = $model" -ForegroundColor White
    } else {
        Write-Host "    CLAUDE_MODEL        = (未设置)" -ForegroundColor DarkGray
    }

    if ($useOai) {
        Write-Host "    CLAUDE_CODE_USE_OPENAI = $useOai" -ForegroundColor White
    }

    Write-Host "  ────────────────────────────────────────" -ForegroundColor Gray
    Write-Host ""
}

function Set-ApiConfig {
    param(
        [string]$BaseUrl,
        [string]$ApiKey,
        [string]$Model
    )

    # 设置环境变量 (用户级别，永久生效)
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", $BaseUrl, "User")
    [System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", $ApiKey, "User")
    [System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", $ApiKey, "User")
    [System.Environment]::SetEnvironmentVariable("OPENAI_BASE_URL", $BaseUrl, "User")
    [System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_USE_OPENAI", "1", "User")
    [System.Environment]::SetEnvironmentVariable("CLAUDE_MODEL", $Model, "User")

    # 同时设置当前会话
    $env:ANTHROPIC_BASE_URL    = $BaseUrl
    $env:ANTHROPIC_API_KEY     = $ApiKey
    $env:OPENAI_API_KEY        = $ApiKey
    $env:OPENAI_BASE_URL       = $BaseUrl
    $env:CLAUDE_CODE_USE_OPENAI = "1"
    $env:CLAUDE_MODEL          = $Model

    # 更新 Claude Code 配置文件
    $claudeConfigDir = "$env:USERPROFILE\.claude"
    if (-not (Test-Path $claudeConfigDir)) {
        New-Item -ItemType Directory -Path $claudeConfigDir -Force | Out-Null
    }

    $settingsContent = @"
{
  "apiProvider": "third-party",
  "apiBaseUrl": "$BaseUrl",
  "model": "$Model",
  "apiKeySource": "env:ANTHROPIC_API_KEY"
}
"@
    $settingsContent | Out-File -FilePath "$claudeConfigDir\settings.json" -Encoding UTF8 -Force
}

function Clear-ApiConfig {
    $vars = @(
        "ANTHROPIC_BASE_URL",
        "ANTHROPIC_API_KEY",
        "OPENAI_API_KEY",
        "OPENAI_BASE_URL",
        "CLAUDE_CODE_USE_OPENAI",
        "CLAUDE_MODEL"
    )

    foreach ($var in $vars) {
        [System.Environment]::SetEnvironmentVariable($var, $null, "User")
        Remove-Item -Path "Env:\$var" -ErrorAction SilentlyContinue
    }

    # 删除配置文件
    $settingsPath = "$env:USERPROFILE\.claude\settings.json"
    if (Test-Path $settingsPath) {
        Remove-Item -Path $settingsPath -Force
    }

    Write-Host "  [信息] 所有 API 配置已清除" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# 提供商信息
# ---------------------------------------------------------------------------
$providers = @{
    "1" = @{
        Name       = "智谱 GLM"
        BaseUrl    = "https://open.bigmodel.cn/api/paas/v4"
        KeyUrl     = "https://open.bigmodel.cn/usercenter/apikeys"
        Models     = @("glm-5", "glm-4.7", "glm-4.5", "glm-4.7-flash", "glm-4-flash")
        ModelDescs = @("旗舰模型 745B MoE，最强", "编程增强 SWE-bench 73.8", "Agent基座，工具调用优化", "30B MoE 轻量快速", "免费模型")
        Help       = "注册地址: https://open.bigmodel.cn -> 右上角头像 -> API 密钥 -> 创建"
    }
    "2" = @{
        Name       = "DeepSeek"
        BaseUrl    = "https://api.deepseek.com"
        KeyUrl     = "https://platform.deepseek.com/api_keys"
        Models     = @("deepseek-chat", "deepseek-reasoner")
        ModelDescs = @("V3.2 通用对话+工具调用，最强", "V3.2 深度推理/数学/代码")
        Help       = "注册地址: https://platform.deepseek.com -> API Keys -> 创建"
    }
    "3" = @{
        Name       = "月之暗面 (Kimi)"
        BaseUrl    = "https://api.moonshot.cn/v1"
        KeyUrl     = "https://platform.moonshot.cn/console/api-keys"
        Models     = @("kimi-k2.5", "kimi-k2", "moonshot-v1-128k", "moonshot-v1-32k")
        ModelDescs = @("最新旗舰 1T MoE 多模态+Agent", "K2 推理增强 256K上下文", "经典长文本 128K", "经典 32K")
        Help       = "注册地址: https://platform.moonshot.cn -> 控制台 -> API Key 管理 -> 新建"
    }
    "4" = @{
        Name       = "阿里通义千问 (Qwen)"
        BaseUrl    = "https://dashscope.aliyuncs.com/compatible-mode/v1"
        KeyUrl     = "https://dashscope.console.aliyun.com/apiKey"
        Models     = @("qwen3.5-plus", "qwen3-max", "qwq-plus", "qwen-plus", "qwen-turbo")
        ModelDescs = @("最新旗舰 397B MoE，最强", "Qwen3 旗舰，万亿参数", "深度推理模型", "性价比之选", "轻量快速低成本")
        Help       = "注册地址: https://dashscope.console.aliyun.com -> API-KEY 管理 -> 创建"
    }
    "5" = @{
        Name       = "百度文心 (ERNIE)"
        BaseUrl    = "https://qianfan.baidubce.com/v2"
        KeyUrl     = "https://console.bce.baidu.com/qianfan/ais/console/applicationConsole/application"
        Models     = @("ernie-4.5", "ernie-4.5-turbo", "ernie-4.0-turbo", "ernie-3.5")
        ModelDescs = @("最新旗舰 300B MoE，最强", "快速版 128K上下文", "4.0 系列快速版", "经济实惠")
        Help       = "注册地址: https://qianfan.baidubce.com -> 创建应用 -> 获取 API Key"
    }
}

# ---------------------------------------------------------------------------
# 主菜单
# ---------------------------------------------------------------------------
while ($true) {
    Clear-Host
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Magenta
    Write-Host "       Claude Code API 配置工具" -ForegroundColor Magenta
    Write-Host "  ================================================================" -ForegroundColor Magenta

    Show-CurrentConfig

    Write-Host "  请选择操作:" -ForegroundColor White
    Write-Host "    [1] 配置 智谱 GLM      (glm-5 旗舰)" -ForegroundColor White
    Write-Host "    [2] 配置 DeepSeek       (V3.2 最新)" -ForegroundColor White
    Write-Host "    [3] 配置 月之暗面 Kimi   (K2.5 旗舰)" -ForegroundColor White
    Write-Host "    [4] 配置 阿里通义千问    (Qwen3.5 最新)" -ForegroundColor White
    Write-Host "    [5] 配置 百度文心 ERNIE  (4.5 旗舰)" -ForegroundColor White
    Write-Host "    [6] 自定义 API 接口" -ForegroundColor White
    Write-Host "    [7] 清除所有 API 配置" -ForegroundColor White
    Write-Host "    [8] 测试当前 API 连接" -ForegroundColor White
    Write-Host "    [Q] 退出" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "  请输入选项"

    if ($choice -eq 'Q' -or $choice -eq 'q') {
        Write-Host ""
        Write-Host "  配置工具已退出。请打开新终端窗口使环境变量生效。" -ForegroundColor Yellow
        Write-Host ""
        break
    }

    if ($choice -ge "1" -and $choice -le "5") {
        $provider = $providers[$choice]
        Write-Host ""
        Write-Host "  配置 $($provider.Name)" -ForegroundColor Cyan
        Write-Host "  $($provider.Help)" -ForegroundColor Gray
        Write-Host ""

        $openBrowser = Read-Host "  是否打开浏览器获取 API Key? (Y/n)"
        if ($openBrowser -ne 'n' -and $openBrowser -ne 'N') {
            Start-Process $provider.KeyUrl
        }

        $apiKey = Read-Host "  请输入 API Key"
        if ([string]::IsNullOrWhiteSpace($apiKey)) {
            Write-Host "  [警告] 未输入 API Key，操作取消" -ForegroundColor Yellow
            Read-Host "  按 Enter 返回主菜单"
            continue
        }

        # 选择模型
        Write-Host ""
        Write-Host "  可用模型:" -ForegroundColor White
        for ($i = 0; $i -lt $provider.Models.Count; $i++) {
            $tag = if ($i -eq 0) { " (推荐)" } else { "" }
            $desc = ""
            if ($provider.ModelDescs -and $i -lt $provider.ModelDescs.Count) {
                $desc = " - $($provider.ModelDescs[$i])"
            }
            Write-Host "    [$($i+1)] $($provider.Models[$i])$desc$tag" -ForegroundColor White
        }
        $modelChoice = Read-Host "  请选择模型 (默认 1)"
        if ([string]::IsNullOrWhiteSpace($modelChoice)) { $modelChoice = "1" }
        $idx = [int]$modelChoice - 1
        if ($idx -lt 0 -or $idx -ge $provider.Models.Count) { $idx = 0 }

        Set-ApiConfig -BaseUrl $provider.BaseUrl -ApiKey $apiKey -Model $provider.Models[$idx]

        Write-Host ""
        Write-Host "  [成功] $($provider.Name) 配置完成!" -ForegroundColor Green
        Write-Host "  模型: $($provider.Models[$idx])" -ForegroundColor Green
        Read-Host "  按 Enter 返回主菜单"
    }
    elseif ($choice -eq "6") {
        Write-Host ""
        Write-Host "  自定义 API 接口配置" -ForegroundColor Cyan
        Write-Host ""

        $customBase  = Read-Host "  请输入 API Base URL"
        $customKey   = Read-Host "  请输入 API Key"
        $customModel = Read-Host "  请输入模型名称"

        if (-not [string]::IsNullOrWhiteSpace($customBase) -and
            -not [string]::IsNullOrWhiteSpace($customKey) -and
            -not [string]::IsNullOrWhiteSpace($customModel)) {
            Set-ApiConfig -BaseUrl $customBase -ApiKey $customKey -Model $customModel
            Write-Host ""
            Write-Host "  [成功] 自定义 API 配置完成!" -ForegroundColor Green
        }
        else {
            Write-Host "  [警告] 配置信息不完整，操作取消" -ForegroundColor Yellow
        }
        Read-Host "  按 Enter 返回主菜单"
    }
    elseif ($choice -eq "7") {
        $confirmClear = Read-Host "  确定要清除所有 API 配置吗? (y/N)"
        if ($confirmClear -eq 'y' -or $confirmClear -eq 'Y') {
            Clear-ApiConfig
        }
        Read-Host "  按 Enter 返回主菜单"
    }
    elseif ($choice -eq "8") {
        Write-Host ""
        Write-Host "  正在测试 API 连接..." -ForegroundColor Cyan

        $testBaseUrl = [System.Environment]::GetEnvironmentVariable("OPENAI_BASE_URL", "User")
        $testApiKey  = [System.Environment]::GetEnvironmentVariable("OPENAI_API_KEY", "User")
        $testModel   = [System.Environment]::GetEnvironmentVariable("CLAUDE_MODEL", "User")

        if ([string]::IsNullOrWhiteSpace($testBaseUrl) -or [string]::IsNullOrWhiteSpace($testApiKey)) {
            Write-Host "  [错误] 未配置 API，请先选择一个 API 提供商进行配置" -ForegroundColor Red
        }
        else {
            try {
                $testUrl = "$testBaseUrl/chat/completions"
                $body = @{
                    model    = $testModel
                    messages = @(@{ role = "user"; content = "请回复'连接成功'" })
                    max_tokens = 20
                } | ConvertTo-Json -Depth 3

                $headers = @{
                    "Content-Type"  = "application/json"
                    "Authorization" = "Bearer $testApiKey"
                }

                Write-Host "  请求地址: $testUrl" -ForegroundColor Gray
                Write-Host "  使用模型: $testModel" -ForegroundColor Gray

                $response = Invoke-RestMethod -Uri $testUrl -Method POST -Headers $headers -Body $body -TimeoutSec 30

                if ($response.choices -and $response.choices.Count -gt 0) {
                    $reply = $response.choices[0].message.content
                    Write-Host ""
                    Write-Host "  [成功] API 连接正常!" -ForegroundColor Green
                    Write-Host "  模型回复: $reply" -ForegroundColor Green
                }
                else {
                    Write-Host "  [警告] API 返回了意外的响应格式" -ForegroundColor Yellow
                    Write-Host "  响应: $($response | ConvertTo-Json -Depth 2)" -ForegroundColor Gray
                }
            }
            catch {
                Write-Host ""
                Write-Host "  [错误] API 连接失败" -ForegroundColor Red
                Write-Host "  错误信息: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host ""
                Write-Host "  请检查:" -ForegroundColor Yellow
                Write-Host "    1. API Key 是否正确" -ForegroundColor Yellow
                Write-Host "    2. API Base URL 是否正确" -ForegroundColor Yellow
                Write-Host "    3. 账户是否有余额" -ForegroundColor Yellow
                Write-Host "    4. 网络是否正常" -ForegroundColor Yellow
            }
        }

        Write-Host ""
        Read-Host "  按 Enter 返回主菜单"
    }
    else {
        Write-Host "  无效选项，请重试" -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
}
