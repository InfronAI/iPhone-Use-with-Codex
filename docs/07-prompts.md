# Reusable Codex tasks

**English** | [简体中文](zh-CN/07-prompts.md) · [Documentation index](README.md)

Start Codex in this repository and use the device and configuration authorized by the current user. Each prompt below can be copied independently.

## Environment and MCP diagnostics

> Read AGENTS.md. Check Xcode, Python, devicectl, and the physical iPhone's state. If Xcode MCP is configured, actually call its current workspace-discovery tool and read basic project information. Distinguish configuration presence, callable MCP tools, and device availability. Do not infer a working connection from configuration alone. If owner authorization is genuinely required, identify the exact window and action.

## Build and deploy

> Check config.local.json, then build, sign, and deploy to the specified physical iPhone using this repository's iphone.py. Diagnose and fix failures. Report compilation, signature verification, installation, launch, and UI verification separately. Do not substitute a simulator or commit local identity settings.

## Hello World exercise

> On a separate branch, use examples/HelloWorldView.swift to implement Hello, World! and a tap counter, keeping the complete project buildable. Deploy to the physical iPhone, start the control bridge, observe a count of 0, tap incrementCount, verify that it becomes 1, and save the evidence. Do not run the game-specific UI tests against this screen.

## Game regression

> Run the game logic checks and physical iPhone UI tests. Check mission start, dragging, bomb consumption, pause, restart, and automatic pause after switching to Settings and back. Assert the actual background state rather than treating a Home call as proof of a completed transition. Leave the playable game on its start screen when finished.

## Autonomous UI interaction

> Use the bridge described in docs/04-device-control.md to operate the authorized target app. Inspect the hierarchy and screenshot first, then execute one action using an accessibility ID or current coordinates. Verify the result after each action before continuing. On timeout, collect the original action without resending it. Send done at completion and wait for the Runner to exit.

## Send an explicitly authorized test message

> In the messaging app where I am signed in and have authorized you to act, send [ENTER THE COMPLETE MESSAGE] to [ENTER A UNIQUE RECIPIENT AND IDENTIFYING DETAILS]. Verify the recipient and draft, send once, and inspect the message bubble and status. Ask if matching names are ambiguous. If the outcome is unknown, keep observing without sending again. Do not commit message logs or chat screenshots to GitHub.

Fill in both the recipient and content before using this prompt. The original user's permission to choose a greeting applied to that task; it is not default authorization for future tasks.

## Publish and hand off

> Check that public files contain no device UDIDs, personal Team IDs, certificates, session logs, or private chat content. Run relevant checks and update both language versions of docs/06-validation.md with actual results only. Commit and push as requested, preserving the remote history and avoiding force pushes. Provide the commit link and any remaining limitations.
