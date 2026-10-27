#!/usr/bin/env python3
"""
Simple regression helper for Scenario 02 web rules.
This is a documentation/placeholder script.
Real testing is done with wazuh-logtest + live attacks.
"""

RULES = {
    "100020": "Soft Scanner (User-Agent)",
    "100021": "SQL Injection",
    "100022": "XSS",
    "100023": "Path Traversal / LFI",
    "100024": "Command Injection",
    "100025": "Multiple scanners correlation",
    "100026": "Multiple attack types correlation",
    "100027": "Attack after scanner (layered)",
    "100028": "Trusted IP",
    "100029": "Suspicious patterns",
}

def main():
    print("Scenario 02 - Web Attack Rules Regression Checklist")
    print("=" * 55)
    for rid, desc in RULES.items():
        print(f"[ ] {rid} - {desc}")
    print("=" * 55)
    print("Run live attacks and mark PASS/FAIL in reports/test-results.md")

if __name__ == "__main__":
    main()
