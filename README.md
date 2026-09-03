# 🛡️ Wazuh SOC & XDR Engineering Lab

A hands-on Security Operations Center (SOC) and Extended Detection and Response (XDR) environment built to simulate real-world cyber attacks, engineer custom detection rules, implement automated threat containment (SOAR), and document Incident Response (IR) playbooks aligned with the MITRE ATT&CK framework.

---

## 📐 Lab Topology & Environment Setup

- **SIEM / XDR Manager:** Wazuh Manager 4.x (Ubuntu Server | `192.168.122.X`)
- **Endpoint / Victim:** Ubuntu Linux Desktop + Wazuh Agent + `auditd` (Ubuntu Laptop | `192.168.122.Y`)
- **Attacker Host:** Kali Linux (`192.168.122.Z`)

---

## 🎯 Project Modules & Attack Scenarios

| ID | Scenario Name | Focus Areas | Status |
| :--- | :--- | :--- | :--- |
| **01** | **SSH Brute Force & Compromise** | Custom XML Rules, Correlation (Level 14), Active Response (IP Drop), MITRE T1110.001 | 🟢 Completed |
| **02** | **Web Attack Detection (SQLi/XSS)** | Web Application Security, Log Analysis, Custom Decoders, MITRE T1190 | 🟢 Completed |
| **03** | **File Integrity Monitoring (FIM)** | Syscheck Engine, System File Tampering, Escalation Detection, MITRE T1565.001 | 🟢 Completed |
| **04** | **Linux Credential Access & SOAR Response** | Kernel Auditing (`auditd`), Custom Detection (Tuning & FP Reduction), Account Lockout & Permanent IP Block, MITRE T1003.008 | 🟢 Completed |
| **05** | **Threat Intel & VirusTotal Integration** | FIM Active Trigger, VirusTotal API, Automated File Quarantine & Removal, MITRE T1204 | 🟢 Completed |

---

## 🛠️ Key Skills & Technologies Demonstrated

- **SIEM/XDR Management:** Custom rule engineering (`local_rules.xml`), correlation logic, level escalation, and false-positive reduction.
- **Kernel-Level Telemetry:** Auditing Linux system calls using `auditd` to monitor privileged file access (`/etc/shadow`).
- **Automated Response (SOAR):** BASH scripting for Wazuh Active Response (`ossec.conf`) implementing account lockouts (`passwd -l`) and persistent firewall bans via `iptables` / `netfilter-persistent`.
- **Threat Hunting & Log Analysis:** Deep analysis of `/var/log/audit/audit.log`, `/var/log/auth.log`, and raw JSON telemetry (`alerts.json`).
- **Framework Alignment:** Direct mapping of all detection logic and active response playbooks to MITRE ATT&CK Tactics & Techniques.

---

## 📁 Repository Structure

```text
Wazuh-SOC-Lab/
├── README.md                           # Main repository overview (This file)
├── 01-ssh-brute-force/                 # Scenario 01: SSH Brute Force & Containment
├── 02-web-attack-detection/            # Scenario 02: Web Attack Detection (SQLi/XSS)
├── 03-file-integrity-monitoring/       # Scenario 03: File Integrity Monitoring (FIM)
├── 04-Linux-Credential-Access/         # Scenario 04: Kernel Auditing, Credential Access & Active Response
│   ├── artifacts/                      # Execution logs & verification proof
│   ├── configs/                        # local_rules.xml & ossec.conf snippets
│   ├── docs/screenshots/               # Dashboard alerts & verification evidence
│   ├── scripts/                        # SOAR enforcement script (block-attacker.sh)
│   ├── README.md                       # Detailed scenario guide & playbook
│   └── what_need                       # Deployment cheat-sheet
└── 05-virustotal-integration/          # Scenario 05: Malware Analysis & VirusTotal Integration (Upcoming)
