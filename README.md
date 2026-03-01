# OpenCode 一键安装工具 (Windows 中国版)

面向中国用户的 OpenCode Windows 一键安装工具。自动安装所有依赖，配置智谱 GLM API，开箱即用。

## 为什么需要这个工具？

1. **OpenCode** 是开源 AI 编程助手（类似 Claude Code），需要 Node.js 环境，对非开发者来说配置复杂
2. **中国用户无法直接使用 Anthropic/OpenAI API**，需要使用智谱 GLM 替代
3. 本工具实现了 **一键安装 + 傻瓜式配置**，降低使用门槛
4. **无需翻墙**，全程使用国内镜像和国产 API

## 什么是 OpenCode？

[OpenCode](https://opencode.ai/) 是一款开源的终端 AI 编程助手，功能类似 Claude Code，但不绑定任何模型提供商。它可以：

- 在终端中通过自然语言编写、调试、重构代码
- 读写文件、执行命令、分析项目结构
- 支持 75+ 模型提供商，包括智谱 GLM

## 支持的模型

本工具通过智谱 GLM 的 OpenAI 兼容端点接入，支持以下模型：

| 模型 | 说明 |
|------|------|
| GLM-5 | 旗舰模型 745B MoE，最强（对标 Claude Opus） ← **推荐** |
| GLM-4.7 | 编程增强 SWE-bench 73.8（对标 Claude Sonnet） |
| GLM-4.5 | Agent 基座，工具调用优化 |
| GLM-4.7-Flash | 30B MoE 轻量快速（对标 Claude Haiku） |
| GLM-4-Flash | 免费模型，轻量任务 |

- 注册地址：https://open.bigmodel.cn
- GLM Coding Plan（推荐）：https://open.bigmodel.cn/glm-coding

## 快速开始

### 方式一：直接运行脚本（推荐）

1. 下载本目录下的所有文件
2. **右键** `一键安装OpenCode.bat` → **以管理员身份运行**
3. 按照提示完成安装
4. 选择模型、输入 API Key
5. 打开新终端，输入 `opencode` 即可使用！

### 方式二：使用 Inno Setup 打包为安装程序

1. 下载并安装 [Inno Setup](https://jrsoftware.org/isinfo.php)
2. 打开 `OpenCodeInstaller.iss`
3. 点击 Build → Compile
4. 生成的 `OpenCode-Setup-v1.0.0.exe` 即为安装包

### 方式三：手动运行 PowerShell 脚本

```powershell
# 以管理员身份打开 PowerShell，然后运行：
Set-ExecutionPolicy Bypass -Scope Process -Force
.\install-opencode.ps1
```

## 安装过程说明

安装脚本会自动完成以下步骤：

1. **安装 Node.js** - 从国内镜像 (npmmirror.com) 下载 Node.js LTS 版本
2. **配置 npm 镜像源** - 设置为 npmmirror.com 国内镜像
3. **安装 OpenCode** - 通过 npm 全局安装 `opencode-ai`
4. **配置智谱 GLM API** - 选择模型并输入 API Key，自动生成配置文件

## 配置 API

### 首次配置

安装过程中会引导您完成 API 配置。您需要：

1. 在智谱开放平台 (https://open.bigmodel.cn) 注册账号
2. 购买 GLM Coding Plan（推荐）或充值通用 API 额度
3. 获取 API Key（右上角头像 → API 密钥 → 创建）
4. 输入 API Key 并选择模型

### 更换/修改 API

运行 `配置智谱API.bat` 或直接运行 `configure-glm.ps1`：

```powershell
.\configure-glm.ps1
```

功能包括：
- 查看当前配置
- 更换 API Key
- 切换模型
- 测试 API 连接
- 清除配置

### 手动配置

也可以手动编辑 `%USERPROFILE%\.config\opencode\opencode.json`：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "zhipu": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Zhipu AI",
      "options": {
        "baseURL": "https://open.bigmodel.cn/api/coding/paas/v4",
        "apiKey": "your-api-key-here"
      },
      "models": {
        "glm-5": {
          "name": "GLM-5",
          "limit": {
            "context": 128000,
            "output": 65536
          }
        }
      }
    }
  },
  "model": "zhipu/glm-5"
}
```

## 使用 OpenCode

安装完成后，打开新的 PowerShell 或 CMD 窗口：

```bash
# 进入你的项目目录
cd 你的项目路径

# 启动 OpenCode
opencode

# 查看帮助
opencode --help
```

### OpenCode 内部常用命令

| 命令 | 说明 |
|------|------|
| `/models` | 切换模型 |
| `/connect` | 连接/切换 API 提供商 |
| `/init` | 初始化项目（生成 AGENTS.md） |
| `/help` | 查看帮助 |

## 文件说明

| 文件 | 说明 |
|------|------|
| `一键安装OpenCode.bat` | 一键安装入口（双击运行） |
| `配置智谱API.bat` | API 配置工具入口（双击运行） |
| `install-opencode.ps1` | 主安装脚本 (PowerShell) |
| `configure-glm.ps1` | API 配置脚本 (PowerShell) |
| `OpenCodeInstaller.iss` | Inno Setup 打包脚本 |

## 常见问题

### Q: 安装后运行 `opencode` 提示"不是内部或外部命令"？
**A:** 请关闭当前终端，打开一个新的 PowerShell 或 CMD 窗口再试。安装过程中修改的 PATH 需要新窗口才能生效。

### Q: npm install 速度很慢怎么办？
**A:** 安装脚本已自动配置了国内镜像源 (npmmirror.com)。如果仍然慢，请检查网络连接。

### Q: 如何切换模型？
**A:** 运行 `配置智谱API.bat` 选择"仅切换模型"，或在 OpenCode 中使用 `/models` 命令。

### Q: GLM Coding Plan 和通用 API 有什么区别？
**A:** Coding Plan 是订阅制套餐，专为编程工具优化，性价比更高。通用 API 按量计费，更灵活。推荐使用 Coding Plan。

### Q: API 连接测试失败怎么办？
**A:** 请检查：
1. API Key 是否正确
2. 是否已购买 Coding Plan 或账户有余额
3. 网络连接是否正常
4. 智谱平台服务是否正常

### Q: 支持 Windows 7 吗？
**A:** 建议使用 Windows 10 或更高版本。Node.js 22.x 不再支持 Windows 7。

## 技术原理

本工具通过 OpenCode 的自定义提供商配置，使用 `@ai-sdk/openai-compatible` 适配器将 API 请求发送到智谱 GLM 的 OpenAI 兼容端点。配置文件存放在 `~/.config/opencode/opencode.json`。

智谱 GLM 提供了与 OpenAI Chat Completions API 格式兼容的接口，因此 OpenCode 可以直接调用 GLM 模型进行代码生成、分析和调试。

## 许可证

本工具仅供学习和个人使用。OpenCode 基于 MIT 协议开源。智谱 GLM API 的使用须遵守智谱的服务条款。
