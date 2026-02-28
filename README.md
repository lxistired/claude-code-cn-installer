# Claude Code 一键安装工具 (Windows 中国版)

面向中国用户的 Claude Code Windows 一键安装工具。自动安装所有依赖，并引导配置智谱 GLM API。

## 为什么需要这个工具？

1. **Claude Code** 需要 Node.js 和 Git 环境，对非开发者来说安装配置较为复杂
2. **中国用户无法直接访问 Anthropic Claude API**，需要使用智谱 GLM API 替代
3. 本工具实现了 **一键式安装 + 傻瓜式配置**，降低使用门槛

## 支持的模型

本工具通过智谱 GLM 的 Anthropic 兼容端点接入，支持以下模型：

| 模型 | 说明 |
|------|------|
| glm-5 | 旗舰模型 745B MoE，最强（对标 Claude Opus） ← 推荐 |
| glm-4.7 | 编程增强 SWE-bench 73.8（对标 Claude Sonnet） |
| glm-4.5 | Agent 基座，工具调用优化 |
| glm-4.7-flash | 30B MoE 轻量快速（对标 Claude Haiku） |
| glm-4-flash | 免费模型，轻量任务 |
| glm-4.5-air | 轻量快速，低成本 |

注册地址：https://open.bigmodel.cn

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
5. **配置智谱 GLM API** - 交互式引导您选择模型并输入 API Key

## 配置 API

### 首次配置

安装过程中会引导您完成 API 配置。您需要：

1. 在智谱开放平台 (https://open.bigmodel.cn) 注册账号
2. 获取 API Key（右上角头像 → API 密钥 → 创建）
3. 输入 API Key
4. 从可用模型列表中选择要使用的模型

### 更换/修改 API

运行 `配置API.bat` 或直接运行 `configure-api.ps1`：

```powershell
.\configure-api.ps1
```

功能包括：
- 查看当前配置
- 更换 API Key
- 重新选择模型
- 测试 API 连接
- 清除所有配置

### 手动配置

如果您不想使用配置工具，也可以手动编辑 `%USERPROFILE%\.claude\settings.json`：

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "https://open.bigmodel.cn/api/anthropic",
    "ANTHROPIC_API_KEY": "your-api-key-here",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-5",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.7",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air"
  }
}
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

### Q: 如何更换模型或 API Key？
**A:** 运行 `配置API.bat`，重新输入 API Key 并选择模型即可。

### Q: API 连接测试失败怎么办？
**A:** 请检查：
1. API Key 是否正确
2. 账户是否有余额
3. 网络连接是否正常
4. 智谱平台服务是否正常

### Q: 支持 Windows 7 吗？
**A:** 建议使用 Windows 10 或更高版本。Node.js 22.x 不再支持 Windows 7。

## 技术原理

本工具通过设置 `ANTHROPIC_BASE_URL` 环境变量，将 Claude Code 的 API 请求重定向到智谱 GLM 的 Anthropic 兼容端点 (`https://open.bigmodel.cn/api/anthropic`)。智谱 GLM 提供了与 Anthropic Messages API 格式兼容的接口，因此 Claude Code 可以直接调用 GLM 模型。

通过 `ANTHROPIC_DEFAULT_OPUS_MODEL`、`ANTHROPIC_DEFAULT_SONNET_MODEL`、`ANTHROPIC_DEFAULT_HAIKU_MODEL` 三个环境变量，分别映射 Claude Code 内部使用的 Opus/Sonnet/Haiku 三个模型槽位到具体的 GLM 模型。

## 许可证

本工具仅供学习和个人使用。Claude Code 的版权归 Anthropic 所有。智谱 GLM API 的使用须遵守智谱的服务条款。
