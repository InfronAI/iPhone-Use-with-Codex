# 在真实 iPhone 上完成首次运行

[English](../09-first-run.md) | **简体中文** · [文档目录](README.md)

先完成[安装与配置](01-setup.md)。本教程依次验证部署、自动化触摸交互、界面观察、切换 App 和正常退出会话。保持手机连接并解锁；逐步运行命令，遇到错误先解决，再继续下一步。

你将使用两个终端窗口。**终端 A 持续运行 XCTest Runner；终端 B 发送命令并读取结果。** 每个窗口的工作目录和变量相互独立。手机上有一个 UI 测试或控制 Runner 运行时，不要再启动第二个。

## 1. 安装并启动示例

打开终端 A。如果项目克隆在其他位置，将第一行替换为实际路径：

```bash
cd ~/Projects/iPhone-Use-with-Codex
python3 scripts/iphone.py deploy
```

该命令使用本地 Team ID 和 bundle ID 构建，校验代码签名，安装并启动 App，最后记录进程列表。遇到实际的 Apple 账户、钥匙串或设备提示时处理，然后等待命令返回。

**检查点：** 手机上出现 **雷电 · 星空突袭** 和开始按钮；命令成功结束，`build/` 中出现 `deploy-build.log`、`install.json`、`launch.json`。这比单独看见 `BUILD SUCCEEDED` 更能证明部署完成。失败时查看命令打印的日志并参考[故障排查](05-troubleshooting.md)，暂时不要启动控制会话。

## 2. 验证点击、拖动和前后台行为

deploy 完成后，在终端 A 运行：

```bash
python3 scripts/iphone.py test-ui
tail -n 25 build/test-ui.log
```

观察真实手机。测试会开始游戏、拖动战机、使用炸弹、暂停、重新开始、切到设置并返回；它会断言炸弹数量从 3 变成 2，以及回到 App 后进入暂停状态。测试过程中手动触碰手机可能干扰断言。

**检查点：** 日志报告 **1 个测试，0 失败** 和 `TEST SUCCEEDED`。CLI 将三张截图附件导出到 `build/UITests-<unique-id>.attachments/`；这里的 `<unique-id>` 只是生成目录名的说明，不需要输入。对应的 `.xcresult` 可通过访达在 Xcode 中打开。等待 CLI 完全返回，包括完成附件导出，才能继续。

## 3. 在终端 A 准备控制会话

首次手动会话先打开设置，再切换到示例 App。这样读教程时起始页面保持稳定；前面的 UI 回归测试已经执行了对时机敏感的游戏操作。

```bash
python3 scripts/iphone.py prepare-control --app com.apple.Preferences
```

输出有三行，分别以 `Session:`、`Terminal A:`、`Terminal B:` 开头。第一行是 `build/control/` 下新目录的完整路径。每次 prepare 都创建不同会话。

为了准确保存路径而不用修改占位符，运行：

```bash
read -r SESSION
```

终端此时等待输入一行内容。**只粘贴 `Session:` 后的完整路径，然后回车。** 不要粘贴 `Session:` 标签、引号，或另外两行中的命令。随后检查：

```bash
ls "$SESSION/session.json"
```

**检查点：** `ls` 输出已存在的会话 JSON 路径。如果提示“No such file”，先重新执行 `read` 并填写正确路径，再继续。

保存路径供终端 B 使用，然后启动 Runner：

```bash
printf '%s\n' "$SESSION" > build/current-control-session.txt
python3 scripts/iphone.py run-control "$SESSION"
```

**保持终端 A 运行。** 它会输出 `Log:` 路径，在 Xcode 构建、签名、安装并启动 Runner 期间，终端可能没有新文字。这是正常现象：详细输出在 `runner.log`。只有会话结束或出错时，才会返回 shell 提示符。

## 4. 在终端 B 获取首次观察

新开第二个终端窗口（`⌘N`），重新进入项目目录。如果克隆在其他位置，使用与终端 A 相同的实际路径：

```bash
cd ~/Projects/iPhone-Use-with-Codex
SESSION="$(cat build/current-control-session.txt)"
python3 scripts/iphone.py collect "$SESSION" --timeout 420
```

`collect` 等待 Runner 的结果，不会启动另一个 Runner。首次结果编号为 0。返回后查看两种证据：

```bash
sed -n '1,80p' "$SESSION/hierarchy-0.txt"
open "$SESSION/screen-0.png"
```

**检查点：** 终端打印 `Observed:` 和 `Screenshot:` 路径；文本中能辨认设置 App（`com.apple.Preferences`），PNG 显示当前设置页面。设置会沿用原来的导航位置，因此显示根列表或先前打开的子页面都可能是正常结果。

等待超时时，在终端 B 检查启动日志：

```bash
tail -n 50 "$SESSION/runner.log"
python3 scripts/iphone.py collect "$SESSION" --timeout 420
```

只有 Runner 仍在启动或运行时才继续收集。如果终端 A 已经失败退出，先修复报错，再准备新会话。不要再次运行同一个会话，也不要手工清空会话状态。

## 5. 观察、切换 App 并核验

继续在终端 B 请求新的观察：

```bash
python3 scripts/iphone.py action "$SESSION" snapshot
open "$SESSION/screen-1.png"
```

接着读取本地配置中的 bundle ID，激活示例 App：

```bash
APP_BUNDLE_ID="$(python3 -c 'import json; print(json.load(open("config.local.json"))["bundle_id"])')"
python3 scripts/iphone.py action "$SESSION" activate --bundle "$APP_BUNDLE_ID"
sed -n '1,80p' "$SESSION/hierarchy-2.txt"
open "$SESSION/screen-2.png"
```

**检查点：** 手机和观察结果都已显示示例游戏，界面树中的 App 标识与本地配置一致。由于 Xcode 可能重新启动过 App，画面可以是菜单，也可以是暂停中的游戏；二者都能证明这次切换成功。如果 PNG 恰好拍到过渡动画，再请求一次 `snapshot`，查看该命令新打印的文件路径。

上面的编号假设你严格执行了列出的动作。如果额外截图，计数会递增，应使用 CLI 实际返回的路径。接下来想尝试点击、拖动或输入，请阅读[动作参考](04-device-control.md)，依据最新 UI 选择目标，不要沿用旧页面的坐标或按钮。

动作超时表示结果未知。使用同一会话的 `collect` 获取原动作结果。在解决 pending 状态之前，不要重发动作，也不要发送 `done`。

## 6. 正常结束会话

在终端 B 运行：

```bash
python3 scripts/iphone.py action "$SESSION" done
```

等待终端 A 返回 shell 提示符，再检查日志：

```bash
tail -n 25 "$SESSION/runner.log"
```

**检查点：** done 返回最后一次观察；终端 A 成功退出，日志包含 `TEST SUCCEEDED`；`session.json` 中的 `closed` 为 `true`。该会话已经结束，不能复用。可以保留唯一会话目录用于本地复盘；`build/` 已被 Git 忽略，其中可能包含私人屏幕内容。

## 7. 让 Codex 执行同一流程

手动会话结束后，在空闲终端、项目目录内启动 Codex：

```bash
codex
```

将以下任务粘贴到 Codex，而不是 shell：

> 阅读 AGENTS.md、README.md 和 docs/zh-CN/09-first-run.md。使用 config.local.json 指定的已连接真实 iPhone。确认上一轮 Runner 已退出。部署示例 App，运行它的 UI 测试并报告结果。然后新建一个以系统设置为目标的控制会话，保持 run-control 运行，收集初始界面树和截图，激活本地配置中的示例 App，再核验新的观察结果。发送 done 并等待 Runner 退出。使用 scripts/iphone.py；如果动作超时，只收集原结果，不重发动作。报告实际结果和本地证据路径，不打印个人设备或签名标识。

可用的 shell / XCTest 路线不依赖 Xcode MCP。如果配置了 MCP，另用[发现提示词](02-codex-xcode.md)验证。出现实际的本地审批或账户提示时再处理，无需全局绕过权限。

**检查点：** Codex 实际运行了命令并读取新的观察结果。只有书面计划、MCP enabled 状态或旧截图，都不算本次执行完成。[更多提示词](07-prompts.md)提供游戏交互任务，以及如何将已获授权的任务适配到其他 App。

## 8. 产出检查与下一次运行

| 结果 | 查看位置 |
|---|---|
| 已签名 App 安装并启动 | 手机屏幕、`build/install.json`、`build/launch.json` |
| 游戏触摸回归通过 | `build/test-ui.log` 和唯一的 `.xcresult` / 附件目录 |
| 首次设置页面观察 | 本会话的 `hierarchy-0.txt` 与 `screen-0.png` |
| 成功切换到示例 App | `activate` 返回的界面树与 PNG |
| 控制会话正常退出 | done 的最终结果、`closed: true`、成功的 `runner.log` |

以后运行无需重新安装工具或复制配置。连接并解锁手机，进入项目目录，运行 `devices`；如果代码或签名变化，或者 App 已不在手机上，再运行 deploy。创建**新**控制会话并重复第 3–6 步。终端关闭后变量会消失；路径文件只在其会话仍有效时有用。如果更换手机、Team 或 bundle ID，应更新 `config.local.json`，重新部署后再操控。

本章是复现指南，不代表所有读者的 Mac 和 iPhone 都已经经过测试。[验证记录](06-validation.md)列出了实际执行及其范围。
