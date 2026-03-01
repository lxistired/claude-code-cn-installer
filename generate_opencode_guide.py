"""生成 OpenCode 一键安装工具使用说明 PDF"""

import os
import platform
from fpdf import FPDF

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# ── 字体路径 ──────────────────────────────────────────────
# 优先 Windows 微软雅黑，Linux 回退文泉驿
if platform.system() == "Windows":
    FONT_REGULAR = "C:/Windows/Fonts/msyh.ttc"
    FONT_BOLD    = "C:/Windows/Fonts/msyhbd.ttc"
else:
    FONT_REGULAR = "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc"
    FONT_BOLD    = "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc"


class ChinesePDF(FPDF):
    def __init__(self):
        super().__init__()
        self.add_font("zh", "", FONT_REGULAR)
        self.add_font("zh", "B", FONT_BOLD)
        self.set_auto_page_break(auto=True, margin=20)

    def footer(self):
        self.set_y(-15)
        self.set_font("zh", "", 8)
        self.set_text_color(150, 150, 150)
        self.cell(0, 10, f"- {self.page_no()} -", align="C")


def build_pdf(path):
    pdf = ChinesePDF()
    pdf.set_margins(25, 20, 25)
    W = pdf.w - 50  # 可用宽度

    # ── 封面 / 标题 ──────────────────────────────────────
    pdf.add_page()
    pdf.ln(18)
    pdf.set_font("zh", "B", 24)
    pdf.set_text_color(26, 26, 46)
    pdf.cell(0, 14, "OpenCode 一键安装工具", align="C", new_x="LMARGIN", new_y="NEXT")

    pdf.set_font("zh", "", 13)
    pdf.set_text_color(100, 100, 100)
    pdf.cell(0, 10, "Windows 中国版 — 智谱 GLM  |  使用说明", align="C", new_x="LMARGIN", new_y="NEXT")

    pdf.ln(4)
    pdf.set_draw_color(200, 200, 200)
    pdf.line(25, pdf.get_y(), pdf.w - 25, pdf.get_y())
    pdf.ln(8)

    # ── 辅助函数 ──────────────────────────────────────────
    def heading(text, size=14):
        pdf.ln(4)
        pdf.set_font("zh", "B", size)
        pdf.set_text_color(44, 62, 80)
        pdf.cell(0, 10, text, new_x="LMARGIN", new_y="NEXT")
        pdf.ln(1)

    def body(text):
        pdf.set_font("zh", "", 10.5)
        pdf.set_text_color(30, 30, 30)
        pdf.multi_cell(0, 6.5, text)
        pdf.ln(1.5)

    def bullet(text):
        pdf.set_font("zh", "", 10.5)
        pdf.set_text_color(30, 30, 30)
        pdf.set_x(30)
        pdf.multi_cell(0, 6.5, f"-  {text}")
        pdf.ln(1)

    def numbered(num, text):
        pdf.set_font("zh", "", 10.5)
        pdf.set_text_color(30, 30, 30)
        pdf.set_x(30)
        pdf.multi_cell(0, 6.5, f"{num}.  {text}")
        pdf.ln(1)

    def code_block(lines):
        pdf.set_fill_color(243, 243, 243)
        pdf.set_font("zh", "", 9.5)
        pdf.set_text_color(50, 50, 50)
        for line in lines:
            pdf.set_x(30)
            pdf.cell(W - 5, 7, f"  {line}", fill=True, new_x="LMARGIN", new_y="NEXT")
        pdf.ln(3)
        pdf.set_text_color(30, 30, 30)

    def qa(q, a):
        pdf.set_font("zh", "B", 10.5)
        pdf.set_text_color(30, 30, 30)
        pdf.multi_cell(0, 6.5, f"Q: {q}")
        pdf.set_font("zh", "", 10.5)
        pdf.set_x(30)
        pdf.multi_cell(0, 6.5, f"A: {a}")
        pdf.ln(3)

    def table(headers, rows, col_widths=None):
        cols = len(headers)
        if col_widths is None:
            col_widths = [W / cols] * cols
        # 表头
        pdf.set_font("zh", "B", 9.5)
        pdf.set_fill_color(230, 240, 250)
        pdf.set_x(25)
        for i, h in enumerate(headers):
            pdf.cell(col_widths[i], 8, h, border=1, fill=True, align="C")
        pdf.ln()
        # 数据行
        pdf.set_font("zh", "", 9.5)
        pdf.set_text_color(30, 30, 30)
        for row in rows:
            pdf.set_x(25)
            for i, val in enumerate(row):
                pdf.cell(col_widths[i], 7.5, val, border=1, align="C")
            pdf.ln()
        pdf.ln(3)

    # ══════════════════════════════════════════════════════
    # 正文内容
    # ══════════════════════════════════════════════════════

    heading("一、工具简介")
    body("OpenCode 是一款开源的终端 AI 编程助手（类似 Claude Code），可以在终端中用自然语言编写、调试、重构代码。")
    body("本工具帮助 Windows 用户一键安装 OpenCode，并自动配置智谱 GLM API，无需翻墙，无需手动安装环境。")
    body("安装完成后，您只需填写 API Key，即可开箱即用！")

    heading("二、准备工作")
    body("在安装之前，您需要先在智谱平台注册并获取 API Key：")
    numbered(1, "打开 open.bigmodel.cn 注册账号")
    numbered(2, "（推荐）购买 GLM Coding Plan：open.bigmodel.cn/glm-coding")
    numbered(3, "获取 API Key：右上角头像 -> API 密钥 -> 创建")
    body("请先复制好 API Key，安装过程中需要粘贴。")

    heading("三、安装步骤（3 步搞定）")

    pdf.set_font("zh", "B", 11)
    pdf.set_text_color(0, 120, 60)
    pdf.cell(0, 8, "第 1 步：运行安装程序", new_x="LMARGIN", new_y="NEXT")
    body("右键点击「一键安装OpenCode.bat」-> 选择「以管理员身份运行」。")
    body("安装程序会自动完成以下工作（全程无需您操作）：")
    bullet("从国内镜像下载并安装 Node.js")
    bullet("配置 npm 国内镜像源（加速下载）")
    bullet("通过 npm 安装 OpenCode")

    pdf.set_font("zh", "B", 11)
    pdf.set_text_color(0, 120, 60)
    pdf.cell(0, 8, "第 2 步：选择模型和 API", new_x="LMARGIN", new_y="NEXT")
    body("安装完依赖后，脚本会引导您配置智谱 GLM：")
    numbered(1, "选择模型（默认 GLM-5 旗舰，直接按回车即可）")
    numbered(2, "选择 API 类型（推荐 Coding Plan，直接按回车）")
    numbered(3, "粘贴您在智谱平台获取的 API Key")

    pdf.set_font("zh", "B", 11)
    pdf.set_text_color(0, 120, 60)
    pdf.cell(0, 8, "第 3 步：开始使用", new_x="LMARGIN", new_y="NEXT")
    body("安装完成后，关闭安装窗口，打开一个新的 PowerShell 或 CMD 窗口：")
    code_block([
        "cd  你的项目文件夹路径",
        "opencode",
    ])
    body("就这么简单！OpenCode 交互界面会启动，您可以开始用自然语言编程了。")

    # ── 验证安装 ──────────────────────────────────────────
    heading("四、如何验证安装成功")

    body("安装结束时，脚本会自动检测安装状态。您也可以手动验证：")
    pdf.ln(1)

    pdf.set_font("zh", "B", 10.5)
    pdf.cell(0, 7, "检查 1：Node.js 是否安装成功", new_x="LMARGIN", new_y="NEXT")
    body("打开新的 PowerShell 窗口，输入：")
    code_block(["node --version"])
    body("如果看到类似 v22.13.1 的版本号，说明 Node.js 安装成功。")

    pdf.set_font("zh", "B", 10.5)
    pdf.cell(0, 7, "检查 2：OpenCode 是否安装成功", new_x="LMARGIN", new_y="NEXT")
    body("在同一窗口输入：")
    code_block(["opencode --version"])
    body("如果看到版本号（如 1.2.10），说明 OpenCode 安装成功。")

    pdf.set_font("zh", "B", 10.5)
    pdf.cell(0, 7, "检查 3：智谱 API 是否配置成功", new_x="LMARGIN", new_y="NEXT")
    body("运行「配置智谱API.bat」，选择 [3] 测试 API 连接。")
    body("如果看到「API 连接正常!」和模型回复内容，说明配置成功。")

    pdf.set_font("zh", "B", 10.5)
    pdf.cell(0, 7, "检查 4：实际运行测试", new_x="LMARGIN", new_y="NEXT")
    body("进入任意项目文件夹，运行 opencode，在对话框中输入：")
    code_block(["你好，请用中文介绍一下你自己"])
    body("如果模型正常回复，恭喜！一切就绪。")

    # ── Coding Plan 问题 ──────────────────────────────────
    heading("五、不用 Coding Plan 行不行？")

    pdf.set_font("zh", "B", 11)
    pdf.set_text_color(0, 100, 180)
    pdf.cell(0, 8, "完全可以！两种方式都支持。", new_x="LMARGIN", new_y="NEXT")
    pdf.set_text_color(30, 30, 30)
    pdf.ln(2)

    body("本工具支持两种智谱 API 接入方式：")

    table(
        ["对比项", "GLM Coding Plan（推荐）", "通用 API"],
        [
            ["计费方式", "订阅制（月付/季付）", "按量计费（充值余额）"],
            ["专属端点", "coding/paas/v4", "paas/v4"],
            ["价格", "约 20~100 元/月", "按 token 数计费"],
            ["并发数", "套餐越高并发越多", "普通并发"],
            ["适合场景", "日常编程，高频使用", "偶尔使用，轻量任务"],
        ],
        col_widths=[28, 66, 66],
    )

    body("如果您不想购买 Coding Plan，可以这样做：")
    numbered(1, "在智谱平台充值余额（通用 API 按量计费）")
    numbered(2, "安装时，在「选择 API 类型」步骤选择 [2] 通用 API")
    numbered(3, "其他步骤完全一样")

    body("或者安装后运行「配置智谱API.bat」重新配置，选择通用 API 即可。")

    pdf.ln(1)
    body("提示：GLM-4-Flash 是免费模型，使用通用 API 时选择该模型可以零成本体验！")

    # ── 模型选择建议 ──────────────────────────────────────
    heading("六、模型选择建议")

    table(
        ["模型", "定位", "推荐场景"],
        [
            ["GLM-5", "旗舰 745B MoE", "复杂编程、架构设计"],
            ["GLM-4.7", "编程增强", "日常编程、代码审查"],
            ["GLM-4.5", "Agent 基座", "工具调用、自动化流程"],
            ["GLM-4.7-Flash", "轻量快速", "简单问答、代码补全"],
            ["GLM-4-Flash", "免费模型", "轻量任务、零成本体验"],
        ],
        col_widths=[35, 45, 80],
    )

    body("建议：复杂任务用 GLM-5，日常编程用 GLM-4.7，省钱用 GLM-4.7-Flash。")
    body("在 OpenCode 中随时输入 /models 即可切换模型。")

    # ── 常见问题 ──────────────────────────────────────────
    heading("七、常见问题")

    qa(
        "运行 opencode 提示「不是内部或外部命令」？",
        "请关闭当前终端，打开一个新的 PowerShell 或 CMD 窗口再试。安装后环境变量需要新窗口才能生效。"
    )
    qa(
        "安装过程卡住或很慢？",
        "脚本已配置国内镜像源。如果仍然慢，可能是网络不稳定，请稍等或检查网络。"
    )
    qa(
        "API 测试失败？",
        "检查：(1) API Key 是否正确 (2) 账户是否有余额或有效套餐 (3) 网络是否正常。"
    )
    qa(
        "如何更换模型或 API Key？",
        "双击运行「配置智谱API.bat」，选择对应选项即可重新配置。"
    )
    qa(
        "OpenCode 中怎么切换模型？",
        "在 OpenCode 交互界面中输入 /models 命令，即可查看和切换可用模型。"
    )
    qa(
        "支持 Windows 7 吗？",
        "不支持。请使用 Windows 10 或更高版本，Node.js 22.x 已不支持 Windows 7。"
    )

    # ── 文件清单 ──────────────────────────────────────────
    heading("八、文件清单")

    table(
        ["文件", "用途"],
        [
            ["一键安装OpenCode.bat", "安装入口，右键以管理员身份运行"],
            ["配置智谱API.bat", "API 配置/切换/测试工具"],
            ["install-opencode.ps1", "安装主脚本（由 bat 调用）"],
            ["configure-glm.ps1", "配置脚本（由 bat 调用）"],
        ],
        col_widths=[65, 95],
    )

    # ── 页脚 ──────────────────────────────────────────────
    pdf.ln(6)
    pdf.set_draw_color(200, 200, 200)
    pdf.line(25, pdf.get_y(), pdf.w - 25, pdf.get_y())
    pdf.ln(4)
    pdf.set_font("zh", "", 8)
    pdf.set_text_color(150, 150, 150)
    pdf.cell(0, 6, "仅供学习和个人使用。OpenCode 基于 MIT 协议开源。智谱 GLM API 须遵守智谱服务条款。", align="C")

    pdf.output(path)
    print(f"[OK] PDF 已生成: {path}")


if __name__ == "__main__":
    pdf_path = os.path.join(OUTPUT_DIR, "OpenCode 使用说明.pdf")
    build_pdf(pdf_path)
