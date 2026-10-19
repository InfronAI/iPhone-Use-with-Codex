# Validation record

**English** | [简体中文](zh-CN/06-validation.md) · [Documentation index](README.md)

## Environment and evidence

Date: **October 19, 2026**. Physical device: **iPhone 13 mini**. The historical session recorded iOS **26.7.1**; local Xcode reported **27.1 / 27A9275** during repository preparation. The app's minimum deployment target is iOS 17.0. No simulator was substituted for the physical device.

The table below records actual executions during preparation of this repository. Historical project validation is listed separately and does not replace testing of the reusable version. Personal signing details, device IDs, private UI hierarchies, and raw logs remain in ignored local directories. Translation of these documents does not represent a new device-test run.

## Repository validation

| Check | Execution and result |
|---|---|
| Game rules | `python3 scripts/iphone.py test-engine`: PASS for lifecycle, bounds, combat, scoring, immunity, game over, bosses, supplies, and frame-rate independence |
| Offline protocol checks | `python3 -B -m unittest discover -s Tests -v`: 8 tests passed |
| Unsigned build | `python3 scripts/iphone.py build-for-testing`: `TEST BUILD SUCCEEDED`; both the app and UI tests compiled |
| Signed physical-device build | deploy reported `BUILD SUCCEEDED`; codesign verification passed |
| Installation and launch | After fixing launch argument order, deploy returned 0; installation and launch succeeded, with HelloWorld present in the process list |
| Game UI regression on the phone | test-ui completed at 18:01:04: 1 test passed, 0 failed; 3 attachments exported for start, combat, and pause |
| Bridge observations | Runner compiled, signed, and started; Python retrieved a hierarchy and PNG from its device container |
| Bridge app activation | Switched from Settings to the sample game and retrieved the game UI |
| Bridge tap by identifier | `tap-id startGame` produced pauseGame / useBomb controls with a bomb count of 3 |
| Bridge dragging | drag returned a completion result and fresh screenshot; engine checks separately cover movement bounds |
| Bridge coordinate tap | Located Settings search in the latest hierarchy; tapping it produced Keyboard Focused |
| Mixed English/Chinese input | Entered `Codex测试`; the new hierarchy showed exactly that search-field value; no system setting was changed |
| Session completion | Returned to the sample app and sent done; the result was retrieved and the Runner exited normally. The final control test passed at 18:13:09 after 51.839 seconds |

Offline protocol checks cover retaining pending state after a failed transfer, collecting without resending after a timeout, closing on done, initial result ID 0, rejecting invalid coordinates or empty text, rejecting acknowledgements from a stale session, preserving Unicode and special characters as data, and launch argument order.

## Problems found and handled

1. `devicectl process launch` interpreted arguments after the bundle ID as application arguments, so `--device` was not recognized. Tool options were moved before the bundle ID, a regression check was added, and complete deployment then succeeded.
2. During interactive testing, the game changed state while the previous screen was being inspected, so pauseGame was no longer hittable. The bridge correctly rejected the action and stopped the Runner instead of guessing coordinates. The complete sequential UI regression subsequently passed.
3. Setting only XCTest's maximum allowance could leave the default 10-minute timeout active. The final code sets both default and maximum allowances, plus `executionTimeAllowance = 2100`; the session loop expires after 1800 seconds.

The final short session verified compilation, startup, interaction, and normal exit of the revised code. A full 30-minute endurance test was not run.

## Historical validation from local sessions and artifacts

- Hello World: installed and launched on the same physical iPhone after resolving signing.
- Game: physical-device regression passed at approximately 16:24:33 on October 19, 2026. Its historical start-screen screenshot is used in the README.
- Lark: the session records an authorized greeting entered and sent through the UI, followed by inspection of the message bubble and status icon. The session concluded that it had been sent; there was no server-side delivery audit or proof that the recipient had read it.

## Coverage not claimed

- This project has not been tested on every iPhone, iOS 17+ release, or Xcode version.
- No message was sent to a Lark contact again during repository preparation.
- Home events, search in third-party apps, and different keyboards remain device/app dependent. Chinese input was verified only in Settings search during this preparation.
- CI is provided as `docs/ci/checks.yml.example` and has not been enabled. GitHub rejected the initial push containing a workflow because the token lacked workflow scope; the configuration was retained as a template so the project could be published. CI cannot use this local signing identity or iPhone.
- The session protocol avoids automatic repeated attempts, but cannot provide database transactions or exactly-once guarantees for UI operations.
