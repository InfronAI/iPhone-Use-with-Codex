# 故障排查

[English](../05-troubleshooting.md) | **简体中文** · [文档目录](README.md)

先区分源码编译、签名、设备连接、测试运行器、UI 交互和业务结果。下一层成功不应靠上一层成功来推断。

| 现象 | 检查与处理 | 如何确认恢复 |
|---|---|---|
| `codex: command not found` | 按官方安装器输出配置 PATH，重开终端 | `codex --version` 与 `codex login status` 成功 |
| Python 缺失或低于 3.9 | 安装兼容的 Python.org macOS 安装包，重开终端 | `python3 --version` 为 3.9+ |
| `can't open file scripts/iphone.py` | 进入克隆的仓库；每个终端的目录独立 | `ls scripts/iphone.py` 成功 |
| JSON 解析错误 | 使用英文双引号、字段间逗号，不加注释或末尾逗号 | `python3 -m json.tool config.local.json` 成功 |
| 脚本拒绝 device / team / bundle ID | 替换全部模板值；Team ID 为 10 位，示例 bundle 前缀会被拒绝 | 配置检查通过，然后完成签名部署 |
| 获取 Team ID 的命令输出为空 | 为 App target 选择 Team 并保存，查看前面的 xcodebuild 报错 | DEVELOPMENT_TEAM 输出实际 ID，而非显示名称 |
| 安装的 bundle ID 与配置不同 | 恢复 target 表达式 `$(APP_BUNDLE_ID)` / `$(APP_BUNDLE_ID).uitests`；在工程 APP_BUNDLE_ID 和本地 JSON 填写所选值 | 已安装标识与配置的 App 一致 |
| 找不到会话 JSON 或路径文件 | 按首次运行第 3 步粘贴完整会话路径；两个终端进入同一仓库 | `ls "$SESSION/session.json"` 成功 |
| `xcodebuild` 提示只装了 Command Line Tools | 选择完整 Xcode Developer 目录、安装 iOS 平台 | doctor 输出正确路径和版本 |
| 找不到 `mcpbridge` | 核对安装版本与 `xcrun --find mcpbridge` | 命令存在、Codex 能实际调用工具 |
| MCP enabled，但找不到工程 | 在 Xcode 打开工程，允许外部 agent，重载 Codex 配置 | 当前发现工具返回工作区 |
| 旧文档中的 `XcodeListWindows` 不存在 | 查看当前 MCP 工具列表，使用当前 workspace 接口 | 实际工具调用成功 |
| `SwiftUIMacros.StateMacro` / plugin malformed response | 检查前面的 sandbox/权限报错，必要时批准对应构建命令重试 | 同一源码构建成功；不应为权限问题盲改 SwiftUI |
| `requires a development team` | 登录 Apple 账户、选 Team、填本地 10 位 Team ID | 签名构建成功并通过 codesign verify |
| bundle identifier 不可用 | 换成自己唯一的前缀；App 和 UI test 一起改 | Xcode 成功创建/找到 provisioning |
| 签名卡住 | 检查 Mac 上 codesign 的钥匙串提示，由本人处理 | 日志离开 CodeSign 并完成构建 |
| `unavailable` / 设备不见了 | 解锁、换数据线/端口、确认信任和开发者模式 | physical 设备 connected |
| 编译成功却安装失败 | 检查签名、描述文件、手机系统支持和锁定状态 | devicectl install 返回成功 |
| launch 报 missing `--device` | 所有选项放到 bundle ID 前面；后面的内容可能当作 App 参数 | launch.json 记录启动结果 |
| Home 事件后后台测试失败 | 不假设 Home 生效，检查 app.state，改用 activate 设置 | 明确进入后台，再返回暂停界面 |
| `Wait for ... to idle` 长时间不返回 | 看 runner.log，延长 collect，独立截图核对；不要重发动作 | 原动作 result 和新 UI 状态出现 |
| collect 初始结果一直不存在 | Runner 未启动、签名等待、错误 bundle ID、手机锁定；检查 runner.log | CODEX_CONTROL_READY 与 result-0 |
| Runner 在 10 分钟结束 | 只设 maximum allowance 不会覆盖默认时限；同时设 default allowance 和 XCTestCase.executionTimeAllowance | 新会话日志不再使用旧默认值 |
| pending 阻止后续动作 | 前一次结果未知，继续 collect；失败传输也可能部分完成 | 原动作结果确认后 pending 才清空 |
| tap-id 非唯一或不可点击 | 读取最新 hierarchy，找唯一可点击元素 | 只有一个可见匹配 |
| 截图与点击位置不一致 | points 与 pixels 混用、横竖屏变了、键盘弹出后坐标过时 | 用最新 UI 树重新定位 |
| 文字输入到了错误位置 | 先聚焦输入框，观察键盘/草稿 | 屏幕和层级显示正确内容 |
| 旧 Xcode 无 capture screenshot 命令 | 运行 `xcrun devicectl help device capture screenshot` 检查 | 使用控制桥截图或 XCTest 附件 |
| 网络下载失败且代理为本地端口 | 检查代理是否运行和当前执行权限 | 实际请求成功；不擅自删用户代理配置 |

## 最小诊断命令

```bash
python3 scripts/iphone.py doctor
python3 scripts/iphone.py devices
tail -n 50 build/deploy-build.log
tail -n 50 "$SESSION/runner.log"
python3 scripts/iphone.py collect "$SESSION" --timeout 240
```

`SESSION` 是实际控制会话路径。日志可能包含本机路径和个人数据，贴到公开 issue 前先删去敏感内容。

## 避免“看起来成功”

- `BUILD SUCCEEDED`：源码和目标构建成功，未必有签名。
- 安装成功：文件已安装，未必启动。
- 启动成功：进程创建，未必展示正确页面。
- 动作回执成功：XCTest 调用完成，未必满足任务。
- 业务成功：需要核对界面变化；对发送类任务仍不能从单张图推出服务器或接收方状态。

准确记录失败的层级，通常比重跑整个流程更快。
