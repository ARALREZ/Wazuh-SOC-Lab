# Project 04 — Linux Credential Access & Account Password Lockout

**Status: IN PROGRESS**  
**Platform baseline:** Wazuh 4.14.10-1 (Project 00 is the source of truth for installation, versions and enrollment).  
**Implementation snapshot:** 2026-11-20  
**MITRE ATT&CK:** T1003.008 — OS Credential Dumping: /etc/passwd and /etc/shadow

## 1. Overview

Project 04 detects denied attempts to access `/etc/shadow` on the monitored Ubuntu endpoint. Linux Auditd records the relevant syscall with the key `shadow_access`; the Wazuh Agent forwards `/var/log/audit/audit.log` to the Manager; custom rules classify a single denial, repeated denials and a critical sequence.

After detection has been verified independently, a stateless Wazuh Active Response will lock **password authentication only** for the dedicated low-privilege account `p04-labuser`. The script must verify the alert rule ID and match `audit.auid` to the UID of that one allow-listed account. It must never lock `aralrez` or an arbitrary account from alert data.

## 2. Scope and safety decisions

Included:
- custom rules `100040–100042` in a dedicated rules file;
- Auditd monitoring of `/etc/shadow` with key `shadow_access`;
- collection of `/var/log/audit/audit.log` by the Agent;
- synthetic rule regression, live SSH/Auditd validation and Active Response validation;
- a reversible, account-specific cleanup procedure;
- evidence register, test report, architecture and risk assessment.

Excluded:
- changes to Project 01–03 detection rules or their existing `firewall-drop` Active Response blocks;
- replacing `local_rules.xml` or the complete Manager/Agent `ossec.conf`;
- IP blocking, iptables changes or host isolation;
- locking the administrator account;
- automatic unlock through an Active Response `delete` command.

**Important limitation:** `passwd -l p04-labuser` locks password authentication for that account. It does not terminate an already-open session and does not by itself guarantee that public-key SSH authentication is disabled. This project claims a *password lockout of the dedicated test account*, not full endpoint isolation.

## 3. Lab topology

| Host | Role | Address |
|---|---|---|
| `my-server` | Wazuh Manager, Indexer and Dashboard | `192.168.122.178` |
| `my-agent` | Ubuntu endpoint, Wazuh Agent ID `001`, Auditd | `192.168.122.208` |
| `Kali` | Authorized remote SSH test source | `192.168.122.112` |
| `Fedora` | Administration workstation / repository checkout | host-side `172.16.62.231`; observed trusted VM-side source `192.168.122.1` |

Project 00 owns the baseline installation, package and enrollment documentation. Do not duplicate or change that baseline from this scenario.

## 4. Detection rules

Source: `wazuh/rules/linux_credential_access_rules.xml`  
Deployed on Manager: `/var/ossec/etc/rules/linux_credential_access_rules.xml`

| Rule | Level | Purpose |
|---|---:|---|
| `100040` | 7 | One denied access event: `audit.key=shadow_access` and `audit.success=no`. |
| `100041` | 10 | Repeated denied events for the same `audit.auid` within 90 seconds. |
| `100042` | 12 | Critical sequence for the same `audit.auid` within 120 seconds; the observed Wazuh 4.14.10 `wazuh-logtest` behavior is documented below. |

### Observed correlation tuning

The first test with `100042 frequency="5"` did not trigger on the fifth input event. In the same sequence, the third event was classified by `100041`, rather than appearing as a normal `100040` Phase 3 result. The rule was then changed to `frequency="4"`; the rerun produced `100042` on the fifth event, while `100041` appeared on the third and `100042` did not appear on the fourth.

This is an observed, version-specific tuning result for the current lab ruleset. It has passed the supplied synthetic `wazuh-logtest` sequence, but **must still be confirmed with live Auditd events before Active Response is enabled**. Do not silently change the threshold in the report.

## 5. Auditd and Agent collection

The endpoint already had one active Auditd rule for `shadow_access`. A second identical rule was briefly added during setup, caused `Rule exists` during `augenrules --load`, and was removed. The original `/etc/audit/rules.d/shadow_access.rules` was preserved. The active rule count was verified as exactly one after reload.

The Agent already had exactly one `<localfile>` entry for `/var/log/audit/audit.log` with `log_format=audit`. The following fragment is a reference only; it must not be added again when the existing entry is present:

```xml
<localfile>
  <log_format>audit</log_format>
  <location>/var/log/audit/audit.log</location>
</localfile>
```

## 6. Active Response policy

Planned command: `p04-lock-test-account`  
Planned executable: `p04-lock-test-account.sh`  
Execution location: `local` (the endpoint associated with the alert)  
Trigger: rule `100042` only  
Timeout: disabled (`timeout_allowed=no`); unlock is manual after the test.

The response script must:
1. read the Wazuh JSON message from STDIN;
2. accept only the `add` command and rule ID `100042`;
3. extract `audit.auid` from the alert;
4. compare it with the current UID of `p04-labuser` (UID must be at least 1000);
5. lock only that account, and only when its password state is `P`;
6. skip mismatched AUIDs and already-locked accounts; log every decision.

The response source file in this package is **not deployed**. Active Response remains disabled until the live detection step has passed. See [response policy](architecture/response-policy.md) and [deployment notes](scripts/response/README.md).

## 7. Validation layers

1. XML parsing and `wazuh-analysisd -t` on Manager.
2. `wazuh-logcollector -t` and `wazuh-agentd -t` on Agent.
3. Synthetic positive, negative and correlation tests with `wazuh-logtest`.
4. Different-AUID regression case (still pending at this snapshot).
5. Live Auditd event from a real SSH login as `p04-labuser` from Kali.
6. Actual Manager alert verification.
7. Active Response execution and account-state verification.
8. Manual cleanup and confirmation that the administrator remains unlocked.

A `wazuh-logtest` PASS proves only rule matching for supplied input. It does not prove live log ingestion, live correlation, Active Response execution, password lockout or cleanup.

## 8. Current implementation status

See [Implementation Status — 2026-11-20](reports/implementation-status-2026-11-20.md) for the step-by-step comparison against the 20.11.2026 PDF. See [Test Results](reports/test-results.md) for the actual synthetic test outcomes.

## 9. Repository layout

```text
04-Linux-Credential-Access/
├── README.md
├── architecture/
│   ├── architecture.md
│   ├── detection-flow.md
│   └── response-policy.md
├── evidence/
│   └── README.md
├── reports/
│   ├── implementation-status-2026-11-20.md
│   ├── risk-assessment.md
│   └── test-results.md
├── sample-logs/
│   └── audit_sample.log
├── scripts/
│   ├── attack_simulation.sh
│   ├── cleanup_credential.sh
│   └── response/
│       ├── README.md
│       └── p04-lock-test-account.sh
├── tests/
│   ├── README.md
│   ├── boundary/README.md
│   ├── negative/
│   ├── positive/
│   └── regression/
│       ├── expected-results.md
│       └── test_credential_rules.py
└── wazuh/
    ├── configs/
    │   ├── agent-localfile.conf
    │   ├── audit.rules
    │   └── manager-active-response.xml
    └── rules/
        └── linux_credential_access_rules.xml
```

## 10. Related project

[Project 00 — Wazuh Installation and Agent Deployment](../00-wazuh-installation-and-agent-deployment/README.md)
