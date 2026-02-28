; ============================================================================
; Claude Code 安装程序 - Inno Setup 脚本
; 面向中国用户的一键安装工具
;
; 编译方法:
;   1. 下载 Inno Setup: https://jrsoftware.org/isinfo.php
;   2. 打开本文件，点击 Build -> Compile
;   3. 生成的安装包在 Output 目录下
; ============================================================================

#define AppName "Claude Code 安装助手"
#define AppVersion "1.0.0"
#define AppPublisher "Claude Code Community"
#define AppURL "https://github.com/anthropics/claude-code"

[Setup]
AppId={{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppSupportURL={#AppURL}
DefaultDirName={autopf}\ClaudeCode
DefaultGroupName=Claude Code
DisableProgramGroupPage=yes
LicenseFile=
OutputBaseFilename=ClaudeCode-Setup-v{#AppVersion}
SetupIconFile=
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64compatible
; 中文界面
ShowLanguageDialog=no

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Messages]
chinesesimplified.WelcomeLabel1=欢迎使用 Claude Code 安装助手
chinesesimplified.WelcomeLabel2=本程序将帮助您一键安装 Claude Code 及其所有依赖项（Node.js、Git），并配置国产大模型 API。%n%n建议关闭其他应用程序后再继续。
chinesesimplified.FinishedHeadingLabel=安装完成
chinesesimplified.FinishedLabel=Claude Code 已安装到您的计算机。%n%n请打开新的 PowerShell 或 CMD 窗口，运行 'claude' 命令开始使用。

[Files]
Source: "install.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "configure-api.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "一键安装.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "配置API.bat"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\Claude Code - 配置 API"; Filename: "{app}\配置API.bat"; IconFilename: "{sys}\shell32.dll"; IconIndex: 21
Name: "{group}\Claude Code - 重新安装"; Filename: "{app}\一键安装.bat"; IconFilename: "{sys}\shell32.dll"; IconIndex: 162
Name: "{group}\打开 PowerShell"; Filename: "powershell.exe"; WorkingDir: "{userdesktop}"
Name: "{commondesktop}\配置 Claude Code API"; Filename: "{app}\配置API.bat"; IconFilename: "{sys}\shell32.dll"; IconIndex: 21; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式 (API 配置工具)"; GroupDescription: "快捷方式:"

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\install.ps1"""; Description: "运行 Claude Code 安装程序"; Flags: runascurrentuser waituntilterminated postinstall shellexec; StatusMsg: "正在安装 Claude Code 及依赖..."

[Code]
// 自定义安装向导页面 - 选择 API 提供商
var
  ApiPage: TInputOptionWizardPage;

procedure InitializeWizard();
begin
  ApiPage := CreateInputOptionPage(wpSelectTasks,
    '选择 API 提供商',
    '由于网络限制，中国用户需要使用国产大模型 API',
    '请选择您计划使用的 API 提供商（安装后可随时更改）：',
    True, False);

  ApiPage.Add('智谱 GLM (ChatGLM) - https://open.bigmodel.cn');
  ApiPage.Add('DeepSeek - https://platform.deepseek.com');
  ApiPage.Add('月之暗面 Moonshot/Kimi - https://platform.moonshot.cn');
  ApiPage.Add('阿里通义千问 Qwen - https://dashscope.aliyuncs.com');
  ApiPage.Add('百度文心一言 ERNIE - https://qianfan.baidubce.com');
  ApiPage.Add('稍后手动配置');

  ApiPage.Values[0] := True; // 默认选择 GLM
end;

function GetApiProvider(): String;
begin
  if ApiPage.Values[0] then Result := '1'
  else if ApiPage.Values[1] then Result := '2'
  else if ApiPage.Values[2] then Result := '3'
  else if ApiPage.Values[3] then Result := '4'
  else if ApiPage.Values[4] then Result := '5'
  else Result := '7';
end;
