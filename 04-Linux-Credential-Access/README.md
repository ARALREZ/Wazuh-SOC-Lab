# Scenario 04: Linux Credential Access Detection, Kernel Auditing & Automated Response (XDR)

## 📌 Executive Summary
This project demonstrates an end-to-end SOC scenario simulating an unauthorized Linux Credential Access attack (`/etc/shadow` access attempt). It covers kernel-level telemetry using `auditd`, custom detection engineering in Wazuh SIEM tuned for false-positive reduction, and automated active response (user account lockout & permanent IP containment via `iptables`) aligned with the MITRE ATT&CK framework.

## 📐 Network & Lab Architecture
- SIEM / XDR Manager: Wazuh Manager 4.x (Ubuntu Server)
- Target Endpoint (Victim): Ubuntu Linux Desktop + Wazuh Agent + `auditd` (Ubuntu Laptop)
- Attacker Host: Kali Linux

## 🔍 MITRE ATT&CK Mapping
- Tactic: Credential Access (TA0006)
- Technique: OS Credential Dumping: /etc/passwd and /etc/shadow (T1003.008)

## ⚙️ Custom Detection Rules & Active Response

1. Kernel Audit Configuration (/etc/audit/rules.d/audit.rules)
To capture privilege escalation and credential access attempts at the system call level while filtering authorization noise (e.g., sudo, su):

```bash
-a always,exit -F path=/etc/shadow -F perm=rwa -F auid>=1000 -F auid!=4294967295 -F exe!=/usr/bin/sudo -F exe!=/usr/bin/su -F exe!=/usr/bin/passwd -k shadow_access
```

2. Custom Detection Rule Configuration (configs/local_rules.xml)
Custom rule engineered to detect unauthorized failed access attempts to system credential files:

```xml
<group name="local,syslog,sshd,">

  <!-- Custom Auditd Rule for Credential Access -->
  <rule id="100040" level="10">
    <if_sid>80700</if_sid>
    <field name="audit.key">shadow_access</field>
    <field name="audit.res">failed</field>
    <description>Auditd: Unauthorized failed attempt to access /etc/shadow by user $(audit.auid)</description>
    <mitre>
      <id>T1003.008</id>
    </mitre>
  </rule>

</group>
```

3. Active Response Configuration (configs/ossec.conf)
Binds detection Rule 100040 directly to an automated SOAR remediation script:

```xml
<!-- Active Response Command Definition -->
<command>
  <name>block-attacker-script</name>
  <executable>block-attacker.sh</executable>
  <timeout_allowed>no</timeout_allowed>
</command>

<!-- Active Response Execution Rule -->
<active-response>
  <command>block-attacker-script</command>
  <location>local</location>
  <rules_id>100040</rules_id>
</active-response>
```

## 📁 Repository Structure

```text
04-Linux-Credential-Access/
├── artifacts/
│   └── active_response.log      # Log proof of automated enforcement
├── configs/
│   ├── local_rules.xml          # Wazuh detection rule 100040
│   └── ossec.conf               # Active response & log ingestion config
├── docs/
│   └── screenshots/
│       └── user_without_permission.png # Dashboard alert evidence
├── scripts/
│   └── block-attacker.sh        # SOAR enforcement script
├── README.md                    # Scenario documentation
└── what_need                    # Deployment commands cheat-sheet
```
