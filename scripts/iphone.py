#!/usr/bin/env python3
"""Dependency-free macOS CLI for real iPhone deployment and XCTest control."""
import argparse
import base64
import fcntl
import json
import math
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "build"


def save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(path.suffix + ".tmp")
    temp.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    temp.replace(path)


def run(command, log=None):
    # Arguments are always an argv list, never shell-interpolated.
    print("Running:", command[0], command[1] if len(command) > 1 else "", flush=True)
    if log:
        log.parent.mkdir(parents=True, exist_ok=True)
        print("Log:", log, flush=True)
        with log.open("w") as out:
            subprocess.run(command, cwd=ROOT, stdout=out, stderr=subprocess.STDOUT, check=True)
    else:
        subprocess.run(command, cwd=ROOT, check=True)


def config():
    path = ROOT / "config.local.json"
    if not path.exists():
        raise ValueError("Copy config.example.json to config.local.json and fill device/team/bundle_id")
    c = json.loads(path.read_text())
    if not re.fullmatch(r"[A-Za-z0-9-]+", c.get("device", "")) or c["device"].startswith("YOUR"):
        raise ValueError("Set the physical iPhone UDID in config.local.json")
    if not re.fullmatch(r"[A-Z0-9]{10}", c.get("team", "")):
        raise ValueError("team must be your 10-character Apple Development Team ID")
    validate_bundle(c.get("bundle_id", ""))
    if c["bundle_id"].startswith(("com.yourname.", "com.example.")):
        raise ValueError("Choose your own unique bundle_id")
    return c


def validate_bundle(bundle):
    if not re.fullmatch(r"[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+", bundle):
        raise ValueError("Invalid bundle identifier")


def xcode(project, derived, c=None):
    args = ["xcodebuild", "-project", str(project), "-scheme", "HelloWorld", "-configuration", "Debug",
            "-derivedDataPath", str(derived)]
    if c:
        args += ["-destination", "platform=iOS,id=" + c["device"], "-allowProvisioningUpdates",
                 "-allowProvisioningDeviceRegistration", "DEVELOPMENT_TEAM=" + c["team"],
                 "APP_BUNDLE_ID=" + c["bundle_id"]]
    else:
        args += ["-sdk", "iphoneos", "-destination", "generic/platform=iOS", "CODE_SIGNING_ALLOWED=NO"]
    return args


def device(c, *args):
    return ["xcrun", "devicectl", "device", *args[:2], "--device", c["device"], "--timeout", "30", *args[2:]]


def copy_file(state, direction, source, destination):
    return subprocess.run([
        "xcrun", "devicectl", "device", "copy", direction, "--device", state["device"],
        "--domain-type", "appDataContainer", "--domain-identifier", state["runner"],
        "--source", str(source), "--destination", str(destination), "--timeout", "10"
    ], capture_output=True, text=True, timeout=15)


def remote(state, name):
    return "Documents/codex-" + state["session"] + "/" + name


def observe(state, root, action_id, timeout):
    deadline = time.monotonic() + timeout
    last_error = ""
    while time.monotonic() < deadline:
        target = root / ("result-%d.json" % action_id)
        try:
            r = copy_file(state, "from", remote(state, target.name), target)
        except subprocess.TimeoutExpired:
            last_error = "devicectl transfer timed out"
            continue
        if r.returncode == 0:
            result = json.loads(target.read_text())
            if result.get("session") != state["session"] or result.get("id") != action_id:
                raise ValueError("Unexpected acknowledgement; refusing to advance session")
            if result.get("status") != "ok":
                raise ValueError("Runner error: " + result.get("error", "unknown"))
            for name in ["hierarchy-%d.txt" % action_id, "screen-%d.png" % action_id]:
                r = copy_file(state, "from", remote(state, name), root / name)
                if r.returncode:
                    raise ValueError("Action acknowledged but evidence download failed. Use collect; do not replay.")
            print("Observed:", root / ("hierarchy-%d.txt" % action_id))
            print("Screenshot:", root / ("screen-%d.png" % action_id))
            return
        last_error = (r.stderr or r.stdout)[-600:]
        time.sleep(1)
    raise ValueError("Outcome unknown. Use collect to retrieve the SAME action; never resend. " + last_error)


def action_payload(args, state):
    data = {"session": state["session"], "id": state["next_id"], "kind": args.kind}
    fields = {"x": args.x, "y": args.y, "endX": args.end_x, "endY": args.end_y,
              "text": args.text, "identifier": args.identifier, "bundle": args.bundle}
    required = {"tap": ["x", "y"], "drag": ["x", "y", "endX", "endY"],
                "type": ["text"], "tap-id": ["identifier"], "activate": ["bundle"]}.get(args.kind, [])
    for key in required:
        if fields[key] is None or fields[key] == "":
            raise ValueError("Missing --" + key)
    for key in ["x", "y", "endX", "endY"]:
        value = fields[key]
        if value is not None and (not math.isfinite(value) or value < 0):
            raise ValueError("Coordinates must be finite nonnegative points")
    if args.bundle:
        validate_bundle(args.bundle)
    data.update({k: v for k, v in fields.items() if v is not None})
    return data


def session_command(args):
    root = Path(args.session).resolve()
    # Local lock prevents two clients from overwriting a pending mailbox action.
    with (root / "client.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        state = json.loads((root / "session.json").read_text())
        if args.command == "run-control":
            if state.get("started"):
                raise ValueError("Already started; prepare a fresh session instead of replaying this test")
            state["started"] = True
            save(root / "session.json", state)
        else:
            if state.get("closed"):
                raise ValueError("Session is closed; prepare a new one")
            if args.command == "action":
                if not state.get("ready") or state.get("pending") is not None:
                    raise ValueError("Collect the initial snapshot or pending action before issuing another")
                payload = action_payload(args, state)
                request = root / ("action-%d.json" % payload["id"])
                save(request, payload)
                # Persist BEFORE transfer: timeout/crash must never silently enable replay.
                state["pending"] = payload["id"]
                state["pending_kind"] = payload["kind"]
                save(root / "session.json", state)
                r = copy_file(state, "to", request, remote(state, "action.json"))
                if r.returncode:
                    raise ValueError("Transfer uncertain; pending action retained. " + (r.stderr or r.stdout)[-600:])
            action_id = state["pending"] if state.get("pending") is not None else state["next_id"] - 1
            observe(state, root, action_id, args.timeout)
            if state.get("pending_kind") == "done":
                state["closed"] = True
            state.update(ready=True, pending=None, pending_kind=None, next_id=action_id + 1)
            save(root / "session.json", state)
            return
    # Release client lock while the long-lived test runs in terminal A.
    run(xcode(root / "HelloWorld.xcodeproj", root / "DerivedData", state) + [
        "-parallel-testing-enabled", "NO", "-default-test-execution-time-allowance", "2100",
        "-maximum-test-execution-time-allowance", "2100",
        "-test-timeouts-enabled", "YES", "-only-testing:HelloWorldUITests/FlightUITests/testControlSession",
        "-resultBundlePath", str(root / "Control.xcresult"), "test"], root / "runner.log")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ["doctor", "devices", "build", "build-for-testing", "deploy", "test-ui", "test-engine", "apps"]:
        commands.add_parser(name)
    p = commands.add_parser("screenshot"); p.add_argument("output")
    p = commands.add_parser("prepare-control"); p.add_argument("--app", required=True)
    for name in ["run-control", "collect", "action"]:
        p = commands.add_parser(name); p.add_argument("session")
        if name != "run-control":
            p.add_argument("--timeout", type=float, default=240)
        if name == "action":
            p.add_argument("kind", choices=["snapshot", "tap", "tap-id", "drag", "type", "activate", "home", "done"])
            for flag in ["x", "y", "end-x", "end-y"]:
                p.add_argument("--" + flag, type=float)
            for flag in ["text", "identifier", "bundle"]:
                p.add_argument("--" + flag)
    args = parser.parse_args()
    if args.command in ["run-control", "collect", "action"]:
        if hasattr(args, "timeout") and (not math.isfinite(args.timeout) or args.timeout <= 0):
            raise ValueError("timeout must be finite and positive")
        session_command(args); return
    if args.command == "doctor":
        for command in [["xcode-select", "-p"], ["xcodebuild", "-version"],
                        ["xcrun", "--find", "devicectl"], ["xcrun", "--find", "swiftc"]]:
            run(command)
        print("Optional MCP:", shutil.which("codex") or "Codex CLI not found; Codex app may still be available")
        return
    if args.command == "devices":
        run(["xcrun", "devicectl", "list", "devices", "--timeout", "30"]); return
    BUILD.mkdir(exist_ok=True)
    if args.command == "test-engine":
        run(["xcrun", "swiftc", "-module-cache-path", str(BUILD / "ModuleCache"),
             "HelloWorld/GameEngine.swift", "Tests/GameEngineChecks.swift", "-o", str(BUILD / "engine-checks")])
        run([str(BUILD / "engine-checks")]); return
    if args.command in ["build", "build-for-testing"]:
        run(xcode(ROOT / "HelloWorld.xcodeproj", BUILD / "Unsigned") + [args.command], BUILD / (args.command + ".log")); return
    c = config()
    if args.command == "apps":
        run(device(c, "info", "apps", "--include-all-apps")); return
    if args.command == "screenshot":
        output = Path(args.output).resolve(); output.parent.mkdir(parents=True, exist_ok=True)
        run(device(c, "capture", "screenshot", "--destination", str(output))); return
    if args.command == "prepare-control":
        validate_bundle(args.app)
        session = uuid.uuid4().hex
        root = BUILD / "control" / session
        for name in ["HelloWorld", "HelloWorld.xcodeproj"]:
            shutil.copytree(ROOT / name, root / name, ignore=shutil.ignore_patterns("xcuserdata"))
        (root / "HelloWorldUITests").mkdir()
        encoded = base64.b64encode(json.dumps({"session": session, "app": args.app}).encode()).decode()
        template = (ROOT / "automation/ControlTests.swift").read_text().replace("__CONFIG_BASE64__", encoded)
        (root / "HelloWorldUITests/FlightUITests.swift").write_text(template)
        state = dict(c, session=session, runner=c["bundle_id"] + ".uitests.xctrunner", next_id=1,
                     pending=None, ready=False, closed=False)
        save(root / "session.json", state)
        print("Session:", root)
        print("Terminal A: python3 scripts/iphone.py run-control", root)
        print("Terminal B: python3 scripts/iphone.py collect", root)
        return
    base = xcode(ROOT / "HelloWorld.xcodeproj", BUILD / "Signed", c)
    if args.command == "test-ui":
        result = BUILD / ("UITests-" + uuid.uuid4().hex + ".xcresult")
        run(base + ["-parallel-testing-enabled", "NO", "-resultBundlePath", str(result), "test"], BUILD / "test-ui.log")
        run(["xcrun", "xcresulttool", "export", "attachments", "--path", str(result),
             "--output-path", str(result.with_suffix(".attachments"))]); return
    run(base + ["build"], BUILD / "deploy-build.log")
    app = BUILD / "Signed/Build/Products/Debug-iphoneos/HelloWorld.app"
    run(["codesign", "--verify", "--deep", "--strict", str(app)])
    run(device(c, "install", "app", str(app), "--json-output", str(BUILD / "install.json")))
    run(device(c, "process", "launch", "--terminate-existing", "--json-output", str(BUILD / "launch.json"), c["bundle_id"]))
    run(device(c, "info", "processes", "--json-output", str(BUILD / "processes.json")), BUILD / "processes.log")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.SubprocessError) as exc:
        print("ERROR:", exc, file=sys.stderr)
        sys.exit(1)
