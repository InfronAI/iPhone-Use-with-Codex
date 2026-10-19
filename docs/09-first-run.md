# Your first complete run on a real iPhone

**English** | [简体中文](zh-CN/09-first-run.md) · [Documentation index](README.md)

Finish [installation and configuration](01-setup.md) first. This walkthrough proves deployment, automated touch interaction, observation, app switching, and a clean session exit. Keep the phone connected and unlocked. Run commands one step at a time; resolve an error before continuing.

You will use two Terminal windows. **Terminal A runs the XCTest Runner; Terminal B sends commands and reads results.** Each window has its own working directory and shell variables. Do not run another UI test or control Runner on the phone while one is active.

## 1. Install and launch the sample

Open Terminal A. If you cloned elsewhere, use your actual repository path instead of the first line:

```bash
cd ~/Projects/iPhone-Use-with-Codex
python3 scripts/iphone.py deploy
```

This command builds with the local Team ID and bundle ID, verifies the code signature, installs the app, launches it, and records the process list. Handle any actual Apple account/keychain/device prompt and wait for the command to return.

**Checkpoint:** the phone shows **雷电 · 星空突袭** with its start button. The command finishes successfully, and `build/` contains `deploy-build.log`, `install.json`, and `launch.json`. This is stronger evidence than `BUILD SUCCEEDED` alone. If it fails, inspect the printed log and [troubleshooting](05-troubleshooting.md); do not start a control session yet.

## 2. Verify taps, dragging, and lifecycle behavior

In Terminal A, after deploy has finished:

```bash
python3 scripts/iphone.py test-ui
tail -n 25 build/test-ui.log
```

Watch the physical phone. The test starts a mission, drags the aircraft, uses a bomb, pauses, restarts, switches to Settings, and returns. It checks the bomb count changing from 3 to 2 and the pause state after returning. Touching the phone yourself during the test can interfere with the assertions.

**Checkpoint:** the log reports **1 test, 0 failures** and `TEST SUCCEEDED`. The CLI exports three screenshot attachments under `build/UITests-<unique-id>.attachments/`; `<unique-id>` here describes the generated folder name, not something you type. The corresponding `.xcresult` can be opened in Xcode through Finder. Wait until the CLI returns, including attachment export, before starting the next step.

## 3. Prepare a control session in Terminal A

The first manual session opens Settings, then switches to the sample. This gives you a stable starting point while reading the tutorial; the preceding UI regression already exercised the time-sensitive game controls.

```bash
python3 scripts/iphone.py prepare-control --app com.apple.Preferences
```

The output contains three lines beginning with `Session:`, `Terminal A:`, and `Terminal B:`. The first line contains the full path to a new folder under `build/control/`. Each preparation creates a different session.

To store that exact path without editing a placeholder, run:

```bash
read -r SESSION
```

Terminal now waits for a line of input. **Paste only the full path after `Session:` and press Return.** Do not paste the `Session:` label, surrounding quotes, or either command from the other lines. Then check it:

```bash
ls "$SESSION/session.json"
```

**Checkpoint:** `ls` prints the existing session JSON path. If it says “No such file,” repeat the `read` step with the correct path before continuing.

Save the path so Terminal B can use the same session, then start the Runner:

```bash
printf '%s\n' "$SESSION" > build/current-control-session.txt
python3 scripts/iphone.py run-control "$SESSION"
```

**Leave Terminal A running.** It prints a `Log:` path and can appear quiet while Xcode builds, signs, installs, and starts the Runner. This is expected: the detailed output goes to `runner.log`. The shell prompt should not return until the session ends or encounters an error.

## 4. Get the first observation in Terminal B

Open a second Terminal window (`⌘N`) and enter the repository again. Use the same actual clone path as Terminal A if yours differs:

```bash
cd ~/Projects/iPhone-Use-with-Codex
SESSION="$(cat build/current-control-session.txt)"
python3 scripts/iphone.py collect "$SESSION" --timeout 420
```

`collect` waits for the Runner; it does not start another Runner. The first result has ID 0. When it returns, inspect both forms of evidence:

```bash
sed -n '1,80p' "$SESSION/hierarchy-0.txt"
open "$SESSION/screen-0.png"
```

**Checkpoint:** Terminal prints `Observed:` and `Screenshot:` paths; the text identifies Settings (`com.apple.Preferences`) and the PNG shows its current screen. Settings opens in its existing navigation state; a root list or a previously opened subpage can both be valid.

If the wait times out, inspect startup in Terminal B:

```bash
tail -n 50 "$SESSION/runner.log"
python3 scripts/iphone.py collect "$SESSION" --timeout 420
```

Repeat collection only while the Runner is still starting or running. If Terminal A has already failed, solve the reported error and prepare a new session. Do not run the same session a second time or manually reset its state.

## 5. Observe, switch apps, and verify

Still in Terminal B, request a fresh observation:

```bash
python3 scripts/iphone.py action "$SESSION" snapshot
open "$SESSION/screen-1.png"
```

Now read your configured bundle ID and activate the sample app:

```bash
APP_BUNDLE_ID="$(python3 -c 'import json; print(json.load(open("config.local.json"))["bundle_id"])')"
python3 scripts/iphone.py action "$SESSION" activate --bundle "$APP_BUNDLE_ID"
sed -n '1,80p' "$SESSION/hierarchy-2.txt"
open "$SESSION/screen-2.png"
```

**Checkpoint:** the phone and the observation show the sample game rather than Settings; the hierarchy identifies your configured app. It can show its menu or a paused game depending on whether Xcode restarted it. Either proves the requested app switch. If the PNG catches an animation, request another `snapshot` and inspect the new paths printed by that command.

The numbers above assume you ran exactly the listed actions. Extra snapshots advance the counter: always use the paths returned by the CLI if you added actions. To try taps, drags, or text entry next, follow [the action reference](04-device-control.md) and choose targets from the latest UI; do not reuse coordinates or a button from an old screen.

An action timeout means the outcome is unknown. Run `collect` on the same session to retrieve the original result. Do not resend the action or issue `done` until the pending outcome is resolved.

## 6. Finish the session normally

In Terminal B:

```bash
python3 scripts/iphone.py action "$SESSION" done
```

Wait for Terminal A to return to its shell prompt, then inspect its log:

```bash
tail -n 25 "$SESSION/runner.log"
```

**Checkpoint:** done returns its final observation; Terminal A exits successfully and the log contains `TEST SUCCEEDED`. `session.json` now has `closed: true`. The session is finished and cannot be reused. Keep the unique session directory for local review; `build/` is ignored by Git and may contain private screen contents.

## 7. Let Codex perform the same workflow

After the manual session has ended, start Codex from the repository in a free terminal:

```bash
codex
```

Paste this task into Codex, not into the shell:

> Read AGENTS.md, README.md, and docs/09-first-run.md. Use the connected physical iPhone selected in config.local.json. Confirm the previous Runner has exited. Deploy the sample app, run its UI test, and report the result. Then prepare a fresh control session targeting Settings, keep run-control running, collect the initial hierarchy and screenshot, activate the configured sample app, and inspect the new evidence. Send done and wait for the Runner to exit. Use scripts/iphone.py. If an action times out, collect its original result instead of resending it. Report actual results and local evidence paths, without printing personal device or signing identifiers.

A working shell/XCTest route does not require Xcode MCP. If you configured MCP, verify it separately using [the discovery prompt](02-codex-xcode.md). Respond to actual local approval/account prompts as they arise; no global permission bypass is needed.

**Checkpoint:** Codex actually runs the commands and reads the resulting observations. A written plan, an enabled MCP entry, or an old screenshot is not a completed execution. See [additional prompts](07-prompts.md) for game interaction and adapting authorized tasks to other apps.

## 8. What you should have, and how to run it next time

| Result | Where to check |
|---|---|
| Signed app installed and launched | Phone screen, `build/install.json`, `build/launch.json` |
| Game touch regression passed | `build/test-ui.log` and the unique `.xcresult` / attachments folder |
| Initial Settings observation | Your session's `hierarchy-0.txt` and `screen-0.png` |
| Successful switch to the sample | The returned hierarchy and PNG after `activate` |
| Clean control-session exit | Final done result, `closed: true`, successful `runner.log` |

On later runs, you do not need to reinstall the tools or recopy the configuration. Connect/unlock the phone, enter the repository, run `devices`, and deploy again if code/signing changed or the app is no longer installed. Prepare a **new** control session and repeat Steps 3–6. Shell variables disappear when a terminal closes; the path file only helps while its session is still valid. If you change the phone, team, or bundle ID, update `config.local.json` and deploy before controlling it again.

This is a reproduction guide, not a claim that every reader's Mac or iPhone has been tested. The [validation record](06-validation.md) lists actual executions and their limits.
