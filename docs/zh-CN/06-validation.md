# 验证记录

[English](../06-validation.md) | **简体中文** · [文档目录](README.md)

## 环境与证据分层

日期：2026-10-19；真实设备：iPhone 13 mini；历史会话记录 iOS 26.7.1；本次本机 Xcode 输出为 **27.1 / 27A9275**。App 最低部署目标为 iOS 17.0。未使用模拟器替代真实设备。

下表记录当前仓库整理期间实际执行的结果。原始项目的历史验证另列，不替代仓库版验证。个人签名、设备 ID、私有 UI 树和原始日志保留在本地忽略目录。文档翻译不代表重新执行了一轮真机测试。

## 当前仓库验证

| 项目 | 执行与结果 |
|---|---|
| 规则检查 | `python3 scripts/iphone.py test-engine`，PASS：生命周期、边界、战斗、计分、无敌期、结束、Boss、补给、帧率一致性 |
| 协议离线检查 | `python3 -B -m unittest discover -s Tests -v`，8 项通过 |
| 未签名构建 | `python3 scripts/iphone.py build-for-testing`，`TEST BUILD SUCCEEDED`，同时编译 App 和 UI 测试 |
| 真机签名构建 | `deploy` 的 `BUILD SUCCEEDED`，codesign 校验成功 |
| 安装与启动 | 修复 launch 参数顺序后，deploy 返回 0；App 安装和启动成功，进程列表出现 HelloWorld |
| 游戏真机 UI 回归 | `test-ui` 于 18:01:04 完成，1 个测试通过、0 失败；导出开始/战斗/暂停 3 张附件 |
| 控制桥读取 | Runner 编译签名启动成功，Python 从真机容器取回 hierarchy 和 PNG |
| 控制桥激活 | 从设置切到示例游戏，返回游戏界面 |
| 控制桥元素点击 | `tap-id startGame` 后出现 pauseGame / useBomb，炸弹数为 3 |
| 控制桥拖动 | drag 返回完成结果及新截图；规则移动边界另由引擎检查覆盖 |
| 控制桥坐标点击 | 从最新 UI 树定位设置搜索框，点击后出现 Keyboard Focused |
| 中英文输入 | 输入 `Codex测试`，新 UI 树的搜索框 value 完全一致；未修改系统设置 |
| 控制会话退出 | 返回示例 App 后发送 done，结果成功取回；最终控制测试于 18:13:09 通过，Runner 正常退出（51.839 秒） |

协议离线检查包括：传输失败保留 pending、超时后 collect 不重传、done 关闭会话、初始结果编号 0、非法坐标/空文本拒绝、旧会话回执拒绝、中文/特殊字符保持为数据，以及 launch 参数顺序。

## 本次发现并处理的问题

1. `devicectl process launch` 将 bundle ID 后参数当作应用参数，导致 `--device` 未识别。调整所有工具选项到 bundle ID 之前，并补回归检查；随后完整 deploy 成功。
2. 交互式游戏运行时，读取旧画面后游戏已进入其他状态，pauseGame 不再可点击。控制桥正确拒绝操作、停止 Runner，未猜测坐标继续。完整的顺序 UI 回归随后通过。
3. XCTest 仅设置 maximum allowance 时，仍可能使用默认 10 分钟超时。最终代码同时设置 default/maximum allowance 和 `executionTimeAllowance = 2100`，会话循环期限为 1800 秒。

最后一次短会话已验证修订代码可编译、启动、交互及正常退出；未另行运行满 30 分钟的耐久测试。

## 历史项目验证（本地会话与产物）

- Hello World：签名问题解决后，在同一真实 iPhone 安装启动成功。
- 游戏：2026-10-19 16:24:33 左右真机回归通过；原始游戏开始截图作为 README 插图。
- Lark：会话记录中，用户授权的单条问候经 UI 输入并发送，随后检查了消息气泡与状态图标。历史会话以“已发送”结束；没有服务器端送达审计，也不能证明接收方已读。

## 未宣称的覆盖

- 没有在所有 iPhone、iOS 17+ 或所有 Xcode 版本上验证。
- 本次整理没有给任何 Lark 联系人再次发送消息。
- Home 事件、第三方 App 搜索和不同键盘行为仍依赖设备与 App；本次中文输入只在设置搜索框验证。
- CI 以 `docs/ci/checks.yml.example` 模板提供，尚未启用。GitHub 拒绝了包含 workflow 文件的推送，因为当前令牌缺少 workflow scope；为完成项目同步，保留模板供有权限时启用。CI 无法使用本地开发签名和这台 iPhone。
- 会话协议避免自动重复尝试，但无法对 UI 业务操作提供数据库事务或“恰好一次”保证。
