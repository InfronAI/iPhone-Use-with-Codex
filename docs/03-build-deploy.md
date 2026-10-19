# From Hello World to a playable game

**English** | [简体中文](zh-CN/03-build-deploy.md) · [Documentation index](README.md)

## Understand the project

The repository includes the `.xcodeproj` and a shared scheme, so XcodeGen is not required. The default app is the complete game; the project name remains HelloWorld to preserve continuity with the original workflow.

| File | Responsibility |
|---|---|
| `HelloWorldApp.swift` | SwiftUI app entry point |
| `ContentView.swift` | Start, pause, and game-over UI; lifecycle handling |
| `GameEngine.swift` | Independent rules, seeded randomness, enemies, projectiles, collisions, and bosses |
| `GameScene.swift` | SpriteKit rendering and dragging gestures |
| `FlightUITests.swift` | Physical-device UI workflow and screenshot attachments |

## Follow the Hello World exercise

To reproduce the first stage, create a separate Git branch, copy `examples/HelloWorldView.swift` over `HelloWorld/ContentView.swift`, then deploy. The example displays Hello, World! and a tap counter. Do not add both files defining `ContentView` to the target.

```bash
git switch -c tutorial/hello-world
cp examples/HelloWorldView.swift HelloWorld/ContentView.swift
python3 scripts/iphone.py deploy
```

Use the control bridge to tap `incrementCount` and observe the counter change from 0 to 1. The existing `test-ui` command runs game tests and does not apply to the Hello World screen. To return to the game, save your work first and restore `ContentView.swift` from main; do not overwrite unsaved changes.

## Compile, then sign

```bash
python3 scripts/iphone.py build
python3 scripts/iphone.py build-for-testing
```

Both commands select a generic iOS destination with `CODE_SIGNING_ALLOWED=NO` to check compilation of the source and UI tests. They do not run the app on a simulator or physical device.

For a signed deployment:

```bash
python3 scripts/iphone.py deploy
```

The script:

1. Selects `platform=iOS,id=…` using the configured UDID.
2. Passes `DEVELOPMENT_TEAM` and `APP_BUNDLE_ID` to xcodebuild, enabling automatic provisioning updates and device registration.
3. Verifies the built app's signature.
4. Installs the `.app` on that phone.
5. Launches its bundle ID and records the launch result and device processes.

Any failed step returns a nonzero exit code; logs remain in `build/`. The `install.json`, `launch.json`, and `processes.json` files are local evidence and should not be published unredacted.

To understand the underlying commands, use your own values in a terminal:

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

Set all three shell variables yourself; the JSON configuration and CLI are the recommended routine path. Place `process launch` options before the bundle ID, because later arguments may be interpreted as arguments for the app.

## Why separate game rules from the UI?

The rules can run on the Mac without signing, UI timing, or a phone connection:

```bash
python3 scripts/iphone.py test-engine
```

Checks cover spending bombs before a game starts, movement bounds, automatic firing, freezing while paused, awarding bomb scores once, nonnegative inventory, damage immunity, game over, bosses, supplies, and frame-rate independence. They use `precondition`; the script does not enable `-Ounchecked`, which would remove those checks.

UI tests answer whether the workflow can actually be operated on the phone:

```bash
python3 scripts/iphone.py test-ui
```

The test starts a mission, drags the aircraft, spends one bomb, pauses, restarts, switches to Settings, returns to the automatically paused game, and resumes. Buttons use stable accessibility identifiers. Screenshot attachments are retained in a unique `.xcresult` bundle and automatically exported to the matching `.attachments` directory.

## Iterate and restore

After code changes, run the rule checks, relevant builds, and physical-device tests before deploying again. Reusing a bundle ID updates the existing app; a new bundle ID installs a separate app alongside it. This repository does not automatically uninstall the original project or touch unrelated app data on the phone.

Run `swift scripts/GenerateAppIcon.swift` from the repository root to regenerate the game icon. The generated PNG is already committed, so routine builds do not require icon generation.
