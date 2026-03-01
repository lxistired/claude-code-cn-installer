# ============================================================================
# OpenCode 智谱 GLM API 配置工具
# ============================================================================

# Ensure UTF-8 output in both GBK and UTF-8 consoles
chcp 65001 | Out-Null
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# ---------------------------------------------------------------------------
# 全局配置
# ---------------------------------------------------------------------------
$GLM_CODING_API   = "https://open.bigmodel.cn/api/coding/paas/v4"
$GLM_GENERAL_API  = "https://open.bigmodel.cn/api/paas/v4"
$GLM_REGISTER_URL = "https://open.bigmodel.cn"
$GLM_APIKEY_URL   = "https://open.bigmodel.cn/usercenter/apikeys"
$GLM_CODING_URL   = "https://open.bigmodel.cn/glm-coding"
$CONFIG_DIR       = "$env:USERPROFILE\.config\opencode"
$CONFIG_PATH      = "$CONFIG_DIR\opencode.json"

$GLM_MODELS = @(
    @{ Id = "glm-5";        Name = "GLM-5";        Desc = "旗舰 745B MoE，最强（对标 Claude Opus）"; Context = 128000; Output = 65536 }
    @{ Id = "glm-4.7";      Name = "GLM-4.7";      Desc = "编程增强，SWE-bench 73.8（对标 Sonnet）"; Context = 128000; Output = 128000 }
    @{ Id = "glm-4.5";      Name = "GLM-4.5";      Desc = "Agent 基座，工具调用优化"; Context = 128000; Output = 16384 }
    @{ Id = "glm-4.7-flash"; Name = "GLM-4.7-Flash"; Desc = "30B MoE 轻量快速（对标 Haiku）"; Context = 128000; Output = 16384 }
    @{ Id = "glm-4-flash";  Name = "GLM-4-Flash";  Desc = "免费模型，轻量任务"; Context = 128000; Output = 4096 }
)

# ---------------------------------------------------------------------------
# 辅助函数
# ---------------------------------------------------------------------------
function Show-CurrentConfig {
    Write-Host ""
    Write-Host "  当前配置:" -ForegroundColor Cyan
    Write-Host "  ────────────────────────────────────────" -ForegroundColor Gray

    if (Test-Path $CONFIG_PATH) {
        try {
            $config = Get-Content $CONFIG_PATH -Raw | ConvertFrom-Json

            $provider = $config.provider
            # 查找 zhipu 或 zhipuai provider
            $zhipu = $null
            if ($provider.zhipu) { $zhipu = $provider.zhipu }
            elseif ($provider.zhipuai) { $zhipu = $provider.zhipuai }

            if ($zhipu) {
                $baseUrl = if ($zhipu.options -and $zhipu.options.baseURL) { $zhipu.options.baseURL }
                           elseif ($zhipu.api) { $zhipu.api }
                           else { "(未设置)" }
                Write-Host "    API 端点  = $baseUrl" -ForegroundColor White

                $apiKey = if ($zhipu.options -and $zhipu.options.apiKey) { $zhipu.options.apiKey } else { "(未设置)" }
                if ($apiKey -ne "(未设置)" -and -not $apiKey.StartsWith("{env:")) {
                    $masked = $apiKey.Substring(0, [Math]::Min(8, $apiKey.Length)) + "****"
                    Write-Host "    API Key   = $masked" -ForegroundColor White
                } else {
                    Write-Host "    API Key   = $apiKey" -ForegroundColor White
                }
            } else {
                Write-Host "    (未找到智谱 GLM 配置)" -ForegroundColor DarkGray
            }

            if ($config.model) {
                Write-Host "    默认模型  = $($config.model)" -ForegroundColor White
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

function Save-Config {
    param(
        [string]$ApiKey,
        [string]$BaseUrl,
        [string]$ModelId,
        [string]$ModelName,
        [int]$ContextLimit,
        [int]$OutputLimit
    )

    if (-not (Test-Path $CONFIG_DIR)) {
        New-Item -ItemType Directory -Path $CONFIG_DIR -Force | Out-Null
    }

    $configObj = [ordered]@{
        '$schema'  = "https://opencode.ai/config.json"
        provider = [ordered]@{
            zhipu = [ordered]@{
                npm     = "@ai-sdk/openai-compatible"
                name    = "Zhipu AI"
                options = [ordered]@{
                    baseURL = $BaseUrl
                    apiKey  = $ApiKey
                }
                models  = [ordered]@{
                    $ModelId = [ordered]@{
                        name  = $ModelName
                        limit = [ordered]@{
                            context = $ContextLimit
                            output  = $OutputLimit
                        }
                    }
                }
            }
        }
        model = "zhipu/$ModelId"
    }

    # 默认选 glm-5 时加入 glm-4.7 和 glm-4.7-flash 备选
    if ($ModelId -eq "glm-5") {
        $configObj.provider.zhipu.models["glm-4.7"] = [ordered]@{
            name  = "GLM-4.7"
            limit = [ordered]@{ context = 128000; output = 128000 }
        }
        $configObj.provider.zhipu.models["glm-4.7-flash"] = [ordered]@{
            name  = "GLM-4.7-Flash"
            limit = [ordered]@{ context = 128000; output = 16384 }
        }
    }

    $configObj | ConvertTo-Json -Depth 10 | Out-File -FilePath $CONFIG_PATH -Encoding UTF8 -Force
}

# ---------------------------------------------------------------------------
# 主菜单
# ---------------------------------------------------------------------------
while ($true) {
    Clear-Host
    Write-Host ""
    Write-Host "  ================================================================" -ForegroundColor Magenta
    Write-Host "       OpenCode 智谱 GLM API 配置工具" -ForegroundColor Magenta
    Write-Host "  ================================================================" -ForegroundColor Magenta

    Show-CurrentConfig

    Write-Host "  请选择操作:" -ForegroundColor White
    Write-Host "    [1] 配置 / 更换 API Key 和模型" -ForegroundColor White
    Write-Host "    [2] 仅切换模型" -ForegroundColor White
    Write-Host "    [3] 测试 API 连接" -ForegroundColor White
    Write-Host "    [4] 清除配置" -ForegroundColor White
    Write-Host "    [Q] 退出" -ForegroundColor White
    Write-Host ""

    $choice = Read-Host "  请输入选项"

    if ($choice -eq 'Q' -or $choice -eq 'q') {
        Write-Host ""
        Write-Host "  配置工具已退出。请打开新终端窗口使配置生效。" -ForegroundColor Yellow
        Write-Host ""
        break
    }

    # ── [1] 配置 API Key 和模型 ──────────────────────────────────────────────
    if ($choice -eq "1") {
        Write-Host ""
        Write-Host "  ── 配置智谱 GLM API ──────────────────────────────────" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  获取 API Key:" -ForegroundColor White
        Write-Host "    1. 注册: $GLM_REGISTER_URL" -ForegroundColor Gray
        Write-Host "    2. 购买 Coding Plan: $GLM_CODING_URL" -ForegroundColor Gray
        Write-Host "    3. 获取 Key: 右上角头像 -> API 密钥 -> 创建" -ForegroundColor Gray
        Write-Host ""

        $openBrowser = Read-Host "  是否打开浏览器获取 API Key? (Y/n)"
        if ($openBrowser -ne 'n' -and $openBrowser -ne 'N') {
            Start-Process $GLM_APIKEY_URL
        }

        $apiKey = Read-Host "  请输入 API Key"
        if ([string]::IsNullOrWhiteSpace($apiKey)) {
            Write-Host "  [警告] 未输入 API Key，操作取消" -ForegroundColor Yellow
            Read-Host "  按 Enter 返回主菜单"
            continue
        }

        # 选择 API 类型
        Write-Host ""
        Write-Host "  请选择 API 类型:" -ForegroundColor White
        Write-Host "    [1] GLM Coding Plan (订阅套餐，性价比高) ← 推荐" -ForegroundColor White
        Write-Host "    [2] 通用 API (按量计费)" -ForegroundColor White
        Write-Host ""
        $apiTypeChoice = Read-Host "  请选择 (默认 1)"
        if ([string]::IsNullOrWhiteSpace($apiTypeChoice)) { $apiTypeChoice = "1" }
        $baseUrl = if ($apiTypeChoice -eq "2") { $GLM_GENERAL_API } else { $GLM_CODING_API }

        # 选择模型
        Write-Host ""
        Write-Host "  请选择默认模型:" -ForegroundColor White
        for ($i = 0; $i -lt $GLM_MODELS.Count; $i++) {
            $m = $GLM_MODELS[$i]
            $tag = if ($i -eq 0) { " ← 推荐" } else { "" }
            Write-Host "    [$($i+1)] $($m.Name)  - $($m.Desc)$tag" -ForegroundColor White
        }
        $modelChoice = Read-Host "  请选择 (默认 1)"
        if ([string]::IsNullOrWhiteSpace($modelChoice)) { $modelChoice = "1" }
        $modelIdx = [int]$modelChoice - 1
        if ($modelIdx -lt 0 -or $modelIdx -ge $GLM_MODELS.Count) { $modelIdx = 0 }
        $selected = $GLM_MODELS[$modelIdx]

        Save-Config -ApiKey $apiKey -BaseUrl $baseUrl `
                    -ModelId $selected.Id -ModelName $selected.Name `
                    -ContextLimit $selected.Context -OutputLimit $selected.Output

        Write-Host ""
        Write-Host "  [成功] 配置完成!" -ForegroundColor Green
        Write-Host "    API 端点  = $baseUrl" -ForegroundColor Green
        Write-Host "    API Key   = $($apiKey.Substring(0, [Math]::Min(8, $apiKey.Length)))****" -ForegroundColor Green
        Write-Host "    默认模型  = $($selected.Name)" -ForegroundColor Green
        Write-Host ""
        Write-Host "  配置已写入: $CONFIG_PATH" -ForegroundColor Gray
        Write-Host "  请打开新终端窗口后运行 opencode 启动。" -ForegroundColor Yellow
        Write-Host ""
        Read-Host "  按 Enter 返回主菜单"
    }

    # ── [2] 仅切换模型 ──────────────────────────────────────────────────────
    elseif ($choice -eq "2") {
        if (-not (Test-Path $CONFIG_PATH)) {
            Write-Host "  [错误] 尚未配置，请先使用选项 [1] 进行配置" -ForegroundColor Red
            Read-Host "  按 Enter 返回主菜单"
            continue
        }

        try {
            $config = Get-Content $CONFIG_PATH -Raw | ConvertFrom-Json

            Write-Host ""
            Write-Host "  请选择要切换的模型:" -ForegroundColor White
            for ($i = 0; $i -lt $GLM_MODELS.Count; $i++) {
                $m = $GLM_MODELS[$i]
                $tag = if ($i -eq 0) { " ← 推荐" } else { "" }
                Write-Host "    [$($i+1)] $($m.Name)  - $($m.Desc)$tag" -ForegroundColor White
            }
            $modelChoice = Read-Host "  请选择"
            $modelIdx = [int]$modelChoice - 1
            if ($modelIdx -lt 0 -or $modelIdx -ge $GLM_MODELS.Count) { $modelIdx = 0 }
            $selected = $GLM_MODELS[$modelIdx]

            # 读取现有 apiKey 和 baseUrl
            $existingKey = ""
            $existingUrl = $GLM_CODING_API
            if ($config.provider.zhipu -and $config.provider.zhipu.options) {
                $existingKey = $config.provider.zhipu.options.apiKey
                $existingUrl = $config.provider.zhipu.options.baseURL
            }

            Save-Config -ApiKey $existingKey -BaseUrl $existingUrl `
                        -ModelId $selected.Id -ModelName $selected.Name `
                        -ContextLimit $selected.Context -OutputLimit $selected.Output

            Write-Host ""
            Write-Host "  [成功] 已切换默认模型为: $($selected.Name)" -ForegroundColor Green
            Write-Host ""
        } catch {
            Write-Host "  [错误] 读取配置文件失败: $_" -ForegroundColor Red
        }
        Read-Host "  按 Enter 返回主菜单"
    }

    # ── [3] 测试 API 连接 ──────────────────────────────────────────────────
    elseif ($choice -eq "3") {
        Write-Host ""
        Write-Host "  正在测试 API 连接..." -ForegroundColor Cyan

        if (-not (Test-Path $CONFIG_PATH)) {
            Write-Host "  [错误] 未找到配置文件，请先配置 API" -ForegroundColor Red
        } else {
            try {
                $config = Get-Content $CONFIG_PATH -Raw | ConvertFrom-Json

                $testKey   = $null
                $testUrl   = $null
                $testModel = $null

                if ($config.provider.zhipu -and $config.provider.zhipu.options) {
                    $testKey = $config.provider.zhipu.options.apiKey
                    $testUrl = $config.provider.zhipu.options.baseURL
                }

                if ($config.model) {
                    # model 格式是 "zhipu/glm-5"，提取模型 ID
                    $testModel = ($config.model -split "/")[-1]
                }

                if ([string]::IsNullOrWhiteSpace($testKey)) {
                    Write-Host "  [错误] 配置文件中未找到 API Key" -ForegroundColor Red
                } elseif ([string]::IsNullOrWhiteSpace($testUrl)) {
                    Write-Host "  [错误] 配置文件中未找到 API 端点" -ForegroundColor Red
                } else {
                    $requestUrl = "$testUrl/chat/completions"

                    $body = @{
                        model      = $testModel
                        max_tokens = 20
                        messages   = @(@{ role = "user"; content = "请回复'连接成功'" })
                    } | ConvertTo-Json -Depth 3

                    $headers = @{
                        "Content-Type"  = "application/json"
                        "Authorization" = "Bearer $testKey"
                    }

                    Write-Host "  请求地址: $requestUrl" -ForegroundColor Gray
                    Write-Host "  使用模型: $testModel" -ForegroundColor Gray
                    Write-Host ""

                    $response = Invoke-RestMethod -Uri $requestUrl -Method POST -Headers $headers -Body $body -TimeoutSec 30

                    if ($response.choices -and $response.choices.Count -gt 0) {
                        $reply = $response.choices[0].message.content
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
                Write-Host "    2. 是否已购买 GLM Coding Plan 或账户有余额" -ForegroundColor Yellow
                Write-Host "    3. 网络是否正常" -ForegroundColor Yellow
            }
        }

        Write-Host ""
        Read-Host "  按 Enter 返回主菜单"
    }

    # ── [4] 清除配置 ──────────────────────────────────────────────────────
    elseif ($choice -eq "4") {
        $confirmClear = Read-Host "  确定要清除所有配置吗? (y/N)"
        if ($confirmClear -eq 'y' -or $confirmClear -eq 'Y') {
            if (Test-Path $CONFIG_PATH) {
                Remove-Item -Path $CONFIG_PATH -Force
                Write-Host "  [信息] 配置文件已清除" -ForegroundColor Green
            } else {
                Write-Host "  [信息] 无配置文件，无需清除" -ForegroundColor Gray
            }
        }
        Read-Host "  按 Enter 返回主菜单"
    }

    else {
        Write-Host "  无效选项，请重试" -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
}
