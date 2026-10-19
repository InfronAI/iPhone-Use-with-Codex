# iPhone Use with Codex

**English** | [简体中文](README.zh-CN.md)

Control real iPhones with Codex, Xcode, and XCTest. Build and deploy iOS apps, inspect screens, automate UI interactions, and verify results with reusable scripts and bilingual tutorials.

This project follows a complete workflow on a physical iPhone: **write code → build and sign → install and launch → inspect the UI → tap, drag, and type → verify the result**.

It grew out of a real development session: a SwiftUI Hello World app became **Neon Strike (雷电 · 星空突袭)**, followed by UI automation in Lark. The repository includes a complete Xcode project, reusable control scripts, tests, and English and Chinese documentation. No jailbreak, Appium, or WebDriverAgent is required; the control scripts use the Python standard library and Xcode.

<img src="docs/images/game-start.png" width="260" alt="Historical screenshot from a physical iPhone: the Neon Strike start screen">

“Complete control” means an observable, executable, and verifiable UI workflow. It does not grant unrestricted access to iOS. Initial pairing, Developer Mode, Apple account access, and keychain authorization require the device owner. Some protected screens or apps may not support automation. Cross-app control depends on the device, iOS, Xcode, and target app.

## Capabilities

| Task | Implementation |
|---|---|
| Create or modify a SwiftUI app | Codex edits the project; Xcode MCP is optional |
| Build, sign, install, and launch | `xcodebuild` + `codesign` + `devicectl` |
| Inspect UI and screenshots | XCTest accessibility hierarchy + `XCUIScreen` screenshots |
| Tap, drag, and type | A persistent XCTest control bridge receives JSON from Python |
| Switch apps and verify lifecycle behavior | `XCUIApplication(bundleIdentifier:).activate()` |
| Avoid accidental retries after a timeout | Pending state, session IDs, sequential action IDs, and claiming before execution |
| Run regression checks | Deterministic game checks, protocol unit tests, and physical iPhone UI tests |

## Start from zero

Follow these steps in order. The [full installation guide](docs/01-setup.md) explains each screen, field, and checkpoint; the [first-run walkthrough](docs/09-first-run.md) then shows exactly what to run in both terminals. Use a Mac, a data-capable cable, a physical iPhone, an Apple account for development signing, and a Codex account with access. Check [Xcode/macOS/iOS compatibility](https://developer.apple.com/support/xcode/) before downloading. The app targets iOS 17.0; tested environments are listed in the [validation record](docs/06-validation.md).

### 1. Install Xcode, Git, and Python

Install [full Xcode](https://apps.apple.com/app/xcode/id497799835), open it once, accept the license, and finish installing iOS platform components. In Terminal (`⌘Space` → Terminal), run:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
xcodebuild -version
git --version
python3 --version
```

Use the actual Xcode path if different. Git is supplied with the Apple developer tools. Python must be **3.9+**; if missing, install a compatible macOS `.pkg` from [Python.org](https://www.python.org/downloads/macos/) and reopen Terminal. No Homebrew, Node.js, npm, or `pip install` is required for the route below. **Check:** all version commands succeed; Command Line Tools alone are insufficient.

### 2. Install and sign in to Codex

Use the [official standalone installer](https://learn.chatgpt.com/docs/codex/cli), follow its PATH instructions, and reopen Terminal if requested:

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
codex --version
codex login
codex login status
```

Finish the browser sign-in. **Check:** Codex prints its version and reports that you are signed in. Keep account credentials out of project files.

### 3. Download and open the project

```bash
mkdir -p ~/Projects
cd ~/Projects
git clone https://github.com/InfronAI/iPhone-Use-with-Codex.git
cd iPhone-Use-with-Codex
open HelloWorld.xcodeproj
python3 scripts/iphone.py doctor
```

Run all later commands from this repository directory. If you already cloned it, enter your existing copy. **Check:** Xcode opens the HelloWorld project and doctor resolves the developer tools.

### 4. Pair the phone and configure signing

1. Connect and unlock the iPhone, accept **Trust This Computer**, and wait for Xcode to finish pairing/preparing it.
2. Enable **iPhone Settings → Privacy & Security → Developer Mode**, restart and confirm if prompted. Keep the phone unlocked.
3. In **Xcode → Settings → Apple Accounts**, sign in. In the project, set **PROJECT → HelloWorld → Build Settings → APP_BUNDLE_ID** to your own unique value, such as `dev.yourhandle.codexiphone` with your own handle. Preserve the targets' `$(APP_BUNDLE_ID)` and `$(APP_BUNDLE_ID).uitests` expressions.
4. For **both** HelloWorld and HelloWorldUITests targets, open **Signing & Capabilities**, enable automatic signing, and select your Personal Team or organization team. Select the physical iPhone as the run destination and save (`⌘S`). See [the detailed setup steps](docs/01-setup.md) for finding each setting and the account prerequisites.

Read the device identifier and the selected team:

```bash
python3 scripts/iphone.py devices
xcodebuild -project HelloWorld.xcodeproj -target HelloWorld \
  -configuration Debug -showBuildSettings \
  | sed -n 's/^[[:space:]]*DEVELOPMENT_TEAM = //p'
cp -n config.example.json config.local.json
nano config.local.json
```

Replace **all three** template values:

```json
{
  "device": "YOUR_IPHONE_UDID",
  "team": "YOUR_TEAM_ID",
  "bundle_id": "com.yourname.codexiphone"
}
```

Use the **physical** device's identifier, without the displayed `(UDID)` suffix; the actual **10-character Team ID**, not the account name; and the **same unique bundle ID** you chose in Xcode. The script rejects the template bundle prefix. In nano, save with `Control-O`, Return, then exit with `Control-X`.

```bash
python3 -m json.tool config.local.json
git check-ignore config.local.json
```

**Check:** JSON parses and Git reports `config.local.json` as ignored. Full instructions, common mistakes, and optional Xcode MCP setup are in [Steps 5–9 of the setup guide](docs/01-setup.md).

### 5. Build, deploy, and verify real interaction

Run each command after the previous one finishes:

```bash
python3 scripts/iphone.py test-engine
python3 scripts/iphone.py build-for-testing
python3 scripts/iphone.py deploy
python3 scripts/iphone.py test-ui
```

**Check:** engine checks pass; the unsigned app and tests compile; the signed game appears on the phone; the UI test reports **1 test, 0 failures**. It exercises taps, dragging, bomb use, pause, restart, and returning from the background. Detailed logs and screenshots are under ignored `build/`. A successful unsigned build does not prove installation. Follow [first-run Steps 1–2](docs/09-first-run.md) for expected outputs and [troubleshooting](docs/05-troubleshooting.md) if a stage fails.

### 6. Ask Codex to operate the phone

After the previous test has exited, start Codex from the repository:

```bash
codex
```

Paste this task **into Codex**, not Terminal's shell:

> Read AGENTS.md, README.md, and docs/09-first-run.md. Confirm the connected physical iPhone and local configuration, and that no previous Runner is active. Prepare a new control session targeting Settings, keep run-control running, collect the current hierarchy and screenshot, then activate the configured sample app. Inspect the new evidence, send done, and wait for the Runner to exit. Use scripts/iphone.py. If an action times out, collect its original result without resending it. Report actual results and evidence paths without exposing personal identifiers.

**Check:** Codex runs tools and reads fresh results. For the exact manual commands, complete [the two-terminal walkthrough](docs/09-first-run.md). It shows how to copy the session path, collect result 0, switch apps, inspect screenshots, and exit normally. The [control reference](docs/04-device-control.md) adds tapping, dragging, text input, coordinates, and recovery. [More Codex prompts](docs/07-prompts.md) cover game interaction and other authorized workflows.

Xcode MCP is optional; [connect and test it separately](docs/02-codex-xcode.md) if you want IDE tools. The shell/XCTest workflow above works without it.

## Documentation

The default documentation is in English. Each page links to its complete Chinese counterpart; start from the [English index](docs/README.md) or [中文目录](docs/zh-CN/README.md).

1. [Project history: discussions, execution, and key decisions](docs/00-project-history.md)
2. [Set up your Mac, Xcode, Codex, and iPhone](docs/01-setup.md)
3. [Connect Xcode MCP and understand the CLI/IDE relationship](docs/02-codex-xcode.md)
4. [From Hello World to a game: build, sign, deploy, and test](docs/03-build-deploy.md)
5. [Control a physical iPhone: bridge protocol and the Lark case study](docs/04-device-control.md)
6. [Troubleshooting](docs/05-troubleshooting.md)
7. [Validation record and coverage](docs/06-validation.md)
8. [Reusable Codex prompts](docs/07-prompts.md)
9. [Official references and sources](docs/08-references.md)
10. [First complete run: both terminals, checkpoints, and Codex handoff](docs/09-first-run.md)

## Repository layout

```text
HelloWorld.xcodeproj/          Complete iPhone project with a shared scheme
HelloWorld/                   SwiftUI + SpriteKit game and icon assets
HelloWorldUITests/            Physical iPhone UI regression tests
Tests/GameEngineChecks.swift  Deterministic game checks without a device
Tests/test_control.py         Offline control-protocol regression tests
examples/HelloWorldView.swift Beginner Hello World screen
automation/ControlTests.swift Reusable XCTest bridge template for cross-app control
scripts/iphone.py             Deployment and interaction CLI; no third-party dependencies
scripts/GenerateAppIcon.swift Programmatic icon generator
docs/                        English tutorials and validation record (default)
docs/zh-CN/                  Complete Chinese counterparts
config.example.json          Local configuration template
AGENTS.md                    Project instructions for Codex
```

## Contributing and license

Before submitting code changes, run `python3 -B -m unittest discover -s Tests -v`, `python3 scripts/iphone.py test-engine`, and `python3 scripts/iphone.py build-for-testing`. The [GitHub Actions template](docs/ci/checks.yml.example) runs the same checks without a device. It has not been enabled because the token used for the initial publication lacked the `workflow` permission. With the required permission, copy it to `.github/workflows/checks.yml`. Cloud CI has neither your Apple signing credentials nor your iPhone and cannot replace physical-device tests.

Keep the English and Chinese documentation in sync. The repository retains its original [MIT License](LICENSE). The game is a teaching example and contains no assets from third-party commercial games.
