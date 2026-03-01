; ============================================================================
; OpenCode 安装程序 - Inno Setup 脚本
; 面向中国用户的一键安装工具 - 接入智谱 GLM
;
; 编译方法:
;   1. 下载 Inno Setup: https://jrsoftware.org/isinfo.php
;   2. 打开本文件，点击 Build -> Compile
;   3. 生成的安装包在 Output 目录下
; ============================================================================

#define AppName "OpenCode 安装助手"
#define AppVersion "1.0.0"
#define AppPublisher "OpenCode Community"
#define AppURL "https://opencode.ai"

[Setup]
AppId={{B2C3D4E5-F6A7-8901-BCDE-FA2345678901}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppSupportURL={#AppURL}
DefaultDirName={autopf}\OpenCode
DefaultGroupName=OpenCode
DisableProgramGroupPage=yes
LicenseFile=
OutputBaseFilename=OpenCode-Setup-v{#AppVersion}
SetupIconFile=
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesInstallIn64BitMode=x64compatible
ShowLanguageDialog=no

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Messages]
chinesesimplified.WelcomeLabel1=欢迎使用 OpenCode 安装助手
chinesesimplified.WelcomeLabel2=本程序将帮助您一键安装 OpenCode 及其依赖项（Node.js），并配置智谱 GLM API。%n%n安装完成后即可在终端中使用 OpenCode 进行 AI 辅助编程。%n%n建议关闭其他应用程序后再继续。
chinesesimplified.FinishedHeadingLabel=安装完成
chinesesimplified.FinishedLabel=OpenCode 已安装到您的计算机。%n%n请打开新的 PowerShell 或 CMD 窗口，运行 'opencode' 命令开始使用。

[Files]
Source: "install-opencode.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "configure-glm.ps1"; DestDir: "{app}"; Flags: ignoreversion
Source: "一键安装OpenCode.bat"; DestDir: "{app}"; Flags: ignoreversion
Source: "配置智谱API.bat"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\OpenCode - 配置智谱 API"; Filename: "{app}\配置智谱API.bat"; IconFilename: "{sys}\shell32.dll"; IconIndex: 21
Name: "{group}\OpenCode - 重新安装"; Filename: "{app}\一键安装OpenCode.bat"; IconFilename: "{sys}\shell32.dll"; IconIndex: 162
Name: "{group}\打开 PowerShell"; Filename: "powershell.exe"; WorkingDir: "{userdesktop}"
Name: "{commondesktop}\配置 OpenCode 智谱 API"; Filename: "{app}\配置智谱API.bat"; IconFilename: "{sys}\shell32.dll"; IconIndex: 21; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式 (API 配置工具)"; GroupDescription: "快捷方式:"

[Run]
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\install-opencode.ps1"""; Description: "运行 OpenCode 安装程序"; Flags: runascurrentuser waituntilterminated postinstall shellexec; StatusMsg: "正在安装 OpenCode 及依赖..."

[Code]
var
  ApiPage: TInputOptionWizardPage;

procedure InitializeWizard();
begin
  ApiPage := CreateInputOptionPage(wpSelectTasks,
    '配置智谱 GLM API',
    '使用智谱 GLM 作为 AI 模型提供商',
    '本工具通过智谱 GLM 的 OpenAI 兼容端点接入。安装完成后将引导您选择模型并配置 API Key。' + #13#10 + #13#10 + '推荐购买 GLM Coding Plan 获得最佳性价比。',
    True, False);

  ApiPage.Add('智谱 GLM - https://open.bigmodel.cn（安装后配置 API Key）');
  ApiPage.Add('稍后手动配置');

  ApiPage.Values[0] := True;
end;
