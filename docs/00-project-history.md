# Project history

**English** | [简体中文](zh-CN/00-project-history.md) · [Documentation index](README.md)

## Sources and scope

This project was documented on October 19, 2026, using two complementary sources:

- The user's [shared discussion: installing Xcode and writing Hello World](https://chatgpt.com/share/6ad5e444-5d08-83e9-81ce-11020f88cd0d). The conversation data embedded in the shared page was retrieved during the work. It primarily covers setup, the CLI, signing, and MCP.
- The local Codex project session from the same day, Swift source, build logs, `.xcresult` bundles, and game screenshots. These record actual deployment, game development, and UI interaction with Lark.

This is a process summary, not a verbatim transcript. Private contact information, device identifiers, signing teams, chat screenshots, and complete UI dumps are excluded from the public repository.

## Stage 1: Set up the environment

The original question was how to install Xcode on a Mac, write a SwiftUI Hello World app, and install it on the user's own iPhone. The discussion established the prerequisites: full Xcode, the iOS SDK, an Apple account, a development team, device trust, and Developer Mode.

The user then wanted local Codex to carry out the entire workflow. They ran `codex mcp add xcode -- xcrun mcpbridge`, and the xcode service appeared in the list. The discussion distinguished an external Codex client accessing Xcode through MCP from the coding agent built into Xcode. Configuration still needed verification through an actual tool call.

The earlier instructions referred to `XcodeListWindows` / `tabIdentifier`; the tool catalog available during this project exposed `XcodeListWorkspaces` / `workspaceIdentifier`. The tutorial therefore asks readers to discover the current interfaces rather than treat older names as universal APIs.

## Stage 2: Deploy Hello World to the iPhone

The user requested Hello, World! and a tap counter, checks for the minimum iOS version, automatic signing, and the connected physical device, followed by compilation, installation, and launch. Account or pairing authorization was to be surfaced only when required.

The project targeted iPhone only, with iOS 17.0 as the deployment minimum. The first SwiftUI build hit a macro-plugin sandbox error; compilation succeeded after the required execution permission was granted. Signing then failed with `Signing for "HelloWorld" requires a development team.` The user signed in, selected a team, and the retry succeeded.

Build, signature verification, installation, launch, and process checks all completed. The observed environment was an iPhone 13 mini running iOS 26.7.1 with Xcode 27.1. These are observations from that run, not minimum tool-version requirements.

## Stage 3: Upgrade to Neon Strike

The existing project became a SpriteKit game with a SwiftUI shell and a separate `GameEngine` for the rules. Features included aircraft dragging, automatic fire, enemies, supplies, bombs, bosses, high scores, pause, and restart.

Checks with fixed random seeds covered damage protection, scoring, bomb inventory, boss progression, upgrades, and frame-rate independence. Physical-device UI tests covered starting a mission, dragging, bomb counts, pausing, restarting, and foreground/background transitions.

One useful failure exposed a mistaken assumption: sending a Home event was treated as proof that the app had entered the background. The pause assertion failed. An explicit state check showed that the phone had not actually left the app. The final test activated Settings, asserted that the game was in the background, then returned to check automatic pause. It passed at approximately 16:24:33, after which the game was reinstalled and left on its start screen.

## Stage 4: Operate Lark through its UI

The user requested a message to a specified contact and authorized a simple greeting. The workflow checked installed apps, opened Lark, verified the conversation, entered text, checked the draft, tapped Send, and observed the result. The historical session recorded the message appearing with a status icon; this is not a server-side audit or proof that the recipient read it.

Xcode's device-interaction tool encountered an authorization step, while the generic mobile-device interface did not list this physical iPhone. The working fallback was a persistent XCTest session exchanging `action.json`, UI hierarchies, and result files through the test Runner's Documents container.

Lark's composer spent a long time in XCTest's wait-for-idle phase. The response was to extend the wait, read logs, inspect screenshots, and collect the original action's result. No private API was used to disable idle waiting. The prototype increased its wait window to about 210 seconds and persisted the processed action ID before execution to avoid sending again after a restart.

The temporary control directory and Runner were removed at the end of that historical task. This repository reconstructs and extends the approach with separate session IDs, a client lock, pending state, input validation, and built-in screenshots.

## Turning the prototype into a reusable repository

| Prototype | Repository version |
|---|---|
| Fixed UDID, personal team, and bundle ID | Ignored local JSON configuration and Xcode build variables |
| Temporary tap/type script | Unified CLI with ID-based taps, dragging, app switching, and session completion |
| Fixed temporary path | Separate directory and UUID for each session |
| Avoiding retries depended on operator memory | Pending state blocks new actions; `collect` only retrieves the original result |
| Game tests temporarily replaced with control tests | The bridge builds in an isolated copy under `build/control/` |
| Instructions scattered across chat and logs | Step-by-step tutorials, troubleshooting, tests, and validation records |

Historical recollections, plans, and successful tests remain distinct. See the [validation record](06-validation.md) for actual results.
