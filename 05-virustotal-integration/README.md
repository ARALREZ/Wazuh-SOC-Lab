# Scenario 05: Malware Threat Intel Integration & Automated Host Isolation (SOAR)

## 📌 Executive Summary

This project demonstrates an end-to-end SOC scenario simulating an automated malware detection and containment pipeline. It covers real-time File Integrity Monitoring (FIM) on Linux endpoints, threat intelligence enrichment via VirusTotal API integration in Wazuh SIEM, custom high-severity detection engineering tuned for malicious payload identification, and automated active response (file removal & host network isolation via iptables) aligned with the MITRE ATT&CK framework.

## 📐 Network & Lab Architecture

    SIEM / XDR Manager: Wazuh Manager 4.x (Ubuntu Server)

    Target Endpoint (Victim): Ubuntu Linux Desktop + Wazuh Agent (Ubuntu Laptop)

    Attacker Host: Kali Linux / Local Attacker Session

## 🔍 MITRE ATT&CK Mapping

    Tactic: Execution (TA0002)

    Technique: User Execution: Malicious File (T1204.002)

## ⚙️ Custom Detection Rules & Active Response

1. Agent FIM Configuration (/var/ossec/etc/ossec.conf)
To monitor file creation events in real time within the target user's download directory:

```xml
<syscheck>
  <directories realtime="yes" check_all="yes">/home/USER/Downloads</directories>
</syscheck>
```

2. VirusTotal Integration Configuration (/var/ossec/etc/ossec.conf)
Integrates Wazuh Manager with VirusTotal API to query hashes of newly created files:

```xml
<integration>
  <name>virustotal</name>
  <api_key>YOUR_VIRUSTOTAL_API_KEY</api_key>
  <group>syscheck</group>
  <rule_id>550, 554</rule_id>
  <alert_format>json</alert_format>
</integration>
```

3. Custom Detection Rule Configuration (configs/local_rules.xml)
Custom rule engineered to trigger a high-severity alert when VirusTotal confirms a malicious file hash:

```xml
<group name="virustotal,custom_malware,">

  <!-- Custom Rule for VirusTotal Positive Detection & SOAR Trigger -->
  <rule id="100050" level="13">
    <if_sid>87105</if_sid>
    <description>CUSTOM DETECT: VirusTotal flagged malicious payload ($(virustotal.source.file)) - Triggering Automated Host Isolation!</description>
    <mitre>
      <id>T1204.002</id>
    </mitre>
  </rule>

</group>
```

4. Active Response Configuration (configs/ossec.conf)
Binds detection Rule 100050 directly to an automated SOAR containment script:

```xml
<!-- Active Response Command Definition -->
<command>
  <name>host-isolate</name>
  <executable>host-isolate.sh</executable>
  <timeout_allowed>no</timeout_allowed>
</command>

<!-- Active Response Execution Rule -->
<active-response>
  <command>host-isolate</command>
  <location>local</location>
  <rules_id>100050</rules_id>
</active-response>
```

## 📁 Repository Structure

```text
05-virustotal-integration/
├── artifacts/
│   └── virustotal_alerts.json   # Sample JSON alert proof from VirusTotal
├── configs/
│   ├── local_rules.xml          # Custom detection rule 100050
│   └── ossec.conf               # VirusTotal integration & Active Response config
├── docs/
│   └── screenshots/             # Dashboard evidence & detection logs
├── scripts/
│   └── host-isolate.sh          # SOAR enforcement script (purge + isolation)
├── README.md                    # Scenario documentation
└── what_to_use                  # Deployment commands cheat-sheet
```
