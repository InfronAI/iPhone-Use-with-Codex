# 资料与来源

[English](../08-references.md) | **简体中文** · [文档目录](README.md)

整理日期：2026-10-19。工具参数以本机 `--help` 和当前 MCP schema 为准；以下官方入口用于核对安装、能力和概念。

| 来源 | 本项目使用方式 |
|---|---|
| [原始分享讨论](https://chatgpt.com/share/6ad5e444-5d08-83e9-81ce-11020f88cd0d) | Xcode 安装、外部 Codex、MCP 配置和签名讨论 |
| [Codex CLI](https://developers.openai.com/codex/cli) | 本机终端启动与登录入口 |
| [AGENTS.md](https://developers.openai.com/codex/guides/agents-md) | 项目操作约定 |
| [Codex security](https://developers.openai.com/codex/security) | 沙箱和审批边界 |
| [Apple：Giving external agents access to Xcode](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode) | Intelligence 开关、mcpbridge、外部 Codex 配置 |
| [Apple：Setting up coding intelligence](https://developer.apple.com/documentation/xcode/setting-up-coding-intelligence) | 区分 Xcode 内置 agent 与外部连接 |
| [Apple：Xcode support](https://developer.apple.com/support/xcode/) | 工具与系统兼容性 |
| [Apple：Running your app on simulated or physical devices](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices) | 真机运行和账户准备 |
| [Apple：Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device) | 首次设备准备 |
| [Apple：XCUIAutomation](https://developer.apple.com/documentation/xcuiautomation) | UI 自动化基础 |
| [Apple：XCUIApplication](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication) | 启动、激活与观察目标 App |

本机实际读取的命令帮助：

```bash
xcrun devicectl help device process launch
xcrun devicectl help device copy to
xcrun devicectl help device capture screenshot
xcrun xcresulttool export attachments --help
```

历史本地会话与日志用于还原执行过程，未上传原始文件。本次验证的公开摘要位于 [06-validation.md](06-validation.md)，可复用源码是本仓库中的工程和脚本。原始讨论中未经本次验证的版本、功能和工具名称不会自动成为项目兼容性承诺。
