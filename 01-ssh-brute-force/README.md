cd ~/Wazuh-SOC-Lab/01-ssh-brute-force/
cat << 'EOF' > README.md
# Project 01: SSH Brute Force Detection & Custom Wazuh Rules

## Overview
This scenario simulates a dictionary-based SSH Brute Force attack launched from a Kali Linux machine against a Linux host monitored by a Wazuh Agent. The goal was to capture raw logs, analyze event correlation, and build a custom detection rule with MITRE ATT&CK mapping.

## Infrastructure & Tools
* **Attacker:** Kali Linux (Hydra)
* **Target / Agent:** Ubuntu Linux (Wazuh Agent 4.x)
* **SIEM / Manager:** Wazuh Server
* **Log Source:** `/var/log/auth.log`

## Scenario Steps
1. **Attack Execution:** Performed an automated authentication flood using Hydra against port 22 (`ssh://`).
2. **Log Collection:** Inspected `/var/log/auth.log` on the target host and extracted raw auth events (`raw_auth.log`).
3. **SIEM Analysis:** Observed default triggers (`Rule ID 2501 / 2502 / 40111`) generated during the high-velocity login attempts.
4. **Rule Engineering:** Created custom rule `100001` in `local_rules.xml` to detect 4+ failed authentication attempts from the same source IP within 120 seconds.

## Artifacts
* `logs/raw_auth.log` — Raw authentication log samples generated during Hydra execution.
* `rules/local_rules.xml` — Custom XML rule mapped to MITRE ATT&CK T1110.001 (Brute Force: Password Guessing).
* `screenshots/` — Dashboard verification proving alert generation.

## Incident Classification
* **Severity:** High (Level 10)
* **Classification:** True Positive
* **Mitration Note:** Recommend implementing IP rate-limiting via Active Response or Fail2ban.
EOF
