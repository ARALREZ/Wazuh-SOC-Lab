#!/usr/bin/env python3
"""Basic regression checks for the synthetic GCP IAM audit event."""

import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
POSITIVE_EVENT = ROOT / "tests" / "positive" / "iam-policy-change.json"
NEGATIVE_EVENT = ROOT / "tests" / "negative" / "iam-policy-read.json"


def load_event(path):
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def method_name(event):
    return (
        event.get("protoPayload", {}).get("methodName")
        or event.get("gcp", {}).get("protoPayload", {}).get("methodName")
    )


class TestIAMPolicyEvents(unittest.TestCase):
    def test_positive_event_is_valid_json(self):
        event = load_event(POSITIVE_EVENT)
        self.assertIsInstance(event, dict)

    def test_positive_event_represents_iam_policy_change(self):
        event = load_event(POSITIVE_EVENT)
        self.assertEqual(method_name(event), "SetIamPolicy")

    def test_negative_event_is_valid_json(self):
        event = load_event(NEGATIVE_EVENT)
        self.assertIsInstance(event, dict)

    def test_negative_event_does_not_match_policy_change(self):
        event = load_event(NEGATIVE_EVENT)
        self.assertNotEqual(method_name(event), "SetIamPolicy")


if __name__ == "__main__":
    unittest.main(verbosity=2)
