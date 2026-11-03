
#!/usr/bin/env python3

import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]

LOGTEST = "/var/ossec/bin/wazuh-logtest"

RULE_PATTERN = re.compile(r"id:\s*'(\d+)'")

CASES = [
    {
        "name": "Two failed logins",
        "file": ROOT / "tests/negative/normal-failed-login.log",
        "expected": set(),
        "forbidden": {100001, 100002, 100005},
    },
    {
	"name": "Eight failures followed by success",
	"file": ROOT / "tests/positive/brute-force-success-after-8fails.log",
	"expected": {100001, 100002, 100005},
	"forbidden": set(),
    },
    {
        "name": "Five failed logins",
        "file": ROOT / "tests/positive/brute-force-5fails.log",
        "expected": {100001, 100002},
        "forbidden": set(),
    },
    {
        "name": "Three failures followed by success",
        "file": ROOT / "tests/positive/brute-force-success-after-3fails.log",
        "expected": {100001, 100005},
        "forbidden": {100002},
    },
    {
        "name": "Success for a different user",
        "file": ROOT / "tests/negative/different-user-success.log",
        "expected": {100001},
        "forbidden": {100005},
    },
    {
        "name": "Success from a different source IP",
        "file": ROOT / "tests/negative/different-source-success.log",
        "expected": {100001},
        "forbidden": {100005},
    },
]


def run_case(case):
    log_file = case["file"]

    if not log_file.is_file():
        raise FileNotFoundError(f"Missing test file: {log_file}")

    log_content = log_file.read_text(encoding="utf-8")

    result = subprocess.run(
        [LOGTEST],
        input=log_content,
        text=True,
        capture_output=True,
        timeout=30,
        check=False,
    )

    if result.returncode != 0:
        raise RuntimeError(
            f"wazuh-logtest failed:\n{result.stderr}\n{result.stdout}"
        )

    found = {
        int(rule_id)
        for rule_id in RULE_PATTERN.findall(result.stdout)
    }

    expected = case["expected"]
    forbidden = case["forbidden"]

    missing = expected - found
    unexpected = forbidden & found

    if missing or unexpected:
        print(f"[FAIL] {case['name']}")
        print(f"       Expected: {sorted(expected)}")
        print(f"       Found:    {sorted(found)}")
        print(f"       Missing:  {sorted(missing)}")
        print(f"       Forbidden:{sorted(unexpected)}")
        return False

    print(f"[PASS] {case['name']} -> {sorted(found)}")
    return True


def main():
    if not Path(LOGTEST).is_file():
        print("[ERROR] Run this test on the Wazuh Manager.")
        sys.exit(2)

    failures = 0

    for case in CASES:
        try:
            if not run_case(case):
                failures += 1
        except Exception as error:
            print(f"[ERROR] {case['name']}: {error}")
            failures += 1

    print()
    print(f"Total cases: {len(CASES)}")
    print(f"Passed: {len(CASES) - failures}")
    print(f"Failed: {failures}")

    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
