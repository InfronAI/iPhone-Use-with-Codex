# 从零准备环境

[English](../01-setup.md) | **简体中文** · [文档目录](README.md)

## 1. 安装完整 Xcode

从 [Mac App Store](https://apps.apple.com/app/xcode/id497799835) 或 [Apple Developer Downloads](https://developer.apple.com/download/all/?q=Xcode) 获取与你的 macOS 和 iPhone 系统匹配的 Xcode。使用 [Apple 兼容性表](https://developer.apple.com/support/xcode/)核对版本，避免把历史机器版本当作当前安装要求。

打开 Xcode，完成首次许可、平台和组件安装。只有 Command Line Tools 不足以编译和签名 iPhone App。

```bash
xcode-select -p
xcodebuild -version
xcrun --find devicectl
xcrun --find swiftc
```

若选中 `/Library/Developer/CommandLineTools`，可由本人执行：

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

也可以为当前终端设置 `DEVELOPER_DIR` 到你的 Xcode Developer 路径。不要在教程里固定他人的 Beta 安装位置。

## 2. 登录 Apple 账户并配置签名

在 Xcode → Settings → Apple Accounts（某些版本叫 Accounts）登录。打开本仓库 `HelloWorld.xcodeproj`，选择左侧工程图标，再选择 **TARGETS → HelloWorld → Signing & Capabilities**，启用自动签名并选择自己的 Team。UI 测试 target 也需要同一团队。

CLI 使用 `config.local.json` 中的 Team ID，并通过构建参数同时传给 App 与测试 target。因此建议把本地身份留在 JSON，不提交个人签名设置。Team ID 可从 Xcode 的团队信息或自己的 Apple Developer 账户取得；不要把证书名称中的人名当作 Team ID。

```json
{
  "device": "YOUR_IPHONE_UDID",
  "team": "YOUR_TEAM_ID",
  "bundle_id": "com.yourname.codexiphone"
}
```

把三个示例值全部替换。App bundle ID 必须唯一，UI 测试 ID 自动使用 `<bundle_id>.uitests`，Runner 使用 `<bundle_id>.uitests.xctrunner`。无需向 Codex 提供 Apple 密码或私钥。账户登录、双重验证和钥匙串提示在系统界面完成。

自动签名允许 Xcode 管理开发所需资源，实际可用能力和有效期由你的账户、描述文件和 Apple 规则决定。参考 [Apple 真机运行说明](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)。

## 3. 配对真实 iPhone

1. 使用可传数据的线缆连接 Mac，解锁 iPhone。
2. 在手机上信任电脑并完成锁屏密码确认。
3. 在 Xcode 的设备管理界面确认已配对、可用。
4. 按 [Apple 开发者模式说明](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)启用开发者模式，完成重启和确认。
5. 执行 `python3 scripts/iphone.py devices`，复制 physical 设备的 UDID，确认状态 connected。

不要复制 simulated 设备 ID。首次信任、锁屏密码、生物认证和开发者模式不能通过本控制桥代替本人完成。后续可用性以 `devicectl` 和 Xcode 实际状态为准。

## 4. 准备 Codex

可在能访问本机项目和终端的 Codex 环境中工作。CLI 安装、登录按 [Codex 官方说明](https://developers.openai.com/codex/cli)进行。在仓库目录启动 `codex`，让它先读取 `AGENTS.md`。本项目的 Python 脚本不直接调用 OpenAI API，因此不要求在仓库保存 API key。

Xcode MCP 是可选增强，见[下一章](02-codex-xcode.md)。部署和 XCTest 控制桥可以直接由 Codex 调用 shell 驱动。

## 5. 环境验收

```bash
python3 scripts/iphone.py doctor
python3 scripts/iphone.py devices
python3 scripts/iphone.py test-engine
python3 scripts/iphone.py build-for-testing
```

`doctor` 检查工具路径，不证明签名和设备已授权。只有后续真机部署、启动和 UI 操作成功才完成端到端验收。
