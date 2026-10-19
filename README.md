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

## Quick start with an environment already set up

You need a Mac, full Xcode with the iOS SDK, Python 3.9+, access to Codex, and an iPhone connected by a data cable. See the [validation record](docs/06-validation.md) for the environments actually tested. The app deployment target is iOS 17.0; this does not mean every control feature has been tested on iOS 17 or every Xcode release.

```bash
git clone https://github.com/InfronAI/iPhone-Use-with-Codex.git
cd iPhone-Use-with-Codex
python3 scripts/iphone.py doctor
python3 scripts/iphone.py devices
cp config.example.json config.local.json
```

Edit `config.local.json` with your physical iPhone UDID, your 10-character Team ID, and a unique app bundle ID. Follow the [setup guide](docs/01-setup.md) for account, team, and pairing steps. This local file is ignored by Git.

```bash
# No signing or phone required: check game logic and compile the app and UI tests
python3 scripts/iphone.py test-engine
python3 scripts/iphone.py build-for-testing

# Signing and a physical iPhone required: build, verify the signature, install, launch
python3 scripts/iphone.py deploy

# Test tapping, dragging, bombs, pause, restart, and background recovery on the phone
python3 scripts/iphone.py test-ui
```

Build artifacts and local observations go into the ignored `build/` directory. If a build fails, open the log path printed by the CLI. A successful unsigned build does not prove that installation succeeded.

## Let Codex operate the iPhone

Deploy the sample, then prepare a control session. Set `--app` to the bundle ID in your configuration. You can also use `com.apple.Preferences` to inspect Settings.

```bash
python3 scripts/iphone.py prepare-control --app com.yourcompany.codexiphone
# Replace <SESSION> below with the unique session path printed by this command

# Terminal A: leave this running
python3 scripts/iphone.py run-control <SESSION>

# Terminal B: wait for the initial UI, then inspect hierarchy-0.txt and screen-0.png
python3 scripts/iphone.py collect <SESSION>
python3 scripts/iphone.py action <SESSION> tap-id --identifier startGame
python3 scripts/iphone.py action <SESSION> tap-id --identifier pauseGame
python3 scripts/iphone.py action <SESSION> done
```

Each step returns paths to a fresh UI hierarchy and screenshot. Codex can read the files, inspect the image, and choose the next action. `<SESSION>` is a documentation placeholder, not a literal shell argument. See the [device control guide](docs/04-device-control.md) for commands, Chinese text input, coordinate units, and timeout recovery.

Start Codex in this repository and give it this task:

> Read AGENTS.md and README.md. Check the connected physical iPhone and local configuration, deploy the sample app, and use the control bridge to inspect the start screen. Start a mission, drag the aircraft, use one bomb and confirm the count decreases, then pause. Use the latest UI hierarchy for each step and keep screenshot evidence. If an action times out, collect its original result without resending it. Report the actual result of every step.

More tasks are available in [Codex prompts](docs/07-prompts.md).

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
