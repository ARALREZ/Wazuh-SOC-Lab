# Project 02: Web Reconnaissance & Directory Brute-Force Detection

## Executive Summary
This project demonstrates detection capabilities for web-based reconnaissance and directory brute-force attacks using Wazuh SIEM. The scenario covers log parsing, identification of scanner User-Agents, and frequency-based correlation rules to detect high-volume 404 HTTP responses.

---

## Architecture & Flow
`[Kali Linux (Gobuster/Nikto)]` ---> `[Target Server (Apache2 + Wazuh Agent)]` ---> `[Wazuh Manager (SIEM Rules 100020, 100021)]`

---

## Technical Steps
1. **Log Collection**: Configured Wazuh Agent to ingest Apache access logs (`/var/log/apache2/access.log`).
2. **Attack Simulation**: Executed `gobuster dir` and `nikto` scans from Kali Linux against the target web application.
3. **Analysis & Rule Development**:
   - Analyzed raw HTTP 404 log patterns.
   - Built custom detection rules utilizing signature-based matching (User-Agent strings) and threshold-based correlation (15+ HTTP 404 responses in 10 seconds from a single IP).

---

## Custom Rules (`rules/local_rules.xml`)
- **Rule ID 100020 (Level 7)**: Detects automated reconnaissance tools via User-Agent inspection (`T1595.002`).
- **Rule ID 100021 (Level 10)**: Detects Directory Brute-Force attempts based on HTTP 404 threshold exceeding (`T1110`).

---

## Incident Classification Matrix
| Metric | Value |
| :--- | :--- |
| **Severity** | Medium / High |
| **Attacker IP** | `192.168.1.x` (Kali Linux) |
| **Target** | Port 80/HTTP Apache2 |
| **MITRE ATT&CK** | T1595.002 (Active Scanning), T1110 (Brute Force) |
| **Recommended Action** | Block IP at Web Application Firewall (WAF) or local `iptables`. |
