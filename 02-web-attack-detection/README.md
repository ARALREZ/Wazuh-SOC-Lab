# Scenario 02: Web Attack Detection, Reconnaissance & Automated Response (XDR)

## 📌 Executive Summary
This project demonstrates an end-to-end SOC scenario simulating web application attacks against an Apache2 web server (Web Reconnaissance, SQL Injection, and Cross-Site Scripting). It covers custom detection engineering in Wazuh SIEM using pattern and group matching, real-time HTTP log decoding, and automated active response (IP containment via firewall-drop) aligned with the MITRE ATT&CK framework.

## 📐 Network & Lab Architecture
- SIEM / XDR Manager: Wazuh Manager 4.x (Ubuntu Server - moj-server)
- Target Endpoint (Victim / Web Server): Apache2 Web Server + Wazuh Agent (Ubuntu Laptop - My_Agent)
- Attacker Host: Kali Linux (192.168.122.121)

## 🔍 MITRE ATT&CK Mapping
- Tactic: Reconnaissance (TA0043), Initial Access (TA0001)
- Technique: Active Scanning: Vulnerability Scanning (T1595.002)
- Technique: Exploit Public-Facing Application (T1190)

## ⚙️ Custom Detection Rules & Active Response

1. Custom Rules Configuration (configs/local_rules.xml)
Three custom rules were engineered to analyze Apache access logs (`/var/log/apache2/access.log`) and detect web threat vectors:
- Rule 100020 (Level 8): Detects automated web vulnerability scanners (Nikto, SQLmap, Nmap, Acunetix) by analyzing user-agent strings across web log groups.
- Rule 100021 (Level 11): Identifies SQL Injection (SQLi) payload signatures (`UNION SELECT`, `SELECT FROM`, `OR 1=1`) in query parameters.
- Rule 100022 (Level 10): Identifies Cross-Site Scripting (XSS) payload signatures (`<script>`, `%3Cscript%3E`, `javascript:`, `onerror=`).

```xml
<group name="web,appsec,custom_web_detection,">

  <!-- Custom Rule 100020: Web Reconnaissance / Vulnerability Scanner -->
  <rule id="100020" level="8">
    <if_group>web</if_group>
    <regex>Nikto|sqlmap|nmap|acunetix</regex>
    <description>CUSTOM DETECT: Automated Web Vulnerability Scanner Detected ($(http_user_agent))</description>
    <mitre>
      <id>T1595.002</id>
    </mitre>
  </rule>

  <!-- Custom Rule 100021: SQL Injection Attempt -->
  <rule id="100021" level="11">
    <if_sid>31100</if_sid>
    <regex>UNION.*SELECT|SELECT.*FROM|OR%201=1|' OR '1'='1|UNION%20SELECT</regex>
    <description>CUSTOM DETECT: SQL Injection Attack Attempted from $(srcip)</description>
    <mitre>
      <id>T1190</id>
    </mitre>
  </rule>

  <!-- Custom Rule 100022: Cross-Site Scripting (XSS) Attempt -->
  <rule id="100022" level="10">
    <if_sid>31100</if_sid>
    <regex>%3Cscript%3E|&lt;script&gt;|javascript:|onerror=</regex>
    <description>CUSTOM DETECT: Cross-Site Scripting (XSS) Injection Attempted from $(srcip)</description>
    <mitre>
      <id>T1190</id>
    </mitre>
  </rule>

</group>
```

2. Active Response Configuration (configs/ossec.conf)
Binds detection rules directly to automated IP blocking:
```xml
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>100021, 100022</rules_id>
  <timeout>300</timeout>
</active-response>
```
## 📁 Repository Structure
```text
02-web-attack-detection/
├── artifacts/
│   └── apache_alerts.json       # Log samples of intercepted web attacks
├── configs/
│   ├── local_rules.xml          # Custom web security XML rules
│   └── ossec.conf               # Web log collection & Active Response config
├── docs/
│   └── screenshots/             # Screenshots of Nikto/SQLi/XSS alerts
└── README.md                    # Scenario documentation
```
