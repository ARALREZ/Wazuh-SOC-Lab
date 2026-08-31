# 🛡️ Wazuh SOC & XDR Engineering Lab

A hands-on Security Operations Center (SOC) and Extended Detection and Response (XDR) environment built to simulate real-world cyber attacks, engineer custom detection rules, implement automated threat containment, and document Incident Response (IR) playbooks aligned with the **MITRE ATT&CK** framework.

---

## 📐 Lab Topology & Environment Setup

* **SIEM / XDR Manager:** Wazuh Manager 4.x (`Ubuntu Server` | `192.168.122.Server`)
* **Endpoint / Victim:** Ubuntu Linux Desktop + Wazuh Agent (`Ubuntu Laptop` | `192.168.122.X`)
* **Attacker Host:** Kali Linux (`192.168.122.Y`)

---

## 🎯 Project Modules & Attack Scenarios

| ID | Scenario Name | Focus Areas | Status |
| :--- | :--- | :--- | :---: |
| **01** | [SSH Brute Force & Compromise](./01-ssh-brute-force) | Custom XML Rules, Correlation (Level 14), Active Response (IP Drop), MITRE T1110.001 | 🟢 Completed |
| **02** | [Web Attack Detection (SQLi/XSS)](./02-web-attack-detection) | Web Application Security, Log Analysis, Custom Decoders | 🟢 Completed |
| **03** | [File Integrity Monitoring (FIM)](./03-fim-integrity-monitoring) | Syscheck Engine, System File Tampering, Escalation Detection | 🟡 Planned |

---

## 🛠️ Key Skills & Technologies Demonstrated

* **SIEM/XDR Management:** Custom rule engineering (`local_rules.xml`), correlation logic, level escalation.
* **Automated Containment:** Configuring Wazuh Active Response (`ossec.conf`) for automated IP blocking via `iptables`.
* **Threat Hunting & Analysis:** Analyzing Linux authentication logs (`/var/log/auth.log`) and Wazuh alert streams (`alerts.json`).
* **Framework Alignment:** Mapping detection coverage directly to MITRE ATT&CK Tactics & Techniques.
* **Documentation & IR:** Structuring incident response procedures and documenting evidence for SOC operations.

---

## 📁 Repository Structure

```text
Wazuh-SOC-Lab/
├── README.md                           # Main repository overview
└── 01-ssh-brute-force/                 # Scenario 01: SSH Brute Force & Containment
    ├── README.md                       # Detailed scenario guide & IR playbook
    ├── configs/                        # Exported XML detection & AR configs
    ├── scripts/                        # Controlled attack simulation scripts
    ├── artifacts/                      # Raw log samples & alert outputs
    └── docs/screenshots/               # Verification evidence & UI alerts
