# 🛡️ Wazuh SOC & XDR Engineering Lab

A hands-on Security Operations Center (SOC) and Extended Detection and Response (XDR) environment built to simulate real-world cyber attacks, engineer custom detection rules, implement automated threat containment (SOAR), and document Incident Response (IR) playbooks aligned with the MITRE ATT&CK framework.

---

## 📐 Lab Topology & Environment Setup

- **SIEM / XDR Manager:** Wazuh Manager 4.x (Ubuntu Server | `192.168.122.X`)
- **Endpoint / Victim:** Ubuntu Linux Desktop + Wazuh Agent + `auditd` (Ubuntu Laptop | `192.168.122.Y`)
- **Attacker Host:** Kali Linux (`192.168.122.Z`)

---

## 🎯 Project Modules & Attack Scenarios

| ID | Scenario Name | Focus Areas | MITRE ATT&CK | Status |
| :--- | :--- | :--- | :--- | :--- |
| **01** | **SSH Brute Force & Compromise** | Custom XML Rules, Correlation (Level 14), Active Response (IP Drop) | T1110.001 | 🟢 Completed |
| **02** | **Web Attack Detection (SQLi/XSS)** | Web Application Security, Log Analysis, Custom Decoders | T1190 | 🟢 Completed |
| **03** | **File Integrity Monitoring (FIM)** | Syscheck Engine, System File Tampering, Escalation Detection | T1565.001 | 🟢 Completed |
| **04** | **Linux Credential Access & SOAR** | Kernel Auditing (`auditd`), Custom Detection Tuning, Account Lockout & Permanent IP Block | T1003.008 | 🟢 Completed |
| **05** | **Threat Intel & VirusTotal** | FIM Active Trigger, VirusTotal API Integration, Automated Host Isolation | T1204.002 | 🟢 Completed |
| **06** | **Linux Privilege Escalation** | SUID Execution Tracking, Kernel Exploitation Monitoring, Auditd Syscall Correlation | T1548 / T1068 | 🟢 Completed |
| **07** | **Suricata NIDS & Active Response** | Network Intrusion Detection (NIDS), Eve JSON Telemetry Parsing, Automatic Traffic Drop | T1071 / T1595 | 🟢 Completed |
| **08** | **YARA Automated Malware Quarantine** | Real-time Payload Scanning, File Permission Neutralization (`chmod 000`), Automated SOAR Containment | T1204.002 / T1059 | 🟢 Completed |
| **09** | **Docker Container Security Monitoring** | `docker-listener` Integration, Privileged Container Execution, Container Escape Attempts (`docker.sock`) | T1611 / T1609 | 🟡 Planned |

---

## 🛠️ Key Skills & Technologies Demonstrated

- **SIEM/XDR Management:** Custom rule engineering (`local_rules.xml`), log decoders, correlation logic, and false-positive suppression.
- **Endpoint Detection & Response (EDR):** YARA signature scanning, real-time FIM file integrity analysis, and Linux kernel telemetry auditing via `auditd`.
- **Network Intrusion Detection (NIDS):** Suricata engine integration, JSON telemetry ingestion, and network-layer active response.
- **Automated Containment (SOAR):** BASH enforcement scripting (`ossec.conf`) for automated malware isolation, file permission neutralization (`000`), user account locking (`passwd -l`), and firewall bans (`iptables`).
- **Cloud & Container Security:** DevSecOps monitoring using Wazuh `docker-listener` to monitor daemon socket interactions and container breakout attempts.
- **Threat Hunting & Incident Response:** Deep investigation of raw logs (`/var/log/audit/audit.log`, `/var/ossec/logs/active-responses.log`, `alerts.json`) mapped directly to MITRE ATT&CK Tactics & Techniques.

---

## 📁 Repository Structure

```text
Wazuh-SOC-Lab/
├── README.md                                # Main repository overview
├── 01-ssh-brute-force/                      # Scenario 01: SSH Brute Force & Containment
├── 02-web-attack-detection/                 # Scenario 02: Web Attack Detection (SQLi/XSS)
├── 03-active-response-ip-block/             # Scenario 03: File Integrity Monitoring (FIM)
├── 04-Linux-Credential-Access/              # Scenario 04: Kernel Auditing, Credential Access & SOAR
├── 05-virustotal-integration/               # Scenario 05: Malware Analysis & VirusTotal Integration
├── 06-Linux-Privilege-Escalation/           # Scenario 06: Privilege Escalation & Auditd Telemetry
├── 07-Suricata-Network-IDS/                 # Scenario 07: Suricata NIDS Integration & Network AR
├── 08-YARA-Automated-Malware-Quarantine/    # Scenario 08: YARA Scanning & Automated File Isolation
│   ├── configs/                             # Custom rules & ossec.conf snippets
│   ├── docs/screenshots/                    # Dashboard alerts & execution proof
│   ├── scripts/                             # yara-quarantine.sh SOAR script
│   ├── yara-rules/                          # Custom YARA signature files
│   ├── README.md                            # Detailed scenario documentation
│   └── what_do.txt                          # Operational verification guide
└── 09-Docker-Container-Security-Monitoring/ # Scenario 09: Container Security & Escape Detection
