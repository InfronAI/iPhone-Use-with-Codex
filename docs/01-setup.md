# Set up the environment

**English** | [简体中文](zh-CN/01-setup.md) · [Documentation index](README.md)

## 1. Install full Xcode

Get an Xcode version compatible with your macOS and iPhone from the [Mac App Store](https://apps.apple.com/app/xcode/id497799835) or [Apple Developer Downloads](https://developer.apple.com/download/all/?q=Xcode). Check [Apple's compatibility information](https://developer.apple.com/support/xcode/); the versions used in the historical session are not current installation requirements.

Open Xcode and finish the initial license, platform, and component setup. Command Line Tools alone are insufficient to build and sign an iPhone app.

```bash
xcode-select -p
xcodebuild -version
xcrun --find devicectl
xcrun --find swiftc
```

If the selected path is `/Library/Developer/CommandLineTools`, the machine owner can run:

```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

Alternatively, set `DEVELOPER_DIR` in the current terminal to your Xcode Developer directory. Do not copy someone else's beta installation path blindly.

## 2. Sign in and configure signing

Sign in under Xcode → Settings → Apple Accounts (called Accounts in some versions). Open `HelloWorld.xcodeproj`, select the project in the navigator, then **TARGETS → HelloWorld → Signing & Capabilities**. Enable automatic signing and choose your team. The UI test target also needs the same team.

The CLI reads the Team ID from `config.local.json` and passes it to both app and test targets through build arguments. Keep your identity in this local JSON file rather than committing personal signing settings. Find the Team ID in Xcode's team information or your Apple Developer account; a person's name in a certificate is not a Team ID.

```json
{
  "device": "YOUR_IPHONE_UDID",
  "team": "YOUR_TEAM_ID",
  "bundle_id": "com.yourname.codexiphone"
}
```

Replace all three example values. The app bundle ID must be unique. The UI test ID is derived as `<bundle_id>.uitests`, and the Runner uses `<bundle_id>.uitests.xctrunner`. You do not need to give Codex your Apple password or private key. Complete account sign-in, two-factor authentication, and keychain prompts in the system UI.

Automatic signing lets Xcode manage development resources. Available capabilities and validity periods depend on your account, provisioning profile, and Apple's rules. See [Apple's physical-device guide](https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices).

## 3. Pair a physical iPhone

1. Connect the phone to the Mac using a data-capable cable and unlock it.
2. Trust the computer on the phone and confirm with the device passcode.
3. Check that the phone is paired and available in Xcode's device management UI.
4. Enable Developer Mode following [Apple's instructions](https://developer.apple.com/documentation/xcode/enabling-developer-mode-on-a-device), including the restart and confirmation.
5. Run `python3 scripts/iphone.py devices`, copy the **physical** device's UDID, and confirm that its state is **connected**.

Do not select a simulated device ID. This bridge cannot perform initial trust, passcode entry, biometric authentication, or Developer Mode confirmation on the owner's behalf. Use the actual states reported by `devicectl` and Xcode to determine availability.

## 4. Prepare Codex

Use a Codex environment that can access the local project and terminal. Follow the [official Codex CLI instructions](https://developers.openai.com/codex/cli) for installation and sign-in. Start `codex` in the repository and have it read `AGENTS.md` first. This project's Python scripts do not directly call the OpenAI API, so no API key needs to be stored in the repository.

Xcode MCP is an optional integration described in the [next chapter](02-codex-xcode.md). Codex can drive deployment and the XCTest bridge directly through shell commands.

## 5. Check the setup

```bash
python3 scripts/iphone.py doctor
python3 scripts/iphone.py devices
python3 scripts/iphone.py test-engine
python3 scripts/iphone.py build-for-testing
```

`doctor` checks tool paths; it does not prove that signing and device access are authorized. End-to-end validation requires successful deployment, launch, and UI interaction on the phone.
