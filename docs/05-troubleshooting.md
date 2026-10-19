# Troubleshooting

**English** | [简体中文](zh-CN/05-troubleshooting.md) · [Documentation index](README.md)

Separate source compilation, signing, device connection, the test Runner, UI interaction, and the task's actual outcome. Success at one stage does not prove success at the next.

| Symptom | What to check or do | Evidence of recovery |
|---|---|---|
| xcodebuild reports that only Command Line Tools are installed | Select the full Xcode Developer directory and install the iOS platform | doctor reports the correct paths and version |
| `mcpbridge` is missing | Check the installed version and run `xcrun --find mcpbridge` | The command exists and Codex can call the tools |
| MCP is enabled but no project is found | Open the project in Xcode, allow external agents, and reload Codex configuration | The current discovery tool returns the workspace |
| `XcodeListWindows` from older instructions is missing | Inspect the current MCP tool list and use its workspace interface | A real tool call succeeds |
| `SwiftUIMacros.StateMacro` / plugin malformed response | Inspect preceding sandbox or permission errors; approve the necessary build command if required | The same source builds; do not rewrite SwiftUI blindly for a permission failure |
| `requires a development team` | Sign in, select a team, and set the local 10-character Team ID | Signed build and codesign verification succeed |
| Bundle identifier is unavailable | Use your own unique prefix for the app and UI tests | Xcode creates or finds the provisioning profile |
| Signing appears stuck | Check the Mac for a codesign keychain prompt; the owner must handle it | The log proceeds past CodeSign and completes |
| Device is unavailable or disappears | Unlock, check cable/port, and confirm trust and Developer Mode | The physical device is connected |
| Build succeeds but installation fails | Check signing, provisioning, OS compatibility, and lock state | devicectl install succeeds |
| Launch reports missing `--device` | Put options before the bundle ID; later arguments may be passed to the app | launch.json records the launch result |
| Background test fails after a Home event | Check app.state rather than assuming Home worked; activate Settings instead | The app actually enters the background and returns paused |
| `Wait for ... to idle` takes too long | Inspect runner.log, extend collect, and obtain an independent screenshot; do not resend | The original action result and updated UI become available |
| The initial collect result never appears | Check runner.log for startup, signing, bundle ID, or locked-device problems | CODEX_CONTROL_READY and result-0 appear |
| Runner ends after 10 minutes | Maximum allowance alone does not override the default; also set default allowance and XCTestCase.executionTimeAllowance | A new session no longer uses the old default allowance |
| Pending state blocks further actions | The earlier outcome is unresolved; keep collecting, since a failed transfer may still have partly completed | Pending state clears only after the original result is confirmed |
| tap-id is ambiguous or not hittable | Inspect the latest hierarchy for one hittable match | Exactly one visible target matches |
| Screenshot and tap positions disagree | Check points versus pixels, orientation, and coordinates made stale by the keyboard | Relocate the target using the latest hierarchy |
| Text goes into the wrong field | Focus the intended input and inspect the keyboard/draft | The screen and hierarchy show the correct content |
| Older Xcode lacks capture screenshot | Check `xcrun devicectl help device capture screenshot` | Use bridge screenshots or XCTest attachments |
| Network requests fail through a local proxy port | Check that the proxy is running and the execution environment permits access | The request succeeds; do not silently delete the user's proxy configuration |

## Minimal diagnostic commands

```bash
python3 scripts/iphone.py doctor
python3 scripts/iphone.py devices
tail -n 50 build/deploy-build.log
tail -n 50 "$SESSION/runner.log"
python3 scripts/iphone.py collect "$SESSION" --timeout 240
```

`SESSION` must be the actual control-session path. Logs can include local paths and personal data; redact them before posting a public issue.

## Distinguish different kinds of success

- `BUILD SUCCEEDED`: the source and targets built, possibly without signing.
- Installation succeeded: the app was installed, but may not have launched.
- Launch succeeded: a process was created, but may not display the expected screen.
- An action was acknowledged: XCTest finished the call, but the task may remain incomplete.
- The task succeeded: the resulting UI must support that conclusion. A single screenshot still cannot establish server-side or recipient state for a message.

Identifying the failing stage is usually more useful than rerunning the entire workflow.
