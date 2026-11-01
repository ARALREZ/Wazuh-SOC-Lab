# Scenario 04: Linux Credential Access Detection, Kernel Auditing & Automated Response (XDR)

## 📌 Executive Summary

This project demonstrates an end-to-end SOC scenario for detecting unauthorized access attempts to Linux credential files (`/etc/shadow`) using kernel auditing (`auditd`) and Wazuh SIEM/XDR. It includes layered custom detection rules (soft → medium → critical), correlation of repeated access attempts, and automated containment via Active Response that locks the offending local account (`passwd -l`).

The lab covers detection engineering, positive/negative test cases, regression checks, and real credential-access simulation against an Ubuntu endpoint protected by a Wazuh Agent.

## 📐 Network & Lab Architecture

```text
Attacker:          local user / Kali Linux
Victim / Agent:    my-agent (Ubuntu + auditd + Wazuh Agent)   192.168.122.208
SIEM / XDR:        my-server (Wazuh Manager)                   192.168.122.178
```

**Expected event flow:**

```text
Attacker attempts to read /etc/shadow (e.g. cat /etc/shadow)
        |
        | auditd syscall event (key=shadow_access)
        v
Ubuntu Agent (Wazuh Agent + auditd)
        |
        | events via 1514/tcp
        v
Wazuh Manager
        |
        +--> Rule 100040 (soft)
        +--> Rule 100041 (medium - multiple attempts)
        +--> Rule 100042 (critical) --> Active Response (block-attacker.sh)
        |
        v
Wazuh Dashboard / alerts.json
```

## 🔍 MITRE ATT&CK Mapping

```text
Tactic:     Credential Access (TA0006)
Technique:  OS Credential Dumping: /etc/passwd and /etc/shadow (T1003.008)
```

## ⚙️ Custom Detection Rules & Validation

```text
Custom Rule Configuration:
/var/ossec/etc/rules/local_rules.xml
(also stored in wazuh/rules/linux_credential_access_rules.xml)

Rule 100040 (Level 7):
  Soft - Any access attempt to /etc/shadow with audit key shadow_access

Rule 100041 (Level 10):
  Medium - 3 attempts within 90 seconds (frequency on 100040)

Rule 100042 (Level 12 - CRITICAL):
  Critical - 5 attempts within 120 seconds → triggers Active Response
```

**Auditd rule (Agent):**

```text
-a always,exit -F path=/etc/shadow -F perm=rwa -F auid>=1000 -F auid!=-1 -k shadow_access
```

**Active Response:**

```text
Command:     block-attacker
Executable:  block-attacker.sh
Location:    local
Trigger:     rule 100042
Action:      passwd -l aralrez (lock local lab account)
```

## 🧪 Detection Test Results

| Test Case                  | Input / Condition                 | Expected Result                       | Status |
|----------------------------|-----------------------------------|---------------------------------------|--------|
| Soft detection             | Single `cat /etc/shadow`          | Rule 100040 (level 7)                 | PASS   |
| Multiple attempts          | 3–5 failed reads in short window  | Rule 100041 / 100042                  | PASS   |
| Critical + Active Response | Rule 100042 fired                 | `block-attacker.sh` executed          | PASS   |
| Containment proof          | After AR                          | `passwd -S` shows account locked (`L`)| PASS   |
| Negative - sudo / system   | `sudo` / `passwd` touching shadow | May still match key-based rule (noise)| PASS   |
| Cleanup                    | `passwd -u aralrez`               | Account unlocked                      | PASS   |

Tests were performed with auditd + Wazuh Agent on Ubuntu. Rules were validated on Wazuh Manager 4.9.2.

## 📁 Repository Structure

```text
04-Linux-Credential-Access/
├── architecture/
│   └── architecture.md
├── wazuh/
│   ├── rules/
│   │   └── linux_credential_access_rules.xml
│   └── configs/
│       ├── active-response.xml
│       ├── audit.rules
│       └── ossec.conf
├── tests/
│   ├── positive/
│   │   └── shadow_access_failed.log
│   ├── negative/
│   │   ├── normal_sudo.log
│   │   └── trusted_process.log
│   └── regression/
│       └── test_credential_rules.py
├── scripts/
│   ├── attack_simulation.sh
│   ├── block-attacker.sh
│   └── cleanup_credential.sh
├── sample-logs/
│   └── audit_sample.log
├── evidence/
│   ├── 100040_soft.png
│   ├── 100041_medium.png
│   ├── 100042_critical.png
│   ├── active_responses_log.png
│   └── account_locked.png
├── reports/
│   └── test-results.md
└── README.md
```

## ⚠️ Limitations

- Active Response uses location local (runs only on the Agent that generated the alert).
- Local audit events have no srcip; containment focuses on locking the local account, not IP blocking.
- Frequency rule 100041 may be absorbed by 100042 and not always appear as a separate alert.
- Current audit rule uses key-based matching; legitimate processes (sudo, passwd, gdm) can generate noise unless additional exe filters are applied.
- Locking the lab user account (aralrez) can lock the operator out — always run passwd -u after tests or use a dedicated test user.
- Tests were performed in a lab libvirt network; production tuning of audit rules and AR targets is required.

## 🚀 Next Steps

1. Add exe!= exclusions for trusted binaries (sudo, su, passwd) once the audit rule syntax is stable on the target kernel.
2. Map Active Response to a dedicated low-privilege test account instead of the primary lab user.
3. Extend detection to /etc/passwd, /etc/sudoers, and SSH key paths.
4. Integrate with SOAR playbooks for ticket creation and notification.
5. Keep evidence screenshots and test-results.md up to date after any rule changes.

