#!/usr/bin/env python3
"""
Regression helper for Scenario 04 rules.
Usage (on manager): feed sample logs into wazuh-logtest manually
or extend this script to call wazuh-logtest via subprocess.
"""

POSITIVE = "tests/positive/shadow_access_failed.log"
NEGATIVE = [
    "tests/negative/normal_sudo.log",
    "tests/negative/trusted_process.log",
]

EXPECTED = {
    "positive": ["100040"],
    "negative_note": "sudo/passwd may still match 100040 (key-based); tune with exe filters if needed",
}

def main():
    print("Scenario 04 - Credential Access rule regression checklist")
    print("=" * 60)
    print(f"[+] Positive sample: {POSITIVE}")
    print("    Expected: rule 100040 (soft)")
    print()
    for path in NEGATIVE:
        print(f"[+] Negative sample: {path}")
        print(f"    Note: {EXPECTED['negative_note']}")
    print()
    print("Manual validation:")
    print("  sudo /var/ossec/bin/wazuh-logtest < tests/positive/shadow_access_failed.log")
    print("  Check Dashboard for 100040 / 100041 / 100042 after live attack_simulation.sh")

if __name__ == "__main__":
    main()
