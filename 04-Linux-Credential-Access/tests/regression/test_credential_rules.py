#!/usr/bin/env python3
"""Synthetic regression runner for Project 04; run on my-server as root."""

from __future__ import annotations

import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOGTEST = Path("/var/ossec/bin/wazuh-logtest")
BASE_EVENT_FILE = ROOT / "tests/positive/shadow_access_failed.log"
CUSTOM_IDS = {100040, 100041, 100042}


def make_event(base: str, index: int, auid: int = 1008, success: str = "no", key: str = "shadow_access") -> str:
    now = time.time() + index * 0.2
    seconds = int(now)
    millis = int((now - seconds) * 1000)
    event = re.sub(
        r"msg=audit\(\d+\.\d+:(\d+)\):",
        f"msg=audit({seconds}.{millis:03d}:{9000 + index}):",
        base,
        count=1,
    )
    event = re.sub(r"\bauid=\d+", f"auid={auid}", event, count=1)
    event = re.sub(r"\bsuccess=(yes|no)", f"success={success}", event, count=1)
    event = re.sub(r'key="[^"]+"', f'key="{key}"', event, count=1)
    if success == "yes":
        event = re.sub(r"\bexit=-13", "exit=6", event, count=1)
    return event


def run_case(name: str, events: list[str], expected: set[int]) -> bool:
    result = subprocess.run(
        [str(LOGTEST)],
        input="\n".join(events) + "\n",
        text=True,
        capture_output=True,
        timeout=30,
        check=False,
    )
    output = result.stdout + "\n" + result.stderr
    # Only match rule IDs in Phase 3; do not match the decoded audit.id field.
    found = {int(value) for value in re.findall(r"(?m)^\s*id:\s*'(\d+)'\s*$", output)} & CUSTOM_IDS
    passed = result.returncode == 0 and found == expected
    print(f"[{'PASS' if passed else 'FAIL'}] {name}: expected={sorted(expected)} observed={sorted(found)}")
    if not passed:
        print(output[-3000:])
    return passed


def main() -> int:
    if len(sys.argv) > 1:
        print("This runner takes no arguments.", file=sys.stderr)
        return 2
    if not LOGTEST.is_file():
        print(f"ERROR: {LOGTEST} not found. Run on the Wazuh Manager.", file=sys.stderr)
        return 2
    if hasattr(__import__("os"), "geteuid") and __import__("os").geteuid() != 0:
        print("ERROR: run with sudo: sudo python3 test_credential_rules.py", file=sys.stderr)
        return 2
    if not BASE_EVENT_FILE.is_file():
        print(f"ERROR: fixture not found: {BASE_EVENT_FILE}", file=sys.stderr)
        return 2

    base = BASE_EVENT_FILE.read_text(encoding="utf-8").splitlines()[0]
    if 'key="shadow_access"' not in base or "success=no" not in base:
        print("ERROR: positive fixture must contain key=shadow_access and success=no", file=sys.stderr)
        return 2

    cases = [
        ("one denied event", [make_event(base, 1)], {100040}),
        ("two denied events / same AUID", [make_event(base, i) for i in (2, 3)], {100040}),
        ("three denied events / same AUID", [make_event(base, i) for i in (4, 5, 6)], {100040, 100041}),
        ("four denied events / same AUID", [make_event(base, i) for i in (7, 8, 9, 10)], {100040, 100041}),
        ("five denied events / same AUID", [make_event(base, i) for i in (11, 12, 13, 14, 15)], {100040, 100041, 100042}),
        ("five denied events / different AUIDs", [make_event(base, i, auid=2000 + i) for i in (16, 17, 18, 19, 20)], {100040}),
        ("successful access", [make_event(base, 21, success="yes")], set()),
        ("unrelated Auditd key", [make_event(base, 22, key="other_key")], set()),
    ]

    results = [run_case(name, events, expected) for name, events, expected in cases]
    passed = sum(results)
    failed = len(results) - passed
    print(f"\nSummary: {passed}/{len(results)} PASS, {failed} FAIL")
    return 0 if failed == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
