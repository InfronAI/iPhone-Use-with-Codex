# Working on iPhone Use with Codex

**English** | [简体中文](AGENTS.zh-CN.md)

Read README.md and docs/04-device-control.md before device interaction.

- Use a physical iPhone selected explicitly by UDID. Never substitute a simulator and call it a real-device result.
- Local configuration lives in ignored config.local.json. Never commit device identifiers, personal Team IDs, profiles, certificates, private UI dumps, or raw session transcripts.
- Use python3 scripts/iphone.py for the documented workflows. Keep the shipped project unsigned and parameterized with APP_BUNDLE_ID and DEVELOPMENT_TEAM.
- Observe → locate from the latest hierarchy → perform one action → inspect hierarchy and screenshot. Coordinates are points in the app frame, not screenshot pixels.
- An acknowledged tap is not proof that a business operation succeeded. Check the resulting UI. When a send or other external action has unknown outcome, collect the same action; do not replay it.
- Existing user authorization carries forward. Do not ask repeatedly for routine checks, fixes, or already authorized operations. Sending messages requires an explicitly authorized recipient and content/scope. Stop only for missing intent, ambiguous recipient, or an actual system/account authorization prompt.
- Do not bypass device trust, Developer Mode, signing, keychain, or Codex sandbox approvals. Use supported public XCTest APIs.
- Run python3 -B -m unittest discover -s Tests -v and python3 scripts/iphone.py test-engine for protocol/engine edits. Build-for-testing checks Swift changes. Device tests are sequential; never run two XCTest sessions on one phone.
- Record actual build, signing, install, launch, UI-test results separately in both language versions of docs/06-validation.md; distinguish historical evidence from the current run.
- Use English by default for README.md and docs/*.md, with complete Simplified Chinese counterparts in README.zh-CN.md and docs/zh-CN/. Keep language-switch links and technical details in sync. Communicate in the user’s language. Preserve the MIT license.
