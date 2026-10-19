# Codex, Xcode MCP, and the command line

**English** | [简体中文](zh-CN/02-codex-xcode.md) · [Documentation index](README.md)

## How the components fit together

```mermaid
flowchart TD
    U[User describes a task] --> C[Local Codex]
    C --> M[Xcode MCP: project and IDE tools]
    C --> S[Shell: iphone.py]
    M --> X[Xcode]
    S --> B[xcodebuild: build, sign, and run XCTest]
    S --> D[devicectl: discover, install, launch, and transfer files]
    B --> T[XCTest Runner on iPhone]
    D --> P[Paired physical iPhone]
    T --> A[Target app]
    A --> O[UI hierarchy, screenshots, and results]
    O --> C
```

An external Codex client calls Xcode through MCP. This does not install the running Codex process inside Xcode. Xcode's built-in coding agent and external Codex are separate entry points; your existing Codex CLI configuration can continue to serve the external workflow.

## Connect Xcode MCP

Follow [Apple's instructions](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode): allow external agents to use Xcode tools under Xcode → Settings → Intelligence, then open the project in Xcode.

```bash
codex mcp add xcode -- xcrun mcpbridge
codex mcp list
codex mcp get xcode
xcrun --find mcpbridge
```

Restart any Codex session that needs to load the configuration, then ask it to call the discovery tool. An **enabled** entry proves that configuration exists, not that the connection works.

Tools available during this project included `XcodeListWorkspaces`, `XcodeListRunDestinations`, `BuildProject`, `GetBuildLog`, and `DeviceInteractionStartSession`. The historical discussion's `XcodeListWindows` and `tabIdentifier` belong to a different interface version. Use workspace and session identifiers returned by the current tools rather than guessing them.

## Test the connection with a real tool call

Finish [Codex installation and sign-in](01-setup.md) first. In Terminal, enter the repository, open its project, then start a new Codex session:

```bash
open HelloWorld.xcodeproj
codex
```

Paste this into Codex:

> Use the configured Xcode MCP server to discover the currently open workspaces/projects. Select this repository's HelloWorld project using the returned identifier, then list its run destinations. Report which destination is the connected physical iPhone and whether it is available. Do not substitute a simulator or invent tool names. If the server or access fails, report the actual error.

**Checkpoint:** a real discovery call returns the open project, followed by a destination result identifying a physical device. Resolve any actual Xcode access prompt before retrying. If nothing is found, verify the Xcode window is open and the MCP configuration was loaded by this new session. The interface may rename tools across Xcode versions; the schema in the current session is authoritative.

If MCP is unavailable, continue with [the CLI first-run guide](09-first-run.md). Xcode MCP configuration, Codex account access, and Apple device signing are separate checks.

## Optional direct device interaction through Xcode

If the current MCP version exposes device-interaction tools:

1. Discover the workspace and physical device, and verify the active destination.
2. Call `DeviceInteractionStartSession` or its workspace variant, and keep the returned session key.
3. Call `DeviceInteractionSynthesize` to obtain the latest hierarchy and screenshot. Locate the target in that hierarchy, then execute one interaction.
4. Inspect the new result and call `DeviceInteractionEndSession` when finished.

Read argument names from the current tool schema. The original Lark task encountered additional authorization and device-discovery differences, which is why the repository also includes an XCTest bridge independent of this MCP interaction API.

## Respect the permission boundaries

A Codex shell sandbox may be unable to reach CoreDevice services, the signing keychain, or compiler plugins. If a necessary command fails for that reason, use the approval mechanism provided by the current Codex environment and explain the error. Disabling all approvals is not a setup step. See the [Codex permissions documentation](https://developers.openai.com/codex/security).

Xcode/iPhone authorization and Codex command approval are separate. Permission to run a shell command does not authorize a signing account, establish device trust, or grant Xcode MCP access.
