# Install and configure everything from scratch

**English** | [简体中文](zh-CN/01-setup.md) · [Documentation index](README.md)

This chapter starts with a Mac that does not yet have the project. Complete each checkpoint before continuing. Then follow [the first complete run](09-first-run.md) to deploy the game and operate the phone.

## 0. What you need

| Item | Purpose |
|---|---|
| A Mac compatible with your chosen Xcode version | Build and sign the iOS app and XCTest Runner |
| A physical iPhone and a data-capable USB cable | Run the app and automation on your own device |
| An Apple account you can sign into in Xcode | Development signing; use a Personal Team or your organization team as available |
| A Codex account/sign-in method with access to Codex | Run the coding agent on the Mac |
| Internet access during setup | Download tools and allow account/provisioning operations |

Check ** → About This Mac** for macOS and hardware, and **iPhone Settings → General → About** for iOS. Compare these against [Apple's Xcode compatibility table](https://developer.apple.com/support/xcode/). Our recorded Xcode 27.1/iPhone 13 mini setup is evidence, not a universal minimum. The app targets iOS 17.0, but the full control workflow has not been verified on every version.

The route below uses the Codex standalone installer and Python's standard library. Homebrew, Node.js, npm, Appium, WebDriverAgent, XcodeGen, CocoaPods, and a paid App Store publishing account are not prerequisites for this sample. Apple account capabilities and restrictions still apply; see [Apple's account overview](https://developer.apple.com/help/account/basics/about-your-developer-account).

## 1. Install full Xcode

1. Open the [Xcode App Store page](https://apps.apple.com/app/xcode/id497799835) on the Mac and install Xcode. If your Mac needs another compatible version, use [Apple Developer Downloads](https://developer.apple.com/download/all/?q=Xcode).
2. Open **Applications → Xcode**. Accept the license and complete any requested component installation.
3. Install the iOS platform components if offered. If missing later, use Xcode Settings and its Components/Platforms section, whose name varies by version.
4. Wait for installation to finish before running build commands. This workflow uses a physical iPhone; a simulator runtime is not the device used for validation.

Open **Terminal** through Spotlight (`⌘Space`, type Terminal). Commands in this guide are pasted into Terminal, without a leading `$` prompt.

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
xcode-select -p
xcodebuild -version
xcodebuild -showsdks
```

Use your actual application path if Xcode is installed elsewhere. `sudo` asks for the Mac login password; Terminal does not display characters while you type it.

**Checkpoint:** `xcode-select -p` ends in `Xcode.app/Contents/Developer`, `xcodebuild -version` prints a version, and the SDK list includes iOS / `iphoneos`. If the path is `/Library/Developer/CommandLineTools`, full Xcode is not selected. Command Line Tools alone cannot build this iPhone project.

## 2. Check Git and Python

In the same terminal:

```bash
git --version
python3 --version
xcrun --find devicectl
xcrun --find swiftc
```

**Checkpoint:** Git prints a version, Python is **3.9 or newer**, and both Xcode tools resolve to executable paths.

If Python is missing or too old, download a compatible Python 3 macOS installer from [Python.org](https://www.python.org/downloads/macos/), open the `.pkg`, follow its installer, then open a new Terminal window and check `python3 --version` again. This repository needs no `pip install` or Python virtual environment. If Git or Xcode tools are missing, finish Xcode setup before continuing.

## 3. Install Codex and sign in

The [official Codex CLI guide](https://learn.chatgpt.com/docs/codex/cli) provides this standalone macOS installer:

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

Follow the installer's PATH instructions and open a new Terminal window if requested. Then run:

```bash
codex --version
codex login
codex login status
```

Complete the browser sign-in opened by `codex login`, then return to Terminal. If the browser cannot be opened, `codex login --device-auth` is an alternative when supported by your environment. The [CLI reference](https://learn.chatgpt.com/docs/cli/reference) documents both login and status commands.

**Checkpoint:** `codex --version` prints a version and `codex login status` reports a signed-in state. If `codex` is not found, fix the PATH using the installer's output rather than installing several copies. A successful login does not by itself establish account entitlement or available usage; use an account with Codex access.

The project's Python scripts do not call the OpenAI API directly. Do not add an API key to `config.local.json`; it contains only device and signing settings.

## 4. Download the repository

Run this once in Terminal:

```bash
mkdir -p ~/Projects
cd ~/Projects
git clone https://github.com/InfronAI/iPhone-Use-with-Codex.git
cd iPhone-Use-with-Codex
pwd
ls README.md HelloWorld.xcodeproj scripts/iphone.py
```

**Checkpoint:** all three paths exist and `pwd` ends in `iPhone-Use-with-Codex`. The repository is public, so cloning does not require a GitHub token. If you already cloned it, use `cd` to enter that copy instead of cloning into an existing folder. From now on, run project commands from this directory.

## 5. Connect, trust, and unlock the iPhone

1. Connect the phone with a cable that supports data, not just charging.
2. Unlock it and accept the **Trust This Computer** prompt; enter the passcode on the phone.
3. Open the project:

```bash
open HelloWorld.xcodeproj
```

4. In Xcode, use the run-destination menu's device management entry or **Window → Devices and Simulators** / **Device Hub**, depending on your version. Wait for the physical phone to finish pairing/preparation.
5. On the phone, open **Settings → Privacy & Security → Developer Mode**, enable it, restart if requested, then unlock and confirm. If the entry is absent, finish pairing with Xcode and inspect the device status first. Follow [Apple's Developer Mode instructions](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device).
6. Keep the phone connected and unlocked during the first run.

```bash
python3 scripts/iphone.py devices
```

**Checkpoint:** select the row marked **physical**, with a connected/available state for your Xcode version. Copy its UDID/Identifier without any displayed `(UDID)` suffix. Do not choose the simulated row. A name alone or a charging icon does not prove development access.

## 6. Sign in to Apple and choose a unique app ID

In Xcode → Settings → Apple Accounts (Accounts in some versions), add your Apple account and complete any authentication. Confirm that your Personal Team or organization team is available. This tutorial deploys development builds to your device, not to the App Store. See [Apple's device-running guide](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices).

Choose a unique bundle ID, for example `dev.alex20261019.codexiphone` with **your own** handle instead of the example. Write down that exact value; use it consistently below.

In the open project:

1. Press `⌘1` to show the navigator and click the blue **HelloWorld project** icon.
2. Under **PROJECT**, select **HelloWorld → Build Settings**. Select **All** settings and search for `APP_BUNDLE_ID`.
3. Set this existing user-defined setting to your chosen bundle ID for Debug and Release.
4. Leave the App target's `PRODUCT_BUNDLE_IDENTIFIER` as `$(APP_BUNDLE_ID)` and the UI test target's as `$(APP_BUNDLE_ID).uitests`. Do not replace those expressions with unrelated literal IDs.

**Checkpoint:** the App target's resolved bundle ID matches your chosen value, and the test target adds `.uitests`. Preserving these expressions allows the CLI configuration to control both targets consistently.

## 7. Select the signing team and find its ID

1. Select **TARGETS → HelloWorld → Signing & Capabilities**.
2. Keep **Automatically manage signing** enabled and choose your team from **Team**. If asked to enable automatic signing, accept it.
3. Repeat for **TARGETS → HelloWorldUITests**, using the same team.
4. Select the physical iPhone in Xcode's run-destination menu. Handle any account, device registration, or keychain prompt in the system UI.
5. Save the project with `⌘S`.

If the team menu is empty, return to Apple Accounts and resolve sign-in/team access. To read the actual 10-character Team ID after selecting it, run:

```bash
xcodebuild -project HelloWorld.xcodeproj -target HelloWorld \
  -configuration Debug -showBuildSettings \
  | sed -n 's/^[[:space:]]*DEVELOPMENT_TEAM = //p'
```

**Checkpoint:** the output contains your 10-character team value, such as the illustrative `ABCDE12345`, not your display name or email. Empty output means the target's team is not yet set, or the command failed; read any preceding error. `DEVELOPMENT_TEAM` is the team-ID build setting in [Apple's reference](https://developer.apple.com/documentation/xcode/build-settings-reference).

Selecting a team in Xcode can change `project.pbxproj`. Those are local setup changes; do not publish your personal signing configuration when contributing. The CLI below uses local JSON values and does not require committing these changes.

## 8. Fill in config.local.json

Copy the template only if you have not already created your local configuration:

```bash
cp -n config.example.json config.local.json
nano config.local.json
```

Replace all three values:

```json
{
  "device": "YOUR_IPHONE_UDID",
  "team": "YOUR_TEAM_ID",
  "bundle_id": "com.yourname.codexiphone"
}
```

| Field | Where its real value comes from |
|---|---|
| `device` | The physical row from Step 5, with no annotation or spaces |
| `team` | The `DEVELOPMENT_TEAM` output from Step 7 |
| `bundle_id` | The unique value you chose in Step 6 |

In nano, save with `Control-O`, press Enter, then exit with `Control-X`. Use straight quotes, keep the commas between fields, and do not add comments or a trailing comma. The script deliberately rejects the `com.yourname.` and `com.example.` prefixes, so replace the bundle ID as well as the UDID and team.

```bash
python3 -m json.tool config.local.json
git check-ignore config.local.json
```

**Checkpoint:** the first command prints valid JSON; the second prints `config.local.json`, confirming that Git ignores it. This validates JSON syntax and ignore rules; deployment still needs to validate the actual device/team combination. The JSON output contains local identifiers, so keep it local.

## 9. Optional: connect Xcode MCP

MCP adds Xcode IDE tools to Codex. The shell/XCTest route works without this optional connection.

1. Keep `HelloWorld.xcodeproj` open in Xcode.
2. In **Xcode → Settings → Intelligence → Model Context Protocol**, enable external agents' access to Xcode tools when that feature is available.
3. Check the bridge and register it in Terminal:

```bash
xcrun --find mcpbridge
codex mcp add xcode -- xcrun mcpbridge
codex mcp list
codex mcp get xcode
```

If xcode is already registered, inspect its configuration rather than adding another entry. Open a fresh Codex session after changing MCP configuration and allow Xcode's actual access prompt if one appears. Follow [Apple's external-agent setup](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode).

**Checkpoint:** use the real discovery prompt in [the MCP guide](02-codex-xcode.md). An enabled entry in `mcp list` alone is not a connection test. If mcpbridge or the setting is unavailable, continue with the CLI route instead of blocking on an optional feature.

## 10. Verify the installation before touching the phone

```bash
python3 scripts/iphone.py doctor
python3 scripts/iphone.py test-engine
python3 scripts/iphone.py build-for-testing
```

**Checkpoint:** doctor resolves the tools, the engine reports PASS, and `build/build-for-testing.log` ends in `TEST BUILD SUCCEEDED`. These checks require no device interaction and do not prove signing or installation.

If a command fails, fix that step using [troubleshooting](05-troubleshooting.md). If it is still running, inspect the printed log in a second terminal rather than starting another build against the same output directory.

## 11. Continue to your first complete run

You now have the project, Codex sign-in, Xcode tools, a paired iPhone, and local signing configuration. Continue with [the first-run walkthrough](09-first-run.md): deploy → run UI tests → create a control session → inspect → act → verify → finish. It includes exact commands for both terminals and the expected output at each stage.
