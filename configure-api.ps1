# ============================================================================
# Claude Code API 配置工具 - 智谱 GLM
# ============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

function Show-CurrentConfig {
    Write-Host ""
    Write-Host "  当前 API 配置:" -ForegroundColor Cyan
    Write-Host "  ────────────────────────────────────────" -ForegroundColor Gray

    $settingsPath = "$env:USERPROFILE\.claude\settings.json"
    if (Test-Path $settingsPath) {
        try {
            $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
            $env = $settings.env

            if ($env.ANTHROPIC_BASE_URL) {
                Write-Host "    ANTHROPIC_BASE_URL          = $($env.ANTHROPIC_BASE_URL)" -ForegroundColor White
            } else {
                Write-Host "    ANTHROPIC_BASE_URL          = (未设置)" -ForegroundColor DarkGray
            }

            if ($env.ANTHROPIC_API_KEY) {
                $masked = $env.ANTHROPIC_API_KEY.Substring(0, [Math]::Min(8, $env.ANTHROPIC_API_KEY.Length)) + "****"
                Write-Host "    ANTHROPIC_API_KEY           = $masked" -ForegroundColor White
            } else {
                Write-Host "    ANTHROPIC_API_KEY           = (未设置)" -ForegroundColor DarkGray
            }

            if ($env.ANTHROPIC_DEFAULT_OPUS_MODEL) {
                Write-Host "    ANTHROPIC_DEFAULT_OPUS_MODEL   = $($env.ANTHROPIC_DEFAULT_OPUS_MODEL)" -ForegroundColor White
            }
            if ($env.ANTHROPIC_DEFAULT_SONNET_MODEL) {
                Write-Host "    ANTHROPIC_DEFAULT_SONNET_MODEL = $($env.ANTHROPIC_DEFAULT_SONNET_MODEL)" -ForegroundColor White
            }
            if ($env.ANTHROPIC_DEFAULT_HAIKU_MODEL) {
                Write-Host "    ANTHROPIC_DEFAULT_HAIKU_MODEL  = $($env.ANTHROPIC_DEFAULT_HAIKU_MODEL)" -ForegroundColor White
            }
        } catch {
            Write-Host "    (配置文件格式异常)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "    (尚未配置)" -ForegroundColor DarkGray
    }

    Write-Host "  ────────────────────────────────────────" -ForegroundColor Gray
    Write-Host ""
}

function Set-ApiConfig {
    param(
        [string]$ApiKey,
        [string]$OpusModel,
        [string]$SonnetModel,
        [string]$HaikuModel
    )

    # 智谱 GLM 专用 Anthropic 兼容端点（支持 /messages 格式）
    $BaseUrl = "https://open.bigmodel.cn/api/anthropic"

    # 更新 Claude Code 配置文件（官方推荐方式：通过 env 字段做模型映射）
    $claudeConfigDir = "$env:USERPROFILE\.claude"
    if (-not (Test-Path $claudeConfigDir)) {
        New-Item -ItemType Directory -Path $claudeConfigDir -Force | Out-Null
    }

    $settingsObj = [ordered]@{
        env = [ordered]@{
            ANTHROPIC_BASE_URL             = $BaseUrl
            ANTHROPIC_API_KEY              = $ApiKey
            ANTHROPIC_DEFAULT_HAIKU_MODEL  = $HaikuModel
            ANTHROPIC_DEFAULT_SONNET_MODEL = $SonnetModel
            ANTHROPIC_DEFAULT_OPUS_MODEL   = $OpusModel
        }
    }

    $settingsJson = $settingsObj | ConvertTo-Json -Depth 5
    $settingsJson | Out-File -FilePath "$claudeConfigDir\settings.json" -Encoding UTF8 -Force
}

function Clear-ApiConfig {
    $settingsPath = "$env:USERPROFILE\.claude\settings.json"
    if (Test-Path $settingsPath) {
        Remove-Item -Path $settingsPath -Force
        Write-Host "  [信息] 配置文件已清除" -ForegroundColor Green
    } else {
        Write-Host "  [信息] 无配置文件，无需清除" -ForegroundColor Gray
    }
}

# ---------------------------------------------------------------------------
# 智谱 GLM 模型列表
# ---------------------------------------------------------------------------
$glmModels = @(
    @{ Name = "glm-5";        Desc = "旗舰模型 745B MoE，最强（对标 Claude Opus）" }
    @{ Name = "glm-4.7";      Desc = "编程增强 SWE-bench 73.8（对标 Claude Sonnet）" }
    @{ Name = "glm-4.5";      Desc = "Agent 基座，工具调用优化" }
    @{ Name = "glm-4.7-flash"; Desc = "30B MoE 轻量快速（对标 Claude Haiku）" }
    @{ Name = "glm-4-flash";  Desc = "免费模型，轻量任务" }
    @{ Name = "glm-4.5-air";  Desc = "轻量快速，低成本" }
)

# ---------------------------------------------------------------------------
# 主菜单
# ---------------------------------------------------------------------------
while ($true) {
    Clear-Host
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Magenta
    Write-Host "       Claude Code API 配置工具 - 智谱 GLM" -ForegroundColor Magenta
    Write-Host "  ================================================================" -ForegroundColor Magenta

    Show-CurrentConfig

    Write-Host "  请选择操作:" -ForegroundColor White
    Write-Host "    [1] 配置 智谱 GLM API Key" -ForegroundColor White
    Write-Host "    [2] 清除 API 配置" -ForegroundColor White
    Write-Host "    [3] 测试当前 API 连接" -ForegroundColor White
    Write-Host "    [Q] 退出" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "  请输入选项"

    if ($choice -eq 'Q' -or $choice -eq 'q') {
        Write-Host ""
        Write-Host "  配置工具已退出。请打开新终端窗口使配置生效。" -ForegroundColor Yellow
        Write-Host ""
        break
    }

    # ── [1] 配置 GLM ──────────────────────────────────────────────────────────
    if ($choice -eq "1") {
        Write-Host ""
        Write-Host "  ── 配置智谱 GLM ──────────────────────────────────────────" -ForegroundColor Cyan
        Write-Host "  获取 API Key: https://open.bigmodel.cn -> 右上角头像 -> API 密钥 -> 创建" -ForegroundColor Gray
        Write-Host ""

        $openBrowser = Read-Host "  是否打开浏览器获取 API Key? (Y/n)"
        if ($openBrowser -ne 'n' -and $openBrowser -ne 'N') {
            Start-Process "https://open.bigmodel.cn/usercenter/apikeys"
        }

        $apiKey = Read-Host "  请输入 API Key"
        if ([string]::IsNullOrWhiteSpace($apiKey)) {
            Write-Host "  [警告] 未输入 API Key，操作取消" -ForegroundColor Yellow
            Read-Host "  按 Enter 返回主菜单"
            continue
        }

        # 选择 Opus 模型（主力模型）
        Write-Host ""
        Write-Host "  请选择主力模型（对标 Claude Opus，用于复杂任务）:" -ForegroundColor White
        for ($i = 0; $i -lt $glmModels.Count; $i++) {
            $tag = if ($i -eq 0) { " ← 推荐" } else { "" }
            Write-Host "    [$($i+1)] $($glmModels[$i].Name)  - $($glmModels[$i].Desc)$tag" -ForegroundColor White
        }
        $opusChoice = Read-Host "  请选择 (默认 1)"
        if ([string]::IsNullOrWhiteSpace($opusChoice)) { $opusChoice = "1" }
        $opusIdx = [int]$opusChoice - 1
        if ($opusIdx -lt 0 -or $opusIdx -ge $glmModels.Count) { $opusIdx = 0 }
        $selectedOpus = $glmModels[$opusIdx].Name

        # 选择 Sonnet 模型（日常模型）
        Write-Host ""
        Write-Host "  请选择日常模型（对标 Claude Sonnet，用于普通任务）:" -ForegroundColor White
        for ($i = 0; $i -lt $glmModels.Count; $i++) {
            $tag = if ($i -eq 1) { " ← 推荐" } else { "" }
            Write-Host "    [$($i+1)] $($glmModels[$i].Name)  - $($glmModels[$i].Desc)$tag" -ForegroundColor White
        }
        $sonnetChoice = Read-Host "  请选择 (默认 2)"
        if ([string]::IsNullOrWhiteSpace($sonnetChoice)) { $sonnetChoice = "2" }
        $sonnetIdx = [int]$sonnetChoice - 1
        if ($sonnetIdx -lt 0 -or $sonnetIdx -ge $glmModels.Count) { $sonnetIdx = 1 }
        $selectedSonnet = $glmModels[$sonnetIdx].Name

        # Haiku 固定用轻量模型
        $selectedHaiku = "glm-4.5-air"

        Set-ApiConfig -ApiKey $apiKey -OpusModel $selectedOpus -SonnetModel $selectedSonnet -HaikuModel $selectedHaiku

        Write-Host ""
        Write-Host "  [成功] 智谱 GLM 配置完成!" -ForegroundColor Green
        Write-Host "  主力模型 (Opus):  $selectedOpus" -ForegroundColor Green
        Write-Host "  日常模型 (Sonnet): $selectedSonnet" -ForegroundColor Green
        Write-Host "  轻量模型 (Haiku):  $selectedHaiku" -ForegroundColor Green
        Write-Host ""
        Write-Host "  配置已写入 %USERPROFILE%\.claude\settings.json" -ForegroundColor Gray
        Write-Host "  请打开新终端窗口后运行 claude 启动。" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "  按 Enter 返回主菜单"
    }

    # ── [2] 清除配置 ──────────────────────────────────────────────────────────
    elseif ($choice -eq "2") {
        $confirmClear = Read-Host "  确定要清除所有 API 配置吗? (y/N)"
        if ($confirmClear -eq 'y' -or $confirmClear -eq 'Y') {
            Clear-ApiConfig
        }
        Read-Host "  按 Enter 返回主菜单"
    }

    # ── [3] 测试连接 ──────────────────────────────────────────────────────────
    elseif ($choice -eq "3") {
        Write-Host ""
        Write-Host "  正在测试 API 连接..." -ForegroundColor Cyan

        $settingsPath = "$env:USERPROFILE\.claude\settings.json"
        if (-not (Test-Path $settingsPath)) {
            Write-Host "  [错误] 未找到配置文件，请先配置 API Key" -ForegroundColor Red
        } else {
            try {
                $settings  = Get-Content $settingsPath -Raw | ConvertFrom-Json
                $testUrl   = "https://open.bigmodel.cn/api/anthropic/v1/messages"
                $testKey   = $settings.env.ANTHROPIC_API_KEY
                $testModel = $settings.env.ANTHROPIC_DEFAULT_SONNET_MODEL

                if ([string]::IsNullOrWhiteSpace($testKey)) {
                    Write-Host "  [错误] 配置文件中未找到 API Key" -ForegroundColor Red
                } else {
                    $body = @{
                        model      = $testModel
                        max_tokens = 20
                        messages   = @(@{ role = "user"; content = "请回复'连接成功'" })
                    } | ConvertTo-Json -Depth 3

                    $headers = @{
                        "Content-Type"     = "application/json"
                        "x-api-key"        = $testKey
                        "anthropic-version" = "2023-06-01"
                    }

                    Write-Host "  请求地址: $testUrl" -ForegroundColor Gray
                    Write-Host "  使用模型: $testModel" -ForegroundColor Gray

                    $response = Invoke-RestMethod -Uri $testUrl -Method POST -Headers $headers -Body $body -TimeoutSec 30

                    if ($response.content -and $response.content.Count -gt 0) {
                        $reply = $response.content[0].text
                        Write-Host ""
                        Write-Host "  [成功] API 连接正常!" -ForegroundColor Green
                        Write-Host "  模型回复: $reply" -ForegroundColor Green
                    } else {
                        Write-Host "  [警告] API 返回了意外的响应格式" -ForegroundColor Yellow
                        Write-Host "  响应: $($response | ConvertTo-Json -Depth 2)" -ForegroundColor Gray
                    }
                }
            } catch {
                Write-Host ""
                Write-Host "  [错误] API 连接失败" -ForegroundColor Red
                Write-Host "  错误信息: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host ""
                Write-Host "  请检查:" -ForegroundColor Yellow
                Write-Host "    1. API Key 是否正确" -ForegroundColor Yellow
                Write-Host "    2. 账户是否有余额或套餐" -ForegroundColor Yellow
                Write-Host "    3. 网络是否正常" -ForegroundColor Yellow
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
