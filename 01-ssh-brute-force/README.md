# Scenario 01: SSH Brute Force Detection, Account Compromise & Automated Response (XDR)

## 📌 Executive Summary
This project demonstrates an end-to-end SOC scenario simulating an SSH Brute Force attack followed by account compromise. It covers custom detection engineering in Wazuh SIEM, automated active response (IP containment), and correlation of credential stuffing events aligned with the MITRE ATT&CK framework.

## 📐 Network & Lab Architecture
- SIEM / XDR Manager: Wazuh Manager 4.x (Ubuntu Server)
- Target Endpoint (Victim): Ubuntu Linux Desktop + Wazuh Agent (Ubuntu Laptop)
- Attacker Host: Kali Linux

## 🔍 MITRE ATT&CK Mapping
- Tactic: Credential Access (TA0006), Initial Access (TA0001)
- Technique: Brute Force: Password Guessing (T1110.001)
- Technique: Valid Accounts (T1078)

## ⚙️ Custom Detection Rules & Active Response

1. Custom Rules Configuration (configs/local_rules.xml)
Two custom rules were engineered to address visibility gaps in default configurations:
- Rule 100001 (Level 10): Detects custom SSH Brute Force attempts (4+ failed logins within 120s from the same IP).
- Rule 100010 (Level 14 - CRITICAL): Correlates successful SSH login events (5715) occurring directly after brute force or multiple failed login attempts from the same source IP.

```xml
<group name="syslog,sshd,custom_detection,">

  <!-- Custom Rule 100001: SSH Brute Force Detection -->
  <rule id="100001" level="10">
    <if_matched_sid>5760</if_matched_sid>
    <same_source_ip />
    <frequency>4</frequency>
    <timeframe>120</timeframe>
    <description>CUSTOM DETECT: SSH Brute Force attack detected from $(srcip)</description>
    <mitre>
      <id>T1110.001</id>
    </mitre>
  </rule>

  <!-- Custom Rule 100010: Successful Login Following Brute Force -->
  <rule id="100010" level="14">
    <if_sid>5715</if_sid>
    <if_matched_sid>100001, 5760, 5763</if_matched_sid>
    <same_source_ip />
    <description>CRITICAL: Successful SSH Authentication Following Brute Force Attack from $(srcip)!</description>
    <mitre>
      <id>T1110.001</id>
      <id>T1078</id>
    </mitre>
  </rule>

</group>
```
2. Active Response Configuration (configs/ossec.conf)
Automatically triggers firewall containment upon detecting rule 100001 or 100010:
```xml
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>100001, 100010</rules_id>
  <timeout>600</timeout>
</active-response>
```

## 📁 Repository Structure

📁 **Repository Structure**

```text
01-ssh-brute-force/
├── artifacts/
│   └── active_responses.log     # Log proof of SSH brute-force detection & IP drop
├── configs/
│   ├── local_rules.xml          # Custom detection rules for SSH authentication failures
│   └── ossec.conf               # Active Response & SSH monitoring configuration
├── docs/
│   └── screenshots/
│       └── ssh_brute_force_alert.png # Dashboard evidence & blocked IP alert
├── scripts/
│   └── firewall-drop.sh         # SOAR containment script (iptables IP block)
├── README.md                    # Scenario documentation & playbook
└── what_need                    # Deployment commands cheat-sheet
