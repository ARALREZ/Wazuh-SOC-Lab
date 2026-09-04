# Scenario 06: Linux Privilege Escalation & Active Response Quarantine

## 📌 Executive Summary

This project demonstrates an end-to-end SOC scenario simulating a Local Privilege Escalation (PrivEsc) attack on a Linux endpoint. It covers custom detection engineering in Wazuh SIEM to detect GTFOBins abuse (sudo find), automated active response (SOAR) via file quarantine (revoking permissions and applying immutable attributes) triggered by File Integrity Monitoring (FIM).

## 📐 Network & Lab Architecture

    SIEM / XDR Manager: Wazuh Manager 4.x (Ubuntu Server)
    Target Endpoint (Victim): Ubuntu Linux + Wazuh Agent (Ubuntu Laptop with low-privileged 'attacker' account)
    Attacker Host: Kali Linux (Payload Delivery)

## 🔍 MITRE ATT&CK Mapping

    Tactic: Privilege Escalation (TA0004)
    Technique: Command and Scripting Interpreter: Unix Shell (T1059.004)
    Technique: Abuse Elevation Control Mechanism: Sudo and Sudo Caching (T1548.003)

## ⚙️ Custom Detection Rules & Active Response

    Custom Rules Configuration (configs/local_rules.xml) Two custom rules were engineered to address visibility gaps in default configurations:

    Rule 100060 (Level 12 - CRITICAL): Detects the execution of GTFOBins privilege escalation via `sudo find -exec`. It specifically extracts and parses the command field from audited sudo logs.
    Rule 100061 (Level 12 - CRITICAL): Correlates with the Wazuh Syscheck (FIM) module to detect the creation of known privilege escalation enumeration scripts (e.g., `linpeas.sh`) in monitored directories.

<group name="linux, privesc, quarantine">

  <!-- Detects the use of sudo find -exec to open a root shell -->
  <rule id="100060" level="12">
    <if_sid>5402,5403</if_sid>
    <field name="command">find.*-exec</field>
    <description>PrivEsc Alert: Using GTFOBins (find -exec) to hijack root!</description>
    <mitre>
      <id>TA0004</id>
      <id>T1548.003</id>
    </mitre>
  </rule>

  <!-- Detects the creation of a malicious linpeas.sh script by the FIM module -->
  <rule id="100061" level="12">
    <if_group>syscheck</if_group>
    <match>linpeas.sh|exploit.sh</match>
    <description>Active Response Trigger: Automatic privilege escalation script detected.</description>
    <mitre>
      <id>TA0004</id>
      <id>T1059.004</id>
    </mitre>
  </rule>

</group>

    Active Response Configuration (configs/ossec.conf) Automatically triggers a custom SOAR script (`quarantine_file.sh`) upon detecting rule 100061. The script immediately executes `chmod 000` and `chattr +i` on the malicious file:

<command>
  <name>quarantine_file</name>
  <executable>quarantine_file.sh</executable>
  <timeout_allowed>no</timeout_allowed>
</command>

<active-response>
  <command>quarantine_file</command>
  <location>local</location>
  <rules_id>100061</rules_id>
</active-response>

## 📁 Repository Structure
```text
06-Linux-Privilege-Escalation/
├── artifacts/
│   └── active-responses.log     # Log proof of script quarantine action
├── configs/
│   ├── local_rules.xml          # Custom detection rules for PrivEsc & FIM
│   └── ossec.conf               # Active Response & SOAR binding configuration
├── docs/
│   └── screenshots/
│       └── privesc_dashboard_alerts.png # Dashboard evidence of GTFOBins execution & FIM trigger
├── scripts/
│   ├── privesc_sim.sh           # Attack simulation script (Payload drop & Sudo abuse)
│   └── quarantine_file.sh       # SOAR containment script (chmod 000 & chattr +i)
├── README.md                    # Scenario documentation & playbook
└── what_need                    # Deployment commands cheat-sheet

