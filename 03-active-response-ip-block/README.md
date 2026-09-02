# Scenario 03: Automated Account Lockout & Active Response (XDR)

## 📌 Executive Summary
This project demonstrates an automated XDR containment scenario designed to detect and block unauthorized privilege escalation attempts (`sudo`) on Linux endpoints. Using Wazuh SIEM/XDR, custom correlation rules match authentication failures, extract event metadata (`srcuser`), and invoke an active response Bash script to cryptographically lock the compromised user account at the PAM layer (`/etc/shadow`) in real time.

## 📐 Network & Lab Architecture
- SIEM / XDR Manager: Wazuh Manager 4.x (moj-server - Ubuntu Server)
- Target Endpoint (Victim): Wazuh Agent (My_Agent / aralrez-Victus-HP - Ubuntu Laptop)
- Attacker Account: Local unprivileged account (`attacker`)

## 🔍 MITRE ATT&CK Mapping
- Tactic: Privilege Escalation (TA0004), Defense Evasion (TA0005)
- Technique: Sudo and Sudo Caching (T1548.003)

## ⚙️ Custom Detection Rules & Active Response

1. Custom Rules Configuration (configs/local_rules.xml)
Analyzes local PAM/sudo authentication logs (`/var/log/auth.log`) to catch unauthorized `sudo` executions (wrong password or user not in sudoers):

```xml
<group name="syslog,sudo,custom_response,">

  <!-- Custom Rule 100030: Unauthorized Sudo Attempt -->
  <rule id="100030" level="12">
    <if_sid>5404, 5405, 5407</if_sid>
    <description>CUSTOM DETECT: Unauthorized sudo attempt (Wrong Password or Not in Sudoers) - Triggering Account Lockout</description>
    <mitre>
      <id>T1548.003</id>
    </mitre>
  </rule>

</group>
```

2. Active Response Configuration (configs/ossec.conf)
Binds Rule 100030 to a local account locking script:

```xml
<command>
  <name>account-lockout</name>
  <executable>account-lockout.sh</executable>
  <timeout_allowed>no</timeout_allowed>
</command>

<active-response>
  <command>account-lockout</command>
  <location>local</location>
  <rules_id>100030</rules_id>
</active-response>
```

## 📁 Repository Structure 
```text
03-automated-account-lockout/
├── artifacts/
│   └── active_responses.log     # Proof of executed account lockout
├── configs/
│   ├── local_rules.xml          # Detection rule 100030
│   └── ossec.conf               # Active Response binding config
├── docs/
│   └── screenshots/             # Dashboard evidence & account status proof
├── scripts/
│   └── account-lockout.sh       # Script invoking passwd -l $(dstuser)
└── README.md                    # Scenario documentation
```
