"""Host-side protocol regression tests. No device is touched."""
import argparse
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("iphone", Path(__file__).parents[1] / "scripts/iphone.py")
iphone = importlib.util.module_from_spec(spec)
spec.loader.exec_module(iphone)


class ControlProtocolTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.state = dict(session="abc", device="test-device", runner="com.test.runner", next_id=1,
                          ready=True, pending=None, closed=False)
        iphone.save(self.root / "session.json", self.state)

    def args(self, command="action", kind="tap", **kw):
        fields = dict(command=command, session=str(self.root), timeout=0.001, kind=kind,
                      x=10, y=20, end_x=None, end_y=None, text=None, identifier=None, bundle=None)
        fields.update(kw)
        return argparse.Namespace(**fields)

    def read(self):
        return json.loads((self.root / "session.json").read_text())

    def test_failed_transfer_retains_pending_and_blocks_next_action(self):
        with patch.object(iphone, "copy_file", return_value=subprocess.CompletedProcess([], 1, "offline", "")) as copy:
            with self.assertRaises(ValueError): iphone.session_command(self.args())
            self.assertEqual(self.read()["pending"], 1)
            with self.assertRaises(ValueError): iphone.session_command(self.args())
            self.assertEqual(copy.call_count, 1)

    def test_timeout_collects_without_resending(self):
        with patch.object(iphone, "copy_file", return_value=subprocess.CompletedProcess([], 0, "", "")) as copy:
            with patch.object(iphone, "observe", side_effect=ValueError("timeout")):
                with self.assertRaises(ValueError): iphone.session_command(self.args())
            self.assertEqual(self.read()["pending"], 1)
            with patch.object(iphone, "observe") as observe:
                iphone.session_command(self.args(command="collect"))
                self.assertEqual(observe.call_args.args[2], 1)
            self.assertEqual(copy.call_count, 1)
            self.assertEqual(self.read()["next_id"], 2)

    def test_done_closes_session(self):
        with patch.object(iphone, "copy_file", return_value=subprocess.CompletedProcess([], 0, "", "")), patch.object(iphone, "observe"):
            iphone.session_command(self.args(kind="done"))
            self.assertTrue(self.read()["closed"])
            with self.assertRaises(ValueError): iphone.session_command(self.args())

    def test_initial_collection_uses_zero(self):
        self.state["ready"] = False
        iphone.save(self.root / "session.json", self.state)
        with patch.object(iphone, "observe") as observe:
            iphone.session_command(self.args(command="collect"))
            self.assertEqual(observe.call_args.args[2], 0)
            self.assertTrue(self.read()["ready"])

    def test_rejects_invalid_coordinates_and_missing_text_before_transfer(self):
        with patch.object(iphone, "copy_file") as copy:
            for args in [self.args(x=float("nan")), self.args(x=-1), self.args(kind="type")]:
                with self.assertRaises(ValueError): iphone.session_command(args)
            copy.assert_not_called()
            self.assertIsNone(self.read()["pending"])

    def test_rejects_ack_from_another_session(self):
        def wrong_ack(state, direction, source, destination):
            Path(destination).write_text(json.dumps(dict(session="stale", id=1, status="ok")))
            return subprocess.CompletedProcess([], 0, "", "")
        with patch.object(iphone, "copy_file", side_effect=wrong_ack):
            with self.assertRaisesRegex(ValueError, "Unexpected acknowledgement"):
                iphone.observe(self.state, self.root, 1, 2)

    def test_unicode_and_shell_metacharacters_stay_data(self):
        text = '你好 $(touch nope) `whoami` "quoted"'
        payload = iphone.action_payload(self.args(kind="type", text=text), self.state)
        self.assertEqual(payload["text"], text)
        iphone.save(self.root / "action.json", payload)
        self.assertEqual(json.loads((self.root / "action.json").read_text())["text"], text)

    def test_launch_options_precede_bundle_argument(self):
        cmd = iphone.device({"device": "real-udid"}, "process", "launch", "--json-output", "out.json", "com.example.app")
        self.assertEqual(cmd[-1], "com.example.app")
        self.assertLess(cmd.index("--device"), cmd.index("com.example.app"))


if __name__ == "__main__":
    unittest.main()
