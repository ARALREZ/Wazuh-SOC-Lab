#!/usr/bin/env python3
"""Read-only check of Project 03 FIM alerts for one regression TEST_ID.

Run on my-server after the Agent regression suite has finished and alerts have
arrived in /var/ossec/logs/alerts/alerts.json. NUL-containing malformed lines
are skipped without modifying the source file.
"""
import argparse
import json
import sys
from collections import Counter


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--test-id", required=True, help="Exact TEST_ID printed by Agent runner")
    parser.add_argument("--agent-id", default="001")
    parser.add_argument("--alerts-file", default="/var/ossec/logs/alerts/alerts.json")
    parser.add_argument("--expected-rule", default="100030", help="Expected base rule ID for watch-directory events")
    parser.add_argument("--output-jsonl", help="Optional path to export only matching alert records")
    args = parser.parse_args()

    found = []
    malformed = 0
    with open(args.alerts_file, "rb") as stream:
        for raw in stream:
            if not raw.strip():
                continue
            if b"\x00" in raw:
                malformed += 1
                continue
            try:
                record = json.loads(raw.decode("utf-8"))
            except (ValueError, UnicodeDecodeError):
                malformed += 1
                continue
            agent = record.get("agent", {})
            if not isinstance(agent, dict) or agent.get("id") != args.agent_id:
                continue
            syscheck = record.get("syscheck", {})
            if not isinstance(syscheck, dict):
                continue
            path = syscheck.get("path", "")
            if isinstance(path, str) and args.test_id in path:
                found.append(record)

    found.sort(key=lambda item: item.get("timestamp", ""))
    counts = Counter(str(item.get("rule", {}).get("id", "-")) for item in found)

    print(f"TEST_ID: {args.test_id}")
    print(f"AGENT_ID: {args.agent_id}")
    print(f"MATCHING_ALERTS: {len(found)}")
    print(f"MALFORMED_OR_NUL_LINES_SKIPPED: {malformed}")

    for record in found:
        syscheck = record.get("syscheck", {})
        rule = record.get("rule", {})
        audit = syscheck.get("audit", {})
        if not isinstance(audit, dict):
            audit = {}
        login = audit.get("login_user", {})
        process = audit.get("process", {})
        if not isinstance(login, dict):
            login = {}
        if not isinstance(process, dict):
            process = {}
        print("\n---")
        print("TIME:", record.get("timestamp"))
        print("RULE:", rule.get("id"), "LEVEL:", rule.get("level"))
        print("EVENT:", syscheck.get("event"))
        print("PATH:", syscheck.get("path"))
        print("LOGIN_USER:", login.get("name"), "UID:", login.get("id"))
        print("PROCESS:", process.get("name"))

    print("\nRULE_COUNTS:", dict(counts))
    if args.output_jsonl:
        with open(args.output_jsonl, "w", encoding="utf-8") as output:
            for record in found:
                output.write(json.dumps(record, ensure_ascii=False) + "\n")
        print("EXPORTED_JSONL:", args.output_jsonl)
    if not found:
        print("[FAIL] No matching FIM alerts found. Check propagation and TEST_ID.")
        return 1
    if args.expected_rule and args.expected_rule not in counts:
        print(f"[FAIL] Expected rule {args.expected_rule} was not observed.")
        return 1
    print(f"[PASS] FIM alerts observed; expected rule {args.expected_rule} present.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
