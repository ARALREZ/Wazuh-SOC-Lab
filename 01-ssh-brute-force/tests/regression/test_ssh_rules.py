
#!/usr/bin/env python3

import argparse
import re
import subprocess
import sys
import time
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LOGTEST = "/var/ossec/bin/wazuh-logtest"

CUSTOM_RULES = {
    100001, 100002, 100003,
    100004, 100005, 100010
}

RULE_LEVELS = {
    100001: 6,
    100002: 10,
    100003: 6,
    100004: 10,
    100005: 14,
    100010: 3,
}


def case(name, filename, exact=None, required_at=None,
         must_have=None, allowed=None, forbidden=None,
         delays=None, critical_last=False):

    return {
        "name": name,
        "file": ROOT / filename,
        "exact": exact,
        "required_at": required_at or {},
        "must_have": set(must_have or []),
        "allowed": set(allowed) if allowed is not None else None,
        "forbidden": set(forbidden or []),
        "delays": delays,
        "critical_last": critical_last,
    }


EMPTY = set()

FAST_CASES = [
    case("Two failed logins",
         "tests/negative/normal-failed-login.log",
         exact=[EMPTY, EMPTY]),

    case("Three failed logins",
         "tests/positive/brute-force-3fails.log",
         exact=[EMPTY, EMPTY, {100001}]),

    case("Five failed logins",
         "tests/positive/brute-force-5fails.log",
         exact=[EMPTY, EMPTY, {100001}, EMPTY, {100002}]),

    case("Five failures followed by successful login",
         "tests/positive/brute-force-success-after-5fails.log",
         exact=[EMPTY, EMPTY, {100001}, EMPTY, {100002}, {100005}],
         must_have={100001, 100002, 100005},
         allowed={100001, 100002, 100005},
         critical_last=True),


    case("Ten failed logins",
         "tests/positive/brute-force-10fails.log",
         required_at={2: 100001, 4: 100002},
         must_have={100001, 100002},
         allowed={100001, 100002}),

    case("Three failures followed by success",
         "tests/positive/brute-force-success-after-3fails.log",
         exact=[EMPTY, EMPTY, {100001}, {100005}],
         must_have={100001, 100005},
         critical_last=True),

    case("Eight failures followed by success",
         "tests/positive/brute-force-success-after-8fails.log",
         required_at={2: 100001, 4: 100002},
         must_have={100001, 100002, 100005},
         allowed={100001, 100002, 100005},
         critical_last=True),

    case("Success by different user",
         "tests/negative/different-user-success.log",
         required_at={2: 100001},
         allowed={100001},
         forbidden={100005}),

    case("Success from different IP",
         "tests/negative/different-source-success.log",
         required_at={2: 100001},
         allowed={100001},
         forbidden={100005}),

    case("Mixed users from same IP",
         "tests/negative/mixed-users-failed-login.log",
         required_at={2: 100001},
         allowed={100001}),

    case("Mixed source IP addresses",
         "tests/negative/mixed-sources-failed-login.log",
         exact=[EMPTY, EMPTY, EMPTY]),

    case("Trusted administrator",
         "tests/negative/trusted-admin-failed-login.log",
         exact=[{100010}, {100010}, {100010}]),

    case("Normal successful login",
         "tests/negative/normal-successful-login.log",
         exact=[EMPTY]),

    case("Public key failure",
         "tests/positive/publickey-failure.log",
         exact=[{100003}]),

    case("Two failures boundary",
         "tests/boundary/brute-force-2fails.log",
         exact=[EMPTY, EMPTY]),

    case("Four failures boundary",
         "tests/boundary/brute-force-4fails.log",
         exact=[EMPTY, EMPTY, {100001}, EMPTY]),

    case("Success after only two failures",
         "tests/boundary/success-after-2-fails.log",
         exact=[EMPTY, EMPTY, EMPTY]),
]


SLOW_CASES = [
    case("Five-user password spraying",
         "tests/positive/password-spray-5users.log",
         exact=[EMPTY, EMPTY, EMPTY, EMPTY, {100004}],
         delays=[61, 61, 61, 61, 0]),

    case("Five failures outside 120 seconds",
         "tests/boundary/five-fails-outside-120s.log",
         exact=[EMPTY, EMPTY, EMPTY, EMPTY, EMPTY],
         delays=[61, 61, 61, 61, 0]),

    case("Four-user spraying boundary",
         "tests/boundary/password-spray-4users.log",
         exact=[EMPTY, EMPTY, EMPTY, EMPTY],
         delays=[61, 61, 61, 0]),

    case("One-user is not password spraying",
         "tests/boundary/password-spray-one-user.log",
         exact=[EMPTY, EMPTY, EMPTY, EMPTY, EMPTY],
         delays=[61, 61, 61, 61, 0]),

    case("Slow failed logins outside 120 seconds",
         "tests/negative/slow-failed-login.log",
         exact=[EMPTY, EMPTY, EMPTY],
         delays=[61, 61, 0]),

    case("Success after 300 seconds",
         "tests/boundary/success-after-300s.log",
         exact=[EMPTY, EMPTY, {100001}, EMPTY],
         delays=[2, 2, 301, 0]),
]


def run_logtest(lines, delays):
    # Temporary files avoid stdout/stderr pipe-buffer deadlocks
    # when wazuh-logtest emits output for multiple events.
    with tempfile.TemporaryFile(mode="w+t") as stdout_file, \\
         tempfile.TemporaryFile(mode="w+t") as stderr_file:

        proc = subprocess.Popen(
            [LOGTEST],
            stdin=subprocess.PIPE,
            stdout=stdout_file,
            stderr=stderr_file,
            text=True,
        )

        try:
            for line, delay in zip(lines, delays):
                if proc.poll() is not None:
                    raise RuntimeError(
                        f"wazuh-logtest exited early: {proc.returncode}"
                    )

                if proc.stdin is None:
                    raise RuntimeError("wazuh-logtest stdin is unavailable")

                proc.stdin.write(line + "\\n")
                proc.stdin.flush()

                if delay:
                    time.sleep(delay)

            if proc.stdin is not None:
                proc.stdin.close()
                proc.stdin = None

            try:
                proc.wait(timeout=sum(delays) + 90)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
                raise RuntimeError("wazuh-logtest timed out")

        except BaseException:
            if proc.poll() is None:
                proc.kill()
            proc.wait()
            raise

        stdout_file.seek(0)
        stderr_file.seek(0)

        stdout = stdout_file.read()
        stderr = stderr_file.read()

        if proc.returncode != 0:
            raise RuntimeError(stderr + "\\n" + stdout)

        return stdout + stderr


def parse_events(output):
    chunks = re.split(
        r"(?=\*\*Phase 1: Completed pre-decoding\.)",
        output
    )

    results = []

    for chunk in chunks:
        if "**Phase 1:" not in chunk:
            continue

        phase3 = re.search(
            r"\*\*Phase 3: Completed filtering \(rules\)\."
            r"(.*?)(?:\*\*Alert to be generated\.|\Z)",
            chunk,
            re.S
        )

        if not phase3:
            raise RuntimeError("Missing Phase 3 result")

        rule = re.search(
            r"^\s*id: '(\d+)'",
            phase3.group(1),
            re.M
        )
        level = re.search(
            r"^\s*level: '(\d+)'",
            phase3.group(1),
            re.M
        )

        if not rule or not level:
            raise RuntimeError("Cannot parse rule ID or level")

        results.append({
            "id": int(rule.group(1)),
            "level": int(level.group(1)),
        })

    return results


def run_case(test):
    path = test["file"]

    if not path.is_file():
        raise FileNotFoundError(path)

    lines = [
        line.strip()
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]

    if not lines:
        raise ValueError(f"Empty test: {path}")

    delays = test["delays"] or [0] * len(lines)

    if len(delays) != len(lines):
        raise ValueError("Delay count does not match event count")

    events = parse_events(run_logtest(lines, delays))

    if len(events) != len(lines):
        raise RuntimeError(
            f"Expected {len(lines)} events, got {len(events)}"
        )

    actual = [
        {event["id"]} & CUSTOM_RULES
        for event in events
    ]

    found = set().union(*actual)
    errors = []

    if test["exact"] is not None:
        if actual != test["exact"]:
            errors.append(
                f"Per-event mismatch: expected {test['exact']}, "
                f"got {actual}"
            )

    for index, rid in test["required_at"].items():
        if index >= len(actual) or rid not in actual[index]:
            errors.append(
                f"Rule {rid} missing on event #{index + 1}"
            )

    missing = test["must_have"] - found

    if missing:
        errors.append(f"Missing rules: {sorted(missing)}")

    if test["allowed"] is not None:
        unexpected = found - test["allowed"]

        if unexpected:
            errors.append(
                f"Unexpected rules: {sorted(unexpected)}"
            )

    forbidden = found & test["forbidden"]

    if forbidden:
        errors.append(
            f"Forbidden rules detected: {sorted(forbidden)}"
        )

    critical_positions = [
        i for i, rules in enumerate(actual)
        if 100005 in rules
    ]

    if test["critical_last"]:
        if critical_positions != [len(events) - 1]:
            errors.append(
                "100005 must trigger exclusively on the last event"
            )

    for event in events:
        rid = event["id"]

        if rid in RULE_LEVELS and event["level"] != RULE_LEVELS[rid]:
            errors.append(
                f"Rule {rid}: expected level {RULE_LEVELS[rid]}, "
                f"got {event['level']}"
            )

    trace = ", ".join(
        f"#{i + 1}:{e['id']}/L{e['level']}"
        for i, e in enumerate(events)
    )

    if errors:
        print(f"[FAIL] {test['name']}")
        for error in errors:
            print("   ", error)
        print("   ", trace)
        return False

    print(f"[PASS] {test['name']}")
    print("   ", trace)
    return True


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--include-slow",
        action="store_true",
        help="Run time-window tests with real delays"
    )
    args = parser.parse_args()

    if not Path(LOGTEST).is_file():
        print("[ERROR] Run on Wazuh Manager")
        return 2

    tests = FAST_CASES + (
        SLOW_CASES if args.include_slow else []
    )

    passed = 0
    failed = 0

    for test in tests:
        try:
            if run_case(test):
                passed += 1
            else:
                failed += 1
        except Exception as error:
            failed += 1
            print(f"[ERROR] {test['name']}: {error}")

    print("\n===== REGRESSION SUMMARY =====")
    print(f"Total:  {len(tests)}")
    print(f"PASS:   {passed}")
    print(f"FAIL:   {failed}")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
