# 从 Hello World 到可玩的游戏

## 先认识工程

本仓库直接提交 `.xcodeproj` 和 shared scheme，无需安装 XcodeGen。默认运行的是完整游戏；工程名保留 HelloWorld，便于对应历史流程。

| 文件 | 职责 |
|---|---|
| `HelloWorldApp.swift` | SwiftUI App 入口 |
| `ContentView.swift` | 开始/暂停/结算界面与生命周期处理 |
| `GameEngine.swift` | 独立规则、固定随机种子、敌机、弹幕、碰撞、Boss |
| `GameScene.swift` | SpriteKit 绘制与拖动手势 |
| `FlightUITests.swift` | 真机 UI 流程与截图附件 |

## 跟做 Hello World

如果要复现第一阶段，在一个独立 Git 分支中，把 `examples/HelloWorldView.swift` 的内容复制到 `HelloWorld/ContentView.swift`，再运行 deploy。该页面提供 Hello, World! 和计数按钮。不要同时把两个定义了 `ContentView` 的文件加入 target。

```bash
git switch -c tutorial/hello-world
cp examples/HelloWorldView.swift HelloWorld/ContentView.swift
python3 scripts/iphone.py deploy
```

可通过控制桥点击 `incrementCount` 并观察文字从 0 变成 1。现有 `test-ui` 是游戏测试，不适用于 Hello World 页面。要回到游戏，先保存自己的修改，再从 main 恢复 `ContentView.swift`；不要直接覆盖未保存工作。

## 编译与签名不是同一步

```bash
python3 scripts/iphone.py build
python3 scripts/iphone.py build-for-testing
```

这两项使用 generic iOS destination，设置 `CODE_SIGNING_ALLOWED=NO`，验证源码及 UI 测试能够编译。它们没有在模拟器或真机运行 App。

签名部署：

```bash
python3 scripts/iphone.py deploy
```

脚本实际执行：

1. 用配置中的 UDID 指定 `platform=iOS,id=…`。
2. 把 `DEVELOPMENT_TEAM` 和 `APP_BUNDLE_ID` 传给 xcodebuild；启用自动 provisioning 更新和设备注册。
3. 校验产物签名。
4. 安装 `.app` 到该手机。
5. 启动对应 bundle ID，记录启动结果和设备进程。

任意步骤失败立即返回非零退出码，日志保留在 `build/`。`install.json`、`launch.json`、`processes.json` 是本地证据，不应原样提交公共仓库。

若想理解底层命令，可用自己的值在终端执行：

```bash
xcodebuild -project HelloWorld.xcodeproj -scheme HelloWorld \
  -configuration Debug -destination "platform=iOS,id=$IPHONE_UDID" \
  -derivedDataPath build/Signed \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
  "DEVELOPMENT_TEAM=$APPLE_TEAM_ID" "APP_BUNDLE_ID=$APP_BUNDLE_ID" build

codesign --verify --deep --strict build/Signed/Build/Products/Debug-iphoneos/HelloWorld.app
xcrun devicectl device install app --device "$IPHONE_UDID" \
  build/Signed/Build/Products/Debug-iphoneos/HelloWorld.app
xcrun devicectl device process launch --device "$IPHONE_UDID" \
  --terminate-existing "$APP_BUNDLE_ID"
```

上面的三个 shell 变量需要自行设置；常规使用推荐 JSON + CLI。`process launch` 的选项必须放在 bundle ID 之前，否则尾部参数可能被当作 App 的启动参数。

## 为什么拆分规则和 UI

游戏规则在 Mac 上即可运行，消除签名、UI 时序和手机连接的影响：

```bash
python3 scripts/iphone.py test-engine
```

检查开始前不能消耗炸弹、移动边界、自动开火、暂停冻结、炸弹得分不重复、库存不为负、伤害无敌期、游戏结束、Boss 与补给、帧率一致性。使用 `precondition`，脚本不启用会去掉检查的 `-Ounchecked`。

真机 UI 检查则回答“人在手机上能不能操作”：

```bash
python3 scripts/iphone.py test-ui
```

执行出击、拖动、消耗一枚炸弹、暂停、重开、切换设置、返回自动暂停和继续。按钮通过稳定的 accessibility identifier 定位。源码里已包含的截图附件保留在独立 `.xcresult`，并自动导出到对应 `.attachments` 目录。

## 迭代与恢复

修改代码后重新执行规则检查、必要构建和真机测试，再 deploy。相同 bundle ID 会更新原 App；新 bundle ID 会并存为另一 App。本仓库不会自动卸载原始项目，也不会触碰手机上无关的应用数据。

`scripts/GenerateAppIcon.swift` 可在仓库根目录通过 `swift scripts/GenerateAppIcon.swift` 重新生成游戏图标；现成 PNG 已提交，日常构建不依赖重新生成。
