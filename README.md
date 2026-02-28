# Claude Code 一键安装工具 (Windows 中国版)

面向中国用户的 Claude Code Windows 一键安装工具。自动安装所有依赖，并引导配置国产大模型 API。

## 为什么需要这个工具？

1. **Claude Code** 需要 Node.js 和 Git 环境，对非开发者来说安装配置较为复杂
2. **中国用户无法直接访问 Anthropic Claude API**，需要使用国产大模型 API 替代
3. 本工具实现了 **一键式安装 + 傻瓜式配置**，降低使用门槛

## 支持的国产大模型

| 提供商 | 推荐模型 | 可选模型 | 注册地址 |
|--------|----------|---------|---------|
| 智谱 GLM | glm-5 (745B 旗舰) | glm-4.7, glm-4.5, glm-4.7-flash, glm-4-flash | https://open.bigmodel.cn |
| DeepSeek | deepseek-chat (V3.2) | deepseek-reasoner | https://platform.deepseek.com |
| 月之暗面 (Kimi) | kimi-k2.5 (1T 旗舰) | kimi-k2, moonshot-v1-128k, moonshot-v1-32k | https://platform.moonshot.cn |
| 阿里通义千问 (Qwen) | qwen3.5-plus (最新旗舰) | qwen3-max, qwq-plus, qwen-plus, qwen-turbo | https://dashscope.aliyuncs.com |
| 百度文心 (ERNIE) | ernie-4.5 (300B 旗舰) | ernie-4.5-turbo, ernie-4.0-turbo, ernie-3.5 | https://qianfan.baidubce.com |
| 自定义 | 任意 OpenAI 兼容接口 | — | - |

## 快速开始

### 方式一：直接运行脚本（推荐）

1. 下载本目录下的所有文件
2. **右键** `一键安装.bat` → **以管理员身份运行**
3. 按照提示完成安装和 API 配置

### 方式二：使用 Inno Setup 打包为安装程序

1. 下载并安装 [Inno Setup](https://jrsoftware.org/isinfo.php)
2. 打开 `ClaudeCodeInstaller.iss`
3. 点击 Build → Compile
4. 生成的 `ClaudeCode-Setup-v1.0.0.exe` 即为安装包

### 方式三：手动运行 PowerShell 脚本

```powershell
# 以管理员身份打开 PowerShell，然后运行：
Set-ExecutionPolicy Bypass -Scope Process -Force
.\install.ps1
```

## 安装过程说明

安装脚本会自动完成以下 5 个步骤：

1. **检查/安装 Node.js** - 从国内镜像 (npmmirror.com) 下载 Node.js LTS 版本
2. **检查/安装 Git** - 从国内镜像下载 Git for Windows
3. **配置 npm 镜像源** - 设置为 npmmirror.com 国内镜像
4. **安装 Claude Code** - 通过 npm 全局安装 `@anthropic-ai/claude-code`
5. **配置国产大模型 API** - 交互式引导您选择 API 提供商并输入 API Key

## 配置 API

### 首次配置

安装过程中会引导您完成 API 配置。您需要：

1. 选择一个国产大模型提供商
2. 在提供商网站注册账号
3. 获取 API Key
4. 输入 API Key
5. 从该提供商的可用模型列表中选择要使用的模型（每个模型都有功能说明）

### 更换/修改 API

运行 `配置API.bat` 或直接运行 `configure-api.ps1`：

```powershell
.\configure-api.ps1
```

功能包括：
- 查看当前配置
- 切换 API 提供商
- 更换 API Key
- 测试 API 连接
- 清除所有配置

### 手动配置环境变量

如果您不想使用配置工具，也可以手动设置以下环境变量：

```powershell
# 在 PowerShell 中设置（永久生效）
[System.Environment]::SetEnvironmentVariable("ANTHROPIC_BASE_URL", "https://open.bigmodel.cn/api/paas/v4", "User")
[System.Environment]::SetEnvironmentVariable("ANTHROPIC_API_KEY", "your-api-key-here", "User")
[System.Environment]::SetEnvironmentVariable("OPENAI_API_KEY", "your-api-key-here", "User")
[System.Environment]::SetEnvironmentVariable("OPENAI_BASE_URL", "https://open.bigmodel.cn/api/paas/v4", "User")
[System.Environment]::SetEnvironmentVariable("CLAUDE_CODE_USE_OPENAI", "1", "User")
[System.Environment]::SetEnvironmentVariable("CLAUDE_MODEL", "glm-5", "User")
```

## 使用 Claude Code

安装完成后，打开新的 PowerShell 或 CMD 窗口：

```bash
# 启动交互模式
claude

# 查看帮助
claude --help

# 查看版本
claude --version
```

## 文件说明

| 文件 | 说明 |
|------|------|
| `一键安装.bat` | 一键安装入口（双击运行） |
| `配置API.bat` | API 配置工具入口（双击运行） |
| `install.ps1` | 主安装脚本 (PowerShell) |
| `configure-api.ps1` | API 配置脚本 (PowerShell) |
| `ClaudeCodeInstaller.iss` | Inno Setup 打包脚本 |

## 常见问题

### Q: 安装后运行 `claude` 提示"不是内部或外部命令"？
**A:** 请关闭当前终端，打开一个新的 PowerShell 或 CMD 窗口再试。安装过程中修改的 PATH 需要新窗口才能生效。

### Q: npm install 速度很慢怎么办？
**A:** 安装脚本已自动配置了国内镜像源 (npmmirror.com)。如果仍然慢，请检查网络连接。

### Q: 如何切换到其他 API 提供商？
**A:** 运行 `配置API.bat`，选择新的提供商并输入 API Key 即可。

### Q: API 连接测试失败怎么办？
**A:** 请检查：
1. API Key 是否正确
2. 账户是否有余额
3. 网络连接是否正常
4. API 提供商服务是否正常

### Q: 支持 Windows 7 吗？
**A:** 建议使用 Windows 10 或更高版本。Node.js 22.x 不再支持 Windows 7。

## 技术原理

本工具通过设置 `ANTHROPIC_BASE_URL` 和 `OPENAI_BASE_URL` 等环境变量，将 Claude Code 的 API 请求重定向到国产大模型提供商的 OpenAI 兼容接口。大部分国产大模型都提供了 OpenAI 格式的 API，因此可以无缝替换。

## 许可证

本工具仅供学习和个人使用。Claude Code 的版权归 Anthropic 所有。各大模型 API 的使用须遵守对应提供商的服务条款。
