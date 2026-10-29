# Scenario 02: Web Attack Detection, Reconnaissance & Automated Response

## 📌 Executive Summary

This project demonstrates an end-to-end SOC scenario for detecting web application attacks (reconnaissance, SQL Injection, XSS, Path Traversal and Command Injection) using Wazuh SIEM/XDR. It includes layered custom detection rules, correlation of multiple attack techniques from the same source, automated containment via Active Response (firewall-drop), and a trusted-IP whitelist.

The lab covers detection engineering, positive/negative test cases, regression checks, and real attack simulation from Kali Linux against an Ubuntu endpoint running Apache2 and protected by a Wazuh Agent.

## 📐 Network & Lab Architecture

```text
Attacker:          Kali Linux          192.168.122.112
Victim / Agent:    Ubunru-Agent        192.168.122.149
Trusted Host:      Fedora (virbr0)     192.168.122.1
SIEM / XDR:        Wazuh Manager       192.168.122.178 (my-server)
```

**Expected event flow:**

```text
Kali (curl / nikto / sqlmap)
      |
      | HTTP malicious requests
      v
Ubuntu Agent (Apache2 + Wazuh Agent)
      |
      | /var/log/apache2/access.log → Agent
      v
Wazuh Manager
      |
      +--> Rule 100020 (soft scanner)
      +--> Rule 100021-100024 (specific attacks)
      +--> Rule 100025 / 100026 (correlation)
      +--> Rule 100027 (layered - attack after scanner)
      +--> Rule 100028 (trusted IP - low level)
      +--> Active Response (firewall-drop)
      |
      v
Wazuh Dashboard / alerts.json
```

## 🔍 MITRE ATT&CK Mapping

```text
Tactic:     Reconnaissance (TA0043), Initial Access (TA0001)
Technique:  Active Scanning: Vulnerability Scanning (T1595.002)
Technique:  Exploit Public-Facing Application (T1190)
```

## ⚙️  Custom Detection Rules & Validation

```text 
Custom Rule Configuration:
/var/ossec/etc/rules/local_rules.xml
(also stored in wazuh/rules/web_attack_rules.xml)

Rule 100020 (Level 6):
  Soft - Automated web vulnerability scanner (Nikto, sqlmap, etc.)

Rule 100021 (Level 10):
  SQL Injection attempt

Rule 100022 (Level 10):
  Cross-Site Scripting (XSS) attempt

Rule 100023 (Level 10):
  Path Traversal / Local File Inclusion

Rule 100024 (Level 11):
  Command Injection / RCE pattern

Rule 100025 (Level 8):
  Multiple scanner detections from same IP (correlation)

Rule 100026 (Level 12):
  Multiple web attack techniques from same IP (correlation)

Rule 100027 (Level 13 - CRITICAL):
  Web attack after previous scanner activity (layered)

Rule 100028 (Level 3):
  Web activity from trusted IP (192.168.122.1)

Rule 100029 (Level 5):
  Suspicious web request patterns (php://, eval, data://)
```

## 🧪 Detection Test Results

| Test Case | Input / Condition | Expected Result | Status |
| --- | --- | --- | --- |
| Soft scanner | Nikto / sqlmap User-Agent | Rule 100020 (level 6) | PASS |
| SQL Injection | ' OR '1'='1 / UNION SELECT | Rule 100021 (level 10) | PASS |
| XSS | alert(1) | Rule 100022 (level 10) | PASS |
| Path Traversal | ../../../../etc/passwd | Rule 100023 (level 10) | PASS |
| Command Injection | ;id / |whoami | Rule 100024 (level 11) | PASS |
| Multiple scanners | 4x scanner in short time | Rule 100025 (level 8) | PASS |
| Multiple attack types | SQLi + XSS + Path Traversal | Rule 100026 (level 12) | PASS |
| Attack after scanner | Nikto -> then SQLi/XSS | Rule 100027 (level 13) | PASS |
| Trusted IP | Request from 192.168.122.1 | Rule 100028 (level 3) | PASS |
| Suspicious patterns | php:// / eval / data:// | Rule 100029 (level 5) | PASS |
| Active Response | After high-severity rules | IP blocked in iptables | PASS |
| Negative - normal traffic | Normal browser requests | No high-severity alerts | PASS |

Tests were performed with real curl/nikto attacks against a live Apache2 instance. Rules were validated on Wazuh Manager 4.x.

## 📁 Repository Structure
```text
02-web-attack-detection/
├── architecture/
│   └── architecture.md
├── wazuh/
│   ├── rules/
│   │   └── web_attack_rules.xml
│   └── configs/
│       └── active-response.xml
├── tests/
│   ├── positive/
│   │   ├── sql_injection.log
│   │   └── xss_and_path.log
│   ├── negative/
│   │   ├── normal-traffic.log
│   │   └── trusted_and_normal.log
│   └── regression/
│       └── test_web_rules.py
├── scripts/
│   ├── attack_simulation.sh
│   └── cleanup_web.sh
├── sample-logs/
│   └── web_sample.log
├── evidence/
├── reports/
│   └── test-results.md
└── README.md
```

## ⚠️  Limitations

- Active Response uses location local (blocks only on the Agent).
- Correlation rules (100026 / 100027) are sensitive to timing and require Active Response to be temporarily disabled during testing.
- Whitelist (100028) is based on a single static IP (192.168.122.1).
- Detection relies on regex patterns in Apache access logs – advanced obfuscation can bypass some rules.
- Tests were performed in a lab libvirt network; production tuning of frequency/timeframe may be required.

## 🚀 Next Steps

1. Add more trusted IPs or CIDR ranges to the whitelist.
2. Consider server-side Active Response for centralized blocking.
3. Extend detection to cover additional vectors (RFI, SSTI, log4shell-style patterns).
4. Integrate with SOAR playbooks for automatic ticket creation.
5. Keep evidence screenshots and test-results.md up to date after any rule changes.
