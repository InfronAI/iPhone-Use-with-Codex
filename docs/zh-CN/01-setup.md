# 从零安装和配置全部环境

[English](../01-setup.md) | **简体中文** · [文档目录](README.md)

本章从尚未下载项目的 Mac 开始。每一步都确认检查点通过后再继续。完成后进入[首次完整运行](09-first-run.md)，部署游戏并操控真机。

## 0. 准备清单

| 项目 | 用途 |
|---|---|
| 能运行所选 Xcode 版本的 Mac | 构建并签名 iOS App 和 XCTest Runner |
| 真实 iPhone 和支持数据传输的 USB 线 | 在自己的设备上运行 App 与自动化 |
| 能在 Xcode 登录的 Apple 账户 | 开发签名；使用账户可用的 Personal Team 或组织 Team |
| 有 Codex 使用权限的账户或登录方式 | 在 Mac 上运行编程代理 |
| 安装期间可用的网络 | 下载工具、登录账户并完成签名配置 |

在 ** → 关于本机** 查看 macOS 与硬件，在 **iPhone 设置 → 通用 → 关于本机** 查看 iOS；对照 [Apple 的 Xcode 兼容表](https://developer.apple.com/support/xcode/)。我们记录的 Xcode 27.1 / iPhone 13 mini 环境是验证证据，不是通用最低要求。App 的最低部署目标是 iOS 17.0，但完整操控流程没有在所有版本上验证。

下面使用 Codex 独立安装器和 Python 标准库。运行本示例不需要预装 Homebrew、Node.js、npm、Appium、WebDriverAgent、XcodeGen、CocoaPods，也不需要购买 App Store 发布会员。Apple 账户仍受各自能力和限制约束，参见 [Apple 账户说明](https://developer.apple.com/help/account/basics/about-your-developer-account)。

## 1. 安装完整 Xcode

1. 在 Mac 打开 [Xcode 的 App Store 页面](https://apps.apple.com/app/xcode/id497799835)并安装。如果 Mac 需要其他兼容版本，使用 [Apple Developer Downloads](https://developer.apple.com/download/all/?q=Xcode)。
2. 打开 **应用程序 → Xcode**，同意许可并完成提示的组件安装。
3. 如果提示选择平台组件，安装 iOS。以后发现缺少组件，可以到 Xcode Settings 的 Components / Platforms 页面补装，具体名称随版本变化。
4. 等安装完成再运行构建命令。本流程使用真实 iPhone，模拟器运行时不是验证所用的设备。

通过聚焦搜索打开 **终端 Terminal**（`⌘Space`，输入 Terminal）。下文命令都粘贴到终端，不需要加 `$` 提示符。

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
xcode-select -p
xcodebuild -version
xcodebuild -showsdks
```

如果 Xcode 安装在其他位置，替换成实际路径。`sudo` 要求的是 Mac 登录密码；输入时终端不显示任何字符，属于正常现象。

**检查点：** `xcode-select -p` 的路径以 `Xcode.app/Contents/Developer` 结束，`xcodebuild -version` 输出版本，SDK 列表包含 iOS / `iphoneos`。如果路径是 `/Library/Developer/CommandLineTools`，说明尚未选中完整 Xcode。仅安装 Command Line Tools 无法构建本 iPhone 项目。

## 2. 检查 Git 和 Python

在同一终端运行：

```bash
git --version
python3 --version
xcrun --find devicectl
xcrun --find swiftc
```

**检查点：** Git 输出版本；Python 为 **3.9 或更新版本**；两个 Xcode 工具均返回可执行文件路径。

如果没有 Python 或版本过低，从 [Python.org](https://www.python.org/downloads/macos/) 下载适合当前 macOS 的 Python 3 安装包，打开 `.pkg` 并完成安装，然后新开终端重新检查 `python3 --version`。本仓库无需运行 `pip install`，也无需配置 Python 虚拟环境。缺少 Git 或 Xcode 工具时，先完成 Xcode 安装。

## 3. 安装并登录 Codex

[Codex CLI 官方教程](https://learn.chatgpt.com/docs/codex/cli)提供以下 macOS 独立安装命令：

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

按照安装器输出完成 PATH 配置，如有提示则新开一个终端窗口。然后运行：

```bash
codex --version
codex login
codex login status
```

在 `codex login` 打开的浏览器中完成登录，再返回终端。如果无法打开浏览器，可在当前环境支持时改用 `codex login --device-auth`。[CLI 命令参考](https://learn.chatgpt.com/docs/cli/reference)说明了登录与状态查询命令。

**检查点：** `codex --version` 输出版本，`codex login status` 显示已登录。找不到 `codex` 时，按安装器输出修正 PATH，不要反复安装多个副本。登录成功不等于账户一定有使用权限或可用额度，请使用有 Codex 访问权限的账户。

项目中的 Python 脚本不直接调用 OpenAI API。不要把 API Key 写入 `config.local.json`；该文件只保存设备和签名配置。

## 4. 下载项目

在终端执行一次：

```bash
mkdir -p ~/Projects
cd ~/Projects
git clone https://github.com/InfronAI/iPhone-Use-with-Codex.git
cd iPhone-Use-with-Codex
pwd
ls README.md HelloWorld.xcodeproj scripts/iphone.py
```

**检查点：** 三个路径都存在，`pwd` 以 `iPhone-Use-with-Codex` 结束。仓库公开，克隆无需 GitHub Token。已经克隆过的读者直接 `cd` 进入已有目录，不要再往同名目录克隆。后续项目命令都在这个目录运行。

## 5. 连接、信任并解锁 iPhone

1. 使用支持数据传输的线连接手机；只能充电的线不够。
2. 解锁手机，在 **信任此电脑** 提示中选择信任，并在手机输入密码。
3. 打开工程：

```bash
open HelloWorld.xcodeproj
```

4. 在 Xcode 的运行目标菜单中进入设备管理，或打开 **Window → Devices and Simulators** / **Device Hub**，具体入口随版本变化。等待真实手机完成配对和准备。
5. 在手机打开 **设置 → 隐私与安全性 → 开发者模式**，开启后按提示重启，再解锁并确认。如果找不到入口，先完成 Xcode 配对并查看设备状态。参见 [Apple 开发者模式教程](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device)。
6. 首次运行期间保持手机连接并解锁。

```bash
python3 scripts/iphone.py devices
```

**检查点：** 选择标为 **physical** 的真实设备行，并确认其状态为当前 Xcode 对应的 connected / available。复制 UDID / Identifier，不要连同显示用的 `(UDID)` 后缀一起复制。不要选 simulated 行。仅看见设备名称或充电图标，不代表已经获得开发访问能力。

## 6. 登录 Apple 账户并设置唯一 App ID

在 Xcode → Settings → Apple Accounts（部分版本称 Accounts）添加 Apple 账户并完成认证。确认能看到 Personal Team 或组织 Team。本教程把开发构建部署到自己的设备，不上架 App Store。参见 [Apple 真机运行教程](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices)。

选择唯一的 bundle ID，例如 `dev.alex20261019.codexiphone`，其中用户名应换成**你自己的**标识。记录这个完整值，后续保持一致。

在已打开的工程中：

1. 按 `⌘1` 展示导航栏，点击蓝色的 **HelloWorld 工程**图标。
2. 在 **PROJECT** 下选择 **HelloWorld → Build Settings**，显示 **All** 设置，搜索 `APP_BUNDLE_ID`。
3. 将已有的这个自定义设置在 Debug 和 Release 中都改为你选定的 bundle ID。
4. 保留 App target 的 `PRODUCT_BUNDLE_IDENTIFIER` 为 `$(APP_BUNDLE_ID)`，UI test target 为 `$(APP_BUNDLE_ID).uitests`。不要将这两个表达式改成不相关的固定 ID。

**检查点：** App target 解析后的 bundle ID 等于你选定的值；测试 target 在其后加 `.uitests`。保留表达式，才能让 CLI 配置一致地控制两个 target。

## 7. 选择签名 Team 并获取 Team ID

1. 选择 **TARGETS → HelloWorld → Signing & Capabilities**。
2. 保持 **Automatically manage signing** 开启，在 **Team** 选择自己的团队。如果提示启用自动签名，确认启用。
3. 对 **TARGETS → HelloWorldUITests** 重复设置，选择同一个 Team。
4. 在 Xcode 的运行目标菜单选择真实 iPhone。遇到账户、设备注册或钥匙串提示，在系统界面处理。
5. 按 `⌘S` 保存工程。

如果 Team 菜单为空，先回到 Apple Accounts 解决登录或团队访问问题。选好后，在终端读取实际的 10 位 Team ID：

```bash
xcodebuild -project HelloWorld.xcodeproj -target HelloWorld \
  -configuration Debug -showBuildSettings \
  | sed -n 's/^[[:space:]]*DEVELOPMENT_TEAM = //p'
```

**检查点：** 输出包含你的 10 位团队标识，例如示意值 `ABCDE12345`；不是显示名称或邮箱。输出为空表示 target 的团队还没设好，或命令失败，应检查前面的报错。`DEVELOPMENT_TEAM` 是 [Apple 构建设置参考](https://developer.apple.com/documentation/xcode/build-settings-reference)中的团队 ID 设置。

在 Xcode 选择 Team 可能会修改 `project.pbxproj`。这些属于本机配置；参与贡献时不要公开个人签名设置。下面的 CLI 使用本地 JSON 参数，不需要提交这些修改。

## 8. 填写 config.local.json

如果尚未创建本地配置，先复制模板：

```bash
cp -n config.example.json config.local.json
nano config.local.json
```

替换以下三个值：

```json
{
  "device": "YOUR_IPHONE_UDID",
  "team": "YOUR_TEAM_ID",
  "bundle_id": "com.yourname.codexiphone"
}
```

| 字段 | 实际值从哪里获得 |
|---|---|
| `device` | 第 5 步的真实设备行，不包含注释或空格 |
| `team` | 第 7 步输出的 `DEVELOPMENT_TEAM` |
| `bundle_id` | 第 6 步选定的唯一值 |

在 nano 中按 `Control-O`，回车保存，再按 `Control-X` 退出。使用英文直引号，保留字段间的逗号，不要添加注释或末尾多余逗号。脚本会主动拒绝 `com.yourname.` 和 `com.example.` 前缀，因此 UDID、Team 和 bundle ID 都必须替换。

```bash
python3 -m json.tool config.local.json
git check-ignore config.local.json
```

**检查点：** 第一个命令打印合法 JSON；第二个输出 `config.local.json`，表示它已被 Git 忽略。这只能验证语法和忽略规则，真实设备与签名团队能否配合仍需部署验证。JSON 输出含本地标识，请留在本机。

## 9. 可选：连接 Xcode MCP

MCP 为 Codex 增加 Xcode IDE 工具。不连接这一可选组件，仍可使用 shell / XCTest 路线。

1. 保持 Xcode 打开 `HelloWorld.xcodeproj`。
2. 如果版本提供该功能，在 **Xcode → Settings → Intelligence → Model Context Protocol** 中启用外部代理访问 Xcode 工具。
3. 在终端检查桥接程序并注册：

```bash
xcrun --find mcpbridge
codex mcp add xcode -- xcrun mcpbridge
codex mcp list
codex mcp get xcode
```

如果已经注册 xcode，先检查现有配置，不要重复添加。修改 MCP 配置后新开 Codex 会话；出现 Xcode 的实际访问提示时予以处理。参见 [Apple 外部代理配置](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode)。

**检查点：** 使用 [MCP 教程](02-codex-xcode.md)中的实际发现提示词。`mcp list` 显示 enabled 不能证明连接成功。如果没有 mcpbridge 或对应设置，继续 CLI 路线即可，无需卡在可选功能上。

## 10. 操作手机前先验证安装

```bash
python3 scripts/iphone.py doctor
python3 scripts/iphone.py test-engine
python3 scripts/iphone.py build-for-testing
```

**检查点：** doctor 能解析工具路径；引擎检查输出 PASS；`build/build-for-testing.log` 结尾出现 `TEST BUILD SUCCEEDED`。这些检查不操作手机，也不能证明签名和安装已成功。

任一命令失败，先按[故障排查](05-troubleshooting.md)修复该步骤。如果命令仍在执行，在第二个终端查看它打印的日志，不要向同一构建目录再启动一次构建。

## 11. 进入首次完整运行

现在你已经准备好工程、Codex 登录、Xcode 工具、配对的 iPhone 和本地签名配置。继续[首次运行教程](09-first-run.md)：部署 → UI 测试 → 创建控制会话 → 观察 → 操作 → 验证 → 结束。教程包含两个终端的具体命令和每个阶段的预期结果。
