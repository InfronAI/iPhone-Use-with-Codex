# References and sources

**English** | [简体中文](zh-CN/08-references.md) · [Documentation index](README.md)

Prepared on October 19, 2026. Use local `--help` output and the current MCP schema for tool arguments. The official pages below provide setup instructions and explain capabilities and concepts.

| Source | Use in this project |
|---|---|
| [Original shared discussion](https://chatgpt.com/share/6ad5e444-5d08-83e9-81ce-11020f88cd0d) | Xcode installation, external Codex, MCP configuration, and signing discussions |
| [Codex CLI](https://developers.openai.com/codex/cli) | Local terminal usage and sign-in |
| [Codex standalone installation](https://learn.chatgpt.com/docs/codex/cli) | Installer and initial terminal setup |
| [Codex CLI reference](https://learn.chatgpt.com/docs/cli/reference) | Login, login status, and MCP commands |
| [Python macOS downloads](https://www.python.org/downloads/macos/) | Python installation if not already available |
| [Apple: Xcode downloads](https://developer.apple.com/download/all/?q=Xcode) | Alternative compatible Xcode releases |
| [Apple: Developer accounts](https://developer.apple.com/help/account/basics/about-your-developer-account) | Account/team capabilities and local development |
| [Apple: Build settings](https://developer.apple.com/documentation/xcode/build-settings-reference) | DEVELOPMENT_TEAM and build configuration |
| [AGENTS.md](https://developers.openai.com/codex/guides/agents-md) | Project instructions |
| [Codex security](https://developers.openai.com/codex/security) | Sandbox and approval boundaries |
| [Apple: Giving external agents access to Xcode](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode) | Intelligence settings, mcpbridge, and external Codex setup |
| [Apple: Setting up coding intelligence](https://developer.apple.com/documentation/xcode/setting-up-coding-intelligence) | Built-in Xcode agents versus external connections |
| [Apple: Xcode support](https://developer.apple.com/support/xcode/) | Tool and operating-system compatibility |
| [Apple: Running your app on simulated or physical devices](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices) | Account preparation and physical-device execution |
| [Apple: Developer Mode](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device) | Initial device setup |
| [Apple: XCUIAutomation](https://developer.apple.com/documentation/xcuiautomation) | UI automation fundamentals |
| [Apple: XCUIApplication](https://developer.apple.com/documentation/xcuiautomation/xcuiapplication) | Launching, activating, and observing the target app |

Local command help inspected during the project:

```bash
xcrun devicectl help device process launch
xcrun devicectl help device copy to
xcrun devicectl help device capture screenshot
xcrun xcresulttool export attachments --help
```

Historical local sessions and logs were used to reconstruct the work; the raw files were not uploaded. The public summary is in [06-validation.md](06-validation.md), and the reusable implementation is the project and scripts in this repository. Versions, capabilities, or tool names mentioned in the original discussion do not become compatibility promises unless they were actually verified.
