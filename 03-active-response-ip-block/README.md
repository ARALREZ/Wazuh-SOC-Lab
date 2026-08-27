# Project 03: Automated IP Containment via Wazuh Active Response

## 📌 Executive Summary
This project implements an automated incident response (**SOAR / Active Response**) workflow within a Wazuh SIEM/EDR environment. By leveraging Wazuh's `active-response` engine, the system automatically detects high-severity brute-force attacks (SSH & Web directory enumeration) originated from Kali Linux and mitigates the threat in real-time by dynamically blocking the attacker's IP address on the target host's firewall (`iptables`).

---

## 🏗 Architecture & Feedback Loop

The automated response operates in a closed-loop security architecture:

```text
[ Attacker (Kali Linux) ] 
        │ 
        │ (1) SSH / Web Brute-Force Attack
        ▼ 
[ Target Host (Wazuh Agent) ] ────(2) Syslog / Auth Logs────► [ Wazuh Manager ]
        ▲                                                          │
        │                                                          │ (3) Rule Match (Level 10+)
        │                                                          │     (Rules: 100001, 100021, 40111)
        │                                                          ▼
        └──────────────(4) Encrypted AR Command: ──────────────────┘
                            firewall-drop (Add IP to iptables)
