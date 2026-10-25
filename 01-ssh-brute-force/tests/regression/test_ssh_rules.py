#!/usr/bin/env python3
"""Regression checks for SSH brute-force rules"""

EXPECTED_RULES = ["100010", "100001", "100002", "100005"]

def test_rule_ids():
    print("[+] Expected rule IDs:", EXPECTED_RULES)
    print("[+] Verify manually in Wazuh Dashboard or alerts.json")
    print("[+] 100010 = Trusted IP")
    print("[+] 100001 = Soft (3 fails)")
    print("[+] 100002 = Brute Force (5 fails)")
    print("[+] 100005 = Critical (success after brute)")

if __name__ == "__main__":
    test_rule_ids()
    print("[+] Regression check finished")
