# iPhone Use with Codex

[English](README.md) | **简体中文**

用 **Codex + Xcode + XCTest + devicectl**，在真实 iPhone 上完成「写代码 → 编译签名 → 安装启动 → 看界面 → 点击/拖动/输入 → 验证结果」的完整闭环。

本项目来自一次实际开发：从 SwiftUI Hello World 到《雷电 · 星空突袭》，再到通过 iPhone 界面操作 Lark。提供完整 Xcode 工程、可复用控制脚本、测试和中英双语教程。无需越狱，无需 Appium / WebDriverAgent；控制脚本只依赖 Python 标准库和 Xcode。

<img src="docs/images/game-start.png" width="260" alt="历史真机截图：雷电星空突袭开始界面">

这里的“完整操控”指可观察、可执行、可验证的 UI 操作流程。它不是对 iOS 的无限权限：首次配对、开发者模式、Apple 账户和钥匙串授权需要本人完成，部分受保护页面或 App 可能不支持自动化。跨 App 控制的可用性取决于设备、iOS、Xcode 和目标 App。

## 能做什么

| 工作 | 实现 |
|---|---|
| 生成/修改 SwiftUI App | Codex 编辑工程；可选 Xcode MCP |
| 编译、签名、安装、启动 | `xcodebuild` + `codesign` + `devicectl` |
| 查看界面和截图 | XCTest 可访问性树 + `XCUIScreen` 截图 |
| 点击、拖动、输入文字 | 长运行 XCTest 控制桥，Python 下发 JSON |
| 切换 App、验证前后台 | `XCUIApplication(bundleIdentifier:).activate()` |
| 防止超时误重发 | pending 状态、会话 ID、顺序编号、执行前认领 |
| 回归验证 | 确定性游戏逻辑检查、协议单测、真实 iPhone UI 测试 |

## 从零开始

按以下步骤顺序操作。[完整安装教程](docs/zh-CN/01-setup.md)解释每个菜单、字段和检查点；[首次运行教程](docs/zh-CN/09-first-run.md)进一步给出两个终端的具体命令。准备 Mac、支持数据传输的线、真实 iPhone、用于开发签名的 Apple 账户和具有访问权限的 Codex 账户。下载前核对 [Xcode / macOS / iOS 兼容性](https://developer.apple.com/support/xcode/)。App 最低部署目标为 iOS 17.0；实际测试环境见[验证记录](docs/zh-CN/06-validation.md)。

### 1. 安装 Xcode、Git 和 Python

安装[完整 Xcode](https://apps.apple.com/app/xcode/id497799835)，首次打开后同意许可并完成 iOS 平台组件安装。打开终端（`⌘Space` → Terminal），执行：

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
xcodebuild -version
git --version
python3 --version
```

Xcode 安装位置不同时使用实际路径。Git 随 Apple 开发工具提供。Python 必须为 **3.9+**；没有则到 [Python.org](https://www.python.org/downloads/macos/) 安装兼容的 macOS `.pkg`，重新打开终端。下面的路线不要求 Homebrew、Node.js、npm 或 `pip install`。**检查：** 版本命令全部成功；仅安装 Command Line Tools 不够。

### 2. 安装并登录 Codex

使用[官方独立安装器](https://learn.chatgpt.com/docs/codex/cli)，按输出完成 PATH 配置，如有提示则重开终端：

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
codex --version
codex login
codex login status
```

在浏览器完成登录。**检查：** Codex 输出版本并报告已登录。账户凭据不要写进项目文件。

### 3. 下载并打开项目

```bash
mkdir -p ~/Projects
cd ~/Projects
git clone https://github.com/InfronAI/iPhone-Use-with-Codex.git
cd iPhone-Use-with-Codex
open HelloWorld.xcodeproj
python3 scripts/iphone.py doctor
```

后续命令都在此项目目录运行。已克隆过则进入已有副本。**检查：** Xcode 打开 HelloWorld 工程，doctor 能找到开发工具。

### 4. 配对手机并设置签名

1. 连接并解锁 iPhone，确认**信任此电脑**，等待 Xcode 完成配对和设备准备。
2. 开启 **iPhone 设置 → 隐私与安全性 → 开发者模式**，按提示重启并确认。保持手机解锁。
3. 在 **Xcode → Settings → Apple Accounts** 登录。在工程中将 **PROJECT → HelloWorld → Build Settings → APP_BUNDLE_ID** 改为自己的唯一值，例如将 `dev.yourhandle.codexiphone` 中的用户名换成自己的。保留两个 target 中的 `$(APP_BUNDLE_ID)` 与 `$(APP_BUNDLE_ID).uitests` 表达式。
4. 为 **HelloWorld 和 HelloWorldUITests 两个 target** 设置 **Signing & Capabilities**，开启自动签名，选择 Personal Team 或组织 Team。运行目标选择真实 iPhone，保存（`⌘S`）。具体菜单位置与账户要求见[详细配置步骤](docs/zh-CN/01-setup.md)。

读取设备标识和已选择的团队：

```bash
python3 scripts/iphone.py devices
xcodebuild -project HelloWorld.xcodeproj -target HelloWorld \
  -configuration Debug -showBuildSettings \
  | sed -n 's/^[[:space:]]*DEVELOPMENT_TEAM = //p'
cp -n config.example.json config.local.json
nano config.local.json
```

替换模板中的**全部三个值**：

```json
{
  "device": "YOUR_IPHONE_UDID",
  "team": "YOUR_TEAM_ID",
  "bundle_id": "com.yourname.codexiphone"
}
```

填写 **physical 真机**的标识，不包含显示用的 `(UDID)` 后缀；填写实际 **10 位 Team ID**，不是账户名称；bundle ID 与刚才在 Xcode 选择的**唯一值保持一致**。脚本会拒绝模板前缀。在 nano 中按 `Control-O`、回车保存，再按 `Control-X` 退出。

```bash
python3 -m json.tool config.local.json
git check-ignore config.local.json
```

**检查：** JSON 解析成功，Git 输出被忽略的 `config.local.json`。完整说明、常见错误与可选的 Xcode MCP 配置见[安装教程第 5–9 步](docs/zh-CN/01-setup.md)。

### 5. 构建、部署并验证真实交互

每条命令完成后再执行下一条：

```bash
python3 scripts/iphone.py test-engine
python3 scripts/iphone.py build-for-testing
python3 scripts/iphone.py deploy
python3 scripts/iphone.py test-ui
```

**检查：** 游戏逻辑检查通过；无签名 App 和测试编译完成；已签名游戏出现在手机上；UI 测试报告 **1 个测试、0 失败**。测试覆盖点击、拖动、炸弹、暂停、重开和后台返回。详细日志与截图写入被忽略的 `build/`。无签名构建成功不能证明安装成功。预期输出见[首次运行第 1–2 步](docs/zh-CN/09-first-run.md)，失败时按[故障排查](docs/zh-CN/05-troubleshooting.md)处理。

### 6. 让 Codex 操作手机

上一轮测试退出后，在项目目录启动 Codex：

```bash
codex
```

把以下任务粘贴到 **Codex 对话中**，不是终端 shell：

> 阅读 AGENTS.md、README.md 和 docs/zh-CN/09-first-run.md。确认当前连接的真实 iPhone、本地配置，以及上一轮 Runner 已退出。新建一个以系统设置为目标的控制会话，保持 run-control 运行，收集当前界面树和截图，再激活配置中的示例 App。核验新的观察结果，发送 done 并等待 Runner 退出。使用 scripts/iphone.py；动作超时时只收集原结果，不重发。报告实际结果和证据路径，不暴露个人标识。

**检查：** Codex 实际调用工具并读取新结果。需要逐条手动操作时，完成[双终端首次运行教程](docs/zh-CN/09-first-run.md)：它解释如何复制会话路径、获取结果 0、切换 App、查看截图并正常退出。[控制参考](docs/zh-CN/04-device-control.md)补充点击、拖动、文字输入、坐标和恢复方式。[更多提示词](docs/zh-CN/07-prompts.md)覆盖游戏交互和其他已获授权的任务。

Xcode MCP 是可选项；如果需要 IDE 工具，可以[单独连接并验证](docs/zh-CN/02-codex-xcode.md)。上述 shell / XCTest 流程无需 MCP 也能工作。

## 教程导航

项目默认展示英文，每篇教程均可切换到完整中文对应版。可以从[中文目录](docs/zh-CN/README.md)或 [English index](docs/README.md)开始。

1. [项目历程：分享讨论、真实执行与关键转折](docs/zh-CN/00-project-history.md)
2. [从零准备 Mac、Xcode、Codex 和 iPhone](docs/zh-CN/01-setup.md)
3. [连接 Xcode MCP，理解 CLI 与 IDE 的关系](docs/zh-CN/02-codex-xcode.md)
4. [从 Hello World 到游戏：构建、签名、部署和测试](docs/zh-CN/03-build-deploy.md)
5. [操控真机：控制桥协议与 Lark 案例](docs/zh-CN/04-device-control.md)
6. [故障排查](docs/zh-CN/05-troubleshooting.md)
7. [验证记录与适用范围](docs/zh-CN/06-validation.md)
8. [可复制的 Codex 提示词](docs/zh-CN/07-prompts.md)
9. [官方资料与来源](docs/zh-CN/08-references.md)
10. [首次完整运行：双终端、检查点与交给 Codex](docs/zh-CN/09-first-run.md)

## 项目结构

```text
HelloWorld.xcodeproj/           已共享 scheme 的完整 iPhone 工程
HelloWorld/                    SwiftUI + SpriteKit 游戏、图标资源
HelloWorldUITests/              真机交互回归测试
Tests/GameEngineChecks.swift   无设备、固定种子的战斗规则检查
examples/HelloWorldView.swift  初学者 Hello World 页面
automation/ControlTests.swift  可复用跨 App XCTest 控制桥模板
scripts/iphone.py              部署和交互统一入口（无第三方依赖）
scripts/GenerateAppIcon.swift  程序化图标生成器
Tests/test_control.py         控制协议离线回归测试
docs/                         英文教程与验证记录（默认）
docs/zh-CN/                   对应的中文教程
config.example.json           本地配置示例
AGENTS.md                     Codex 项目操作约定
```

## 贡献与许可

提交前运行 `python3 -B -m unittest discover -s Tests -v`、`python3 scripts/iphone.py test-engine` 和 `python3 scripts/iphone.py build-for-testing`。[GitHub Actions 模板](docs/ci/checks.yml.example)运行同样的无设备检查。首次发布使用的令牌缺少 workflow 权限，因此模板尚未启用；具备权限后将它复制到 `.github/workflows/checks.yml` 即可。云端 CI 不具备你的 Apple 证书和 iPhone，不能代替真机测试。

请同步维护英文与中文文档。沿用仓库原有 [MIT License](LICENSE)。示例游戏为教学演示，不含第三方商业游戏素材。
