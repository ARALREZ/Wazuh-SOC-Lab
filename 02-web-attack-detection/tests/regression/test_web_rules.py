#!/usr/bin/env python3
"""Regression runner for Project 02 custom web rules.

Run on the Wazuh Manager, where /var/ossec/bin/wazuh-logtest is installed.
Each fixture is sent as one logtest session so multi-line correlation cases keep
one session history. This validates rule matching, not Active Response execution.
"""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_LOGTEST = "/var/ossec/bin/wazuh-logtest"
CUSTOM_RULES = {str(n) for n in range(100020, 100030)}
HIGH_RULES = {str(n) for n in range(100020, 100028)} | {"100029"}
RULE_ID_RE = re.compile(r"\bid:\s*['\"](\d+)['\"]")

@dataclass(frozen=True)
class Case:
    name: str
    fixture: str
    include: frozenset[str] = frozenset()
    exclude: frozenset[str] = frozenset()
    note: str = ""

FAST_CASES = [
    Case("Scanner User-Agent", "tests/positive/scanner-user-agent.log", frozenset({"100020"})),
    Case("SQL Injection", "tests/positive/sqli-detected.log", frozenset({"100021"})),
    Case("XSS", "tests/positive/xss-detected.log", frozenset({"100022"})),
    Case("Path Traversal", "tests/positive/path-traversal-detected.log", frozenset({"100023"})),
    Case("Command Injection", "tests/positive/command-injection-attempt.log", frozenset({"100024"})),
    Case("Suspicious URI scheme", "tests/positive/suspicious-uri-scheme.log", frozenset({"100029"})),
    Case("Trusted benign request", "tests/negative/trusted-source-traffic.log", frozenset({"100028"}), frozenset(HIGH_RULES)),
    Case("Ordinary traffic", "tests/negative/normal-traffic.log", exclude=frozenset(CUSTOM_RULES)),
    Case("Benign query parameters", "tests/negative/benign-query-parameters.log", exclude=frozenset(CUSTOM_RULES)),
    Case("Ordinary 404", "tests/negative/ordinary-404.log", exclude=frozenset(CUSTOM_RULES)),
    Case("Four scanners below threshold", "tests/boundary/scanner-4-requests.log", exclude=frozenset({"100025", "100027"})),
    Case("Five scanners reach correlation", "tests/boundary/scanner-5-requests.log", frozenset({"100025"})),
    Case("Two exploit requests below correlation threshold", "tests/boundary/exploit-2-requests.log", exclude=frozenset({"100026", "100027"})),
    Case("Three same-technique attacks correlate", "tests/boundary/exploit-3-requests.log", frozenset({"100026"})),
    Case("Mixed web attacks correlate", "tests/positive/repeated-web-attacks.log", frozenset({"100026"})),
    Case("Scanner followed by exploit", "tests/positive/scanner-then-exploit.log", frozenset({"100027"})),
]

EXTENDED_CASES = [
    Case("Different source IPs do not correlate", "tests/boundary/different-source-attacks.log", exclude=frozenset({"100026"})),
    Case("Scanner and exploit from different IPs", "tests/boundary/scanner-and-exploit-different-source.log", exclude=frozenset({"100027"})),
    Case("Trusted source attack exclusion", "tests/boundary/trusted-source-attack.log", frozenset({"100028"}), frozenset(HIGH_RULES),
         "Native Wazuh rules may still alert; this checks custom Project 02 IDs only."),
]


def run_case(case: Case, logtest: str, timeout: int) -> tuple[bool, set[str], str]:
    path = PROJECT_ROOT / case.fixture
    if not path.is_file():
        return False, set(), f"missing fixture: {case.fixture}"
    lines = [line.strip() for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    if not lines:
        return False, set(), "fixture is empty"
    try:
        result = subprocess.run(
            [logtest, "-v"], input="\n".join(lines) + "\n",
            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
            timeout=timeout, check=False,
        )
    except FileNotFoundError:
        return False, set(), f"wazuh-logtest not found: {logtest}"
    except subprocess.TimeoutExpired:
        return False, set(), f"wazuh-logtest exceeded {timeout}s"

    found = set(RULE_ID_RE.findall(result.stdout))
    missing = case.include - found
    unexpected = case.exclude & found
    ok = result.returncode == 0 and not missing and not unexpected
    detail = []
    if result.returncode != 0:
        detail.append(f"exit={result.returncode}")
    if missing:
        detail.append("missing=" + ",".join(sorted(missing)))
    if unexpected:
        detail.append("unexpected=" + ",".join(sorted(unexpected)))
    if not found:
        detail.append("no rule IDs parsed from logtest output")
    return ok, found, "; ".join(detail)


def main() -> int:
    parser = argparse.ArgumentParser(description="Run Project 02 fixtures through wazuh-logtest")
    parser.add_argument("--logtest", default=DEFAULT_LOGTEST, help=f"path to wazuh-logtest (default: {DEFAULT_LOGTEST})")
    parser.add_argument("--suite", choices=("fast", "extended", "all"), default="fast")
    parser.add_argument("--timeout", type=int, default=20)
    args = parser.parse_args()

    if args.suite == "fast":
        cases = FAST_CASES
    elif args.suite == "extended":
        cases = EXTENDED_CASES
    else:
        cases = FAST_CASES + EXTENDED_CASES

    print("Project 02 — Wazuh web rules regression")
    print(f"logtest: {args.logtest}")
    print(f"suite: {args.suite}; cases: {len(cases)}")
    print("NOTE: logtest validates rule matching only; it does not execute Active Response.")

    passed = failed = 0
    for index, case in enumerate(cases, 1):
        ok, found, detail = run_case(case, args.logtest, args.timeout)
        ids = ",".join(sorted(found)) if found else "none"
        status = "PASS" if ok else "FAIL"
        print(f"[{status}] {index:02d}. {case.name} | rule IDs: {ids}")
        if detail:
            print(f"       {detail}")
        if case.note:
            print(f"       Note: {case.note}")
        if ok:
            passed += 1
        else:
            failed += 1

    # Time-window expiry is deliberately not counted in the fast suite.
    print("[MANUAL] attack-outside-180s.log is a time-window boundary fixture.")
    print("         Validate it with a real delayed replay; do not treat fast logtest input as proof of elapsed wall-clock time.")
    print(f"\nSummary: {passed}/{len(cases)} PASS, {failed} FAIL")
    return 0 if failed == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
