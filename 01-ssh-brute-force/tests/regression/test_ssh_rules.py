#!/usr/bin/env python3

import re
import subprocess
import sys

from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]

LOGTEST = "/var/ossec/bin/wazuh-logtest"

RULE_PATTERN = re.compile(r"id:\s*'(\d+)'")

PHASE_PATTERN = re.compile(
    r"\*\*Phase 1: Completed pre-decoding\."
)

CUSTOM_RULES = {
    100001,
    100002,
    100005,
    100010,
}


CASES = [

    {
        "name": "Two failed logins",
        "file": ROOT / "tests/negative/normal-failed-login.log",
        "expected": set(),
    },

    {
        "name": "Three failed logins",
        "file": ROOT / "tests/positive/brute-force-3fails.log",
        "expected": {100001},
    },

    {
        "name": "Five failed logins",
        "file": ROOT / "tests/positive/brute-force-5fails.log",
        "expected": {100001},
    },

    {
        "name": "Ten failed logins",
        "file": ROOT / "tests/positive/brute-force-10fails.log",
        "expected": {100001, 100002},
    },

    {
        "name": "Three failures followed by success",
        "file": ROOT / "tests/positive/brute-force-success-after-3fails.log",
        "expected": {100001, 100005},
        "critical_on_last": True,
    },

    {
        "name": "Eight failures followed by success",
        "file": ROOT / "tests/positive/brute-force-success-after-8fails.log",
        "expected": {100001, 100005},
        "critical_on_last": True,
    },

    {
        "name": "Success for a different user",
        "file": ROOT / "tests/negative/different-user-success.log",
        "expected": {100001},
    },

    {
        "name": "Success from a different source IP",
        "file": ROOT / "tests/negative/different-source-success.log",
        "expected": {100001},
    },

    {
        "name": "Different users",
        "file": ROOT / "tests/negative/mixed-users-failed-login.log",
        "expected": set(),
    },

    {
        "name": "Different source IP addresses",
        "file": ROOT / "tests/negative/mixed-sources-failed-login.log",
        "expected": set(),
    },

    {
        "name": "Slow failed logins",
        "file": ROOT / "tests/negative/slow-failed-login.log",
        "expected": set(),
    },

    {
        "name": "Trusted administrator",
        "file": ROOT / "tests/negative/trusted-admin-failed-login.log",
        "expected": {100010},
    },

    {
        "name": "Normal successful login",
        "file": ROOT / "tests/negative/normal-successful-login.log",
        "expected": set(),
    },

]


def run_case(case):

    log_file = case["file"]

    if not log_file.is_file():
        raise FileNotFoundError(
            f"Missing test file: {log_file}"
        )

    log_content = log_file.read_text(
        encoding="utf-8"
    )

    log_lines = [
        line
        for line in log_content.splitlines()
        if line.strip()
    ]

    if not log_lines:
        raise ValueError(
            f"Empty test file: {log_file}"
        )

    result = subprocess.run(
        [LOGTEST],
        input="\n".join(log_lines) + "\n",
        text=True,
        capture_output=True,
        timeout=30,
        check=False,
    )

    output = result.stdout + result.stderr

    if result.returncode != 0:
        raise RuntimeError(
            f"wazuh-logtest failed:\n"
            f"{result.stderr}\n{output}"
        )

    # Separate output into individual analyzed events.

    blocks = PHASE_PATTERN.split(output)

    event_blocks = [
        block for block in blocks
        if "Phase 2:" in block or "Phase 3:" in block
    ]

    if len(event_blocks) != len(log_lines):
        raise RuntimeError(
            f"Expected {len(log_lines)} event results, "
            f"received {len(event_blocks)}."
        )

    event_rules = []

    for block in event_blocks:

        ids = {
            int(rule_id)
            for rule_id in RULE_PATTERN.findall(block)
        }

        event_rules.append(
            ids & CUSTOM_RULES
        )

    found = set().union(*event_rules)

    expected = case["expected"]

    missing = expected - found
    unexpected = found - expected

    failures = []

    if missing:
        failures.append(
            f"Missing rules: {sorted(missing)}"
        )

    if unexpected:
        failures.append(
            f"Unexpected rules: {sorted(unexpected)}"
        )

    # Critical correlation must happen on the successful
    # authentication event, not on an earlier failed event.

    critical_positions = [
        index
        for index, rules in enumerate(event_rules)
        if 100005 in rules
    ]

    if case.get("critical_on_last"):

        expected_position = len(event_rules) - 1

        if critical_positions != [expected_position]:
            failures.append(
                "Rule 100005 did not trigger exclusively "
                "on the last event."
            )

    elif critical_positions:

        failures.append(
            "Unexpected critical alert 100005."
        )

    if failures:

        print(f"[FAIL] {case['name']}")

        for failure in failures:
            print(f"       {failure}")

        print(f"       Expected: {sorted(expected)}")
        print(f"       Found:    {sorted(found)}")

        return False

    print(
        f"[PASS] {case['name']} -> {sorted(found)}"
    )

    return True


def main():

    if not Path(LOGTEST).is_file():

        print(
            "[ERROR] Run this test on the Wazuh Manager."
        )

        sys.exit(2)

    failures = 0

    for case in CASES:

        try:

            if not run_case(case):
                failures += 1

        except Exception as error:

            print(
                f"[ERROR] {case['name']}: {error}"
            )

            failures += 1

    print()
    print(f"Total cases: {len(CASES)}")
    print(f"Passed: {len(CASES) - failures}")
    print(f"Failed: {failures}")

    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
