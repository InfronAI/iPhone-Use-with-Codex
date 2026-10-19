# iPhone Use with Codex 项目约定

[English](AGENTS.md) | **简体中文**

操作设备前先阅读 README.zh-CN.md 和 docs/zh-CN/04-device-control.md。

- 用明确的 UDID 选择真实 iPhone。不能用模拟器替代后声称是真机结果。
- 本地配置保存在忽略的 config.local.json。不要提交设备标识、个人 Team ID、描述文件、证书、私人 UI 树或原始会话记录。
- 文档中的流程使用 python3 scripts/iphone.py。发布的工程保持不含个人签名配置，并通过 APP_BUNDLE_ID 和 DEVELOPMENT_TEAM 参数化。
- 观察 → 按最新界面树定位 → 执行一个动作 → 检查界面树和截图。坐标是 app frame 内的 points，不是截图像素。
- 点击得到回执不等于业务操作成功，要检查实际界面结果。发送等外部动作的结果未知时，只收集原动作结果，不能重放。
- 用户已有授权持续有效。常规检查、修复和已授权操作无需反复询问。发送消息必须有明确的收件人和内容/范围授权；仅在意图缺失、收件人含糊或真实的系统/账户授权提示出现时暂停。
- 不绕过设备信任、开发者模式、签名、钥匙串或 Codex 沙箱审批。使用公开的 XCTest API。
- 修改协议或引擎后运行 python3 -B -m unittest discover -s Tests -v 和 python3 scripts/iphone.py test-engine。Swift 修改用 build-for-testing 验证。真机测试串行执行，不在同一手机并行运行两个 XCTest 会话。
- 在 docs/06-validation.md 及其中文版分别记录编译、签名、安装、启动和 UI 测试的实际结果，区分历史证据与本次运行。
- README.md 和 docs/*.md 默认使用英文；README.zh-CN.md 和 docs/zh-CN/ 提供完整中文对应版。同步维护语言切换链接和技术细节。用用户的语言交流，保留 MIT 许可证。
