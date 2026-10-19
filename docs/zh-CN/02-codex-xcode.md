# Codex、Xcode MCP 与命令行

[English](../02-codex-xcode.md) | **简体中文** · [文档目录](README.md)

## 三种能力如何组合

```mermaid
flowchart TD
    U[用户描述目标] --> C[本机 Codex]
    C --> M[Xcode MCP：工程与 IDE 工具]
    C --> S[Shell：iphone.py]
    M --> X[Xcode]
    S --> B[xcodebuild：构建签名与 XCTest]
    S --> D[devicectl：发现/安装/启动/容器文件]
    B --> T[iPhone 上的 XCTest Runner]
    D --> P[已配对真实 iPhone]
    T --> A[目标 App]
    A --> O[界面树、截图、结果]
    O --> C
```

外部 Codex 通过 MCP 调用 Xcode，并不意味着把当前 Codex 进程“装进 Xcode”。Xcode 内置 coding agent 与外部 Codex 是不同入口。已有 Codex CLI 配置可以继续用于外部工作流。

## 连接 Xcode MCP

按 [Apple 官方步骤](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode)，在 Xcode → Settings → Intelligence 中允许外部 agent 使用 Xcode tools，然后在 Xcode 打开工程。

```bash
codex mcp add xcode -- xcrun mcpbridge
codex mcp list
codex mcp get xcode
xcrun --find mcpbridge
```

重新启动需要加载配置的 Codex 会话，然后要求它实际调用发现工具。列表中显示 enabled 只是配置存在，不是连接成功的证据。

本次可见工具包括 `XcodeListWorkspaces`、`XcodeListRunDestinations`、`BuildProject`、`GetBuildLog` 和 `DeviceInteractionStartSession`。历史讨论中的 `XcodeListWindows`、`tabIdentifier` 属于不同接口版本。使用当前工具描述返回的 workspace/session 标识，不能猜测。

## 用实际工具调用验证连接

先完成 [Codex 安装与登录](01-setup.md)。在终端进入项目目录，打开工程，再启动新的 Codex 会话：

```bash
open HelloWorld.xcodeproj
codex
```

把以下任务粘贴给 Codex：

> 使用已配置的 Xcode MCP 服务发现当前打开的工作区或工程。用返回的实际标识选择本仓库的 HelloWorld 工程，再列出它的运行目标。报告哪一个是真实连接的 iPhone，以及它是否可用。不要用模拟器替代，不要编造工具名称。如果服务或访问失败，报告实际错误。

**检查点：** 实际发现调用返回已打开的工程，随后设备结果标明真实设备。遇到 Xcode 的实际访问提示时先处理再重试。如果找不到工程，确认 Xcode 窗口已打开，新的 Codex 会话已加载 MCP 配置。Xcode 版本可能改变工具名称，具体接口以当前会话的 schema 为准。

MCP 不可用时，继续 [CLI 首次运行教程](09-first-run.md)。Xcode MCP 配置、Codex 账户访问和 Apple 设备签名是彼此独立的检查。

## 可选的 Xcode 直接设备交互

当当前 MCP 版本提供设备交互工具时，可按以下次序：

1. 发现工作区及真实设备，确认 active destination。
2. 调用 `DeviceInteractionStartSession` 或 workspace 版本，保存返回的 session key。
3. 调用 `DeviceInteractionSynthesize` 获取最新 hierarchy 和 screenshot；依据最新 hierarchy 定位后执行一步交互。
4. 读取新结果，任务结束调用 `DeviceInteractionEndSession`。

具体参数必须来自当前工具 schema。原始 Lark 任务曾遇到额外授权及工具发现差异，因此仓库同时提供无需该 MCP 交互 API 的 XCTest 控制桥。

## 保留正常权限边界

Codex 的 shell 沙箱可能无法访问 CoreDevice 服务、签名钥匙串或编译插件。实际失败时，应针对必要命令使用当前 Codex 的审批机制，并说明错误。不要把关闭所有审批当作安装步骤。参考 [Codex 权限说明](https://developers.openai.com/codex/security)。

Xcode / iPhone 的授权与 Codex 命令审批是独立的：shell 获准不代表签名账户、设备信任或 Xcode MCP 已授权。
