# Scenario 03: File Integrity Monitoring – System File Tampering & Automated Quarantine

## 📌 Executive Summary

This project demonstrates an end-to-end SOC scenario for detecting unauthorized modifications of critical system files using Wazuh SIEM/XDR File Integrity Monitoring (FIM). It includes layered custom detection rules, correlation of soft and critical changes, and automated containment via Active Response that quarantines the modified file (permission lock + immutable attribute + move to quarantine directory).

The lab covers detection engineering, positive/negative test cases, regression checks, and real file-tampering simulation against an Ubuntu endpoint protected by a Wazuh Agent.

## 📐 Network & Lab Architecture

```text
Attacker:          local / Kali Linux
Victim / Agent:    Ubunru-Agent          192.168.122.149
SIEM / XDR:        Wazuh Manager         192.168.122.178 (my-server)
```

**Expected event flow:**

```text
Attacker modifies critical file (/etc/passwd, /etc/hosts, ...)
        |
        | realtime syscheck event
        v
Ubuntu Agent (Wazuh Agent + FIM)
        |
        | events via 1514/tcp
        v
Wazuh Manager
        |
        +--> Rule 100030 (soft)
        +--> Rule 100031 (medium - critical file)
        +--> Rule 100032 (critical) --> Active Response (quarantine-file.sh)
        +--> Rule 100033 (layered - critical after soft)
        |
        v
Wazuh Dashboard / alerts.json
```

## 🔍 MITRE ATT&CK Mapping

```text
Tactic:     Impact (TA0040), Privilege Escalation (TA0004), Defense Evasion (TA0005)
Technique:  Stored Data Manipulation (T1565.001)
Technique:  Abuse Elevation Control Mechanism (T1548)
```

## ⚙️ Custom Detection Rules & Validation

```text
Custom Rule Configuration:
/var/ossec/etc/rules/local_rules.xml
(also stored in wazuh/rules/fim_system_tampering_rules.xml)

Rule 100030 (Level 7):
  Soft - Modification in system directories (/etc, /bin, /usr/bin, ...)

Rule 100031 (Level 10):
  Medium - Critical system file modified (/etc/passwd, /etc/shadow, /etc/sudoers, ...)

Rule 100032 (Level 12 - CRITICAL):
  Critical file modified → triggers Active Response (quarantine)

Rule 100033 (Level 14 - CRITICAL):
  Layered - Critical change after previous soft system modification
```

## 🧪 Detection Test Results

Test Case,Input / Condition,Expected Result,Status
Soft detection,Modification of /etc/hosts,Rule 100030 (level 7),PASS
Critical file,Modification of /etc/passwd,Rule 100031 → 100032,PASS
Layered detection,Soft change then critical change,Rule 100033 (level 14),PASS
Active Response,After rule 100032 / 100033,quarantine-file.sh executed,PASS
Quarantine proof,File locked + moved,chattr +i + file in /var/ossec/quarantine,PASS
Negative - normal,Non-critical file change,No high severity alert,PASS

Tests were performed with realtime FIM on Ubuntu agent. Rules were validated on Wazuh Manager 4.x.

## 📁 Repository Structure

```text
03-fim-system-tampering/
├── architecture/
│   └── architecture.md
├── wazuh/
│   ├── rules/
│   │   └── fim_system_tampering_rules.xml
│   └── configs/
│       ├── active-response.xml
│       └── ossec.conf
├── tests/
│   ├── positive/
│   │   ├── soft_etc_change.log
│   │   ├── critical_passwd_change.log
│   │   └── critical_with_process.log
│   ├── negative/
│   │   ├── normal_package_update.log
│   │   └── trusted_process.log
│   └── regression/
│       └── test_fim_rules.py
├── scripts/
│   ├── attack_simulation.sh
│   ├── cleanup_fim.sh
│   └── quarantine-file.sh
├── sample-logs/
│   └── syscheck_sample.log
├── evidence/
├── reports/
│   └── test-results.md
└── README.md
```

## ⚠️ Limitations

- Active Response uses location local (runs only on the Agent where the change occurred).
- Rule 100031 is a parent rule and usually does not appear as a separate alert when 100032 or 100033 fire.
- Whodata was disabled due to missing auditd plugins; detection relies on realtime FIM only.
- Quarantine moves the file – proper restoration procedure is required after testing.
- Tests were performed in a lab libvirt network; production tuning of monitored directories may be required.

## 🚀 Next Steps

1. Re-enable and properly configure whodata + auditd for process context.
2. Extend detection to additional critical paths (e.g. cron, systemd, SSH keys).
3. Add automatic restoration / notification after quarantine.
4. Integrate with SOAR playbooks for ticket creation.
5. Keep evidence screenshots and test-results.md up to date after any rule changes.
