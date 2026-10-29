#!/usr/bin/env python3
"""
Basic regression checks for Scenario 03 FIM rules.
This is a simple helper script – real validation is done via wazuh-logtest / live tests.
"""

import os
import sys

RULES_FILE = "../../wazuh/rules/fim_system_tampering_rules.xml"

REQUIRED_RULES = ["100030", "100031", "100032", "100033"]

def check_rules_exist():
    if not os.path.exists(RULES_FILE):
        print(f"[FAIL] Rules file not found: {RULES_FILE}")
        return False

    with open(RULES_FILE) as f:
        content = f.read()

    missing = [r for r in REQUIRED_RULES if r not in content]
    if missing:
        print(f"[FAIL] Missing rules: {missing}")
        return False

    print("[PASS] All required rules (100030-100033) are present")
    return True

def main():
    print("=== FIM Rules Regression Test ===")
    success = check_rules_exist()
    if success:
        print("All basic checks passed.")
        sys.exit(0)
    else:
        print("Some checks failed.")
        sys.exit(1)

if __name__ == "__main__":
    main()
