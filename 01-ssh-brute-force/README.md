# Scenario 01: SSH Brute Force Detection, Account Compromise & Automated Response

## 📌 Executive Summary

This project demonstrates an end-to-end SOC scenario for detecting SSH brute-force attacks and subsequent successful authentication using Wazuh SIEM/XDR. It includes layered custom detection rules, correlation of failed and successful logins, automated containment via Active Response (firewall-drop), and a trusted-IP whitelist.

The lab covers detection engineering, positive/negative test cases, regression checks, and real attack simulation from Kali Linux against an Ubuntu endpoint protected by a Wazuh Agent.

## 📐 Network & Lab Architecture

```text
Attacker:          Kali Linux          192.168.122.112
Victim / Agent:    Ubunru-Agent        192.168.122.149
Trusted Host:      Fedora (virbr0)     192.168.122.1
SIEM / XDR:        Wazuh Manager       192.168.122.178 (my-server)
```

**Expected event flow:**

```text
Kali (Hydra)
      |
      | SSH failed / successful logins
      v
Ubuntu Agent (Wazuh Agent)
      |
      | events via 1514/tcp
      v
Wazuh Manager
      |
      +--> Rule 100001 (soft)
      +--> Rule 100002 (brute force) --> Active Response (firewall-drop)
      +--> Rule 100005 (critical success after brute)
      +--> Rule 100010 (trusted IP - low level only)
      |
      v
Wazuh Dashboard / alerts.json
```

## 🔍 MITRE ATT&CK Mapping

```text 
Tactic:     Credential Access (TA0006), Initial Access (TA0001)
Technique:  Brute Force: Password Guessing (T1110.001)
Technique:  Valid Accounts (T1078)
```

## ⚙️ Custom Detection Rules & Validation

```text
Custom Rule Configuration:
/var/ossec/etc/rules/local_rules.xml
(also stored in wazuh/rules/ssh_brute_force_rules.xml)

Rule 100010 (Level 3):
  Trusted IP authentication failure (192.168.122.1)

Rule 100001 (Level 6):
  3 failed SSH attempts within 90 seconds (excluding trusted IP)

Rule 100002 (Level 10):
  5 failed SSH attempts within 120 seconds → triggers Active Response

Rule 100005 (Level 14 - CRITICAL):
  Successful SSH login (5715) after recent brute-force activity (100001)
```

## 🧪 Detection Test Results
| Test Case | Input / Condition | Expected Result | Status |
|---|---|---|---|
| Soft detection | 3 failed logins from Kali | Rule 100001 (level 6) | PASS |
| Brute force detection | 5+ failed logins from Kali | Rule 100002 (level 10) + ARP | PASS |
| Critical correlation | Successful login after brute force | Rule 100005 (level 14) | PASS |
| Active Response | After rule 100002 | IP blocked in iptables | PASS |
| Trusted IP | Failed logins from 192.168.122.1 | Rule 100010 (level 3) only | PASS |
| Negative - single failure | 1-2 failed logins | No 100001/100002 | PASS |
| Negative - clean success | Normal successful login | Only 5715, no 100005 | PASS |

Tests were performed with real Hydra attacks and live SSH sessions. Rules were validated on Wazuh Manager 4.9.2.

## 📁 Repository Structure

```text
01-ssh-brute-force/
├── architecture/
│   └── architecture.md
├── wazuh/
│   ├── rules/
│   │   └── ssh_brute_force_rules.xml
│   └── configs/
│       └── active-response.xml
├── tests/
│   ├── positive/
│   │   ├── brute-force-4fails.log
│   │   └── brute-force-success-after.log
│   ├── negative/
│   │   ├── normal-failed-login.log
│   │   └── normal-successful-login.log
│   └── regression/
│       └── test_ssh_rules.py
├── scripts/
│   ├── attack_simulation.sh
│   └── cleanup_firewall.sh
├── sample-logs/
├── evidence/
├── reports/
│   └── test-results.md
└── README.md
```

## ⚠️ Limitations

- Active Response uses location local (blocks on the Agent only).
- Correlation window for rule 100005 is time-sensitive; very long delays between brute force and success may miss the critical alert.
- Whitelist (100010) is based on a single static IP (192.168.122.1).
- Tests were performed in a lab libvirt network; production tuning of frequency/timeframe may be required.
- No automatic unblocking notification beyond the standard Active Response delete event.

## 🚀 Next Steps

1. Add more trusted IPs to the whitelist if needed.
2. Consider adding a server-side Active Response for centralized blocking.
3. Extend detection to cover key-based authentication failures.
4. Integrate with SOAR playbooks for automatic ticket creation.
5. Keep evidence screenshots and test-results.md up to date after any rule changes.
