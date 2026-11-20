# Project 04 — Linux Credential Access & Account Password Lockout

**Status: COMPLETE — LIVE LAB VALIDATED**  
**Implementation/evidence snapshot:** 2026-11-20  
**Platform baseline:** Wazuh `4.14.10-1`; Project 00 remains the source of truth for installation, versions and enrollment.  
**MITRE ATT&CK:** T1003.008 — OS Credential Dumping: `/etc/passwd` and `/etc/shadow`.

## Overview

Project 04 detects denied attempts to read `/etc/shadow` on the monitored Ubuntu endpoint. Auditd records the syscall with key `shadow_access`; the Wazuh Agent forwards `/var/log/audit/audit.log`; custom rules classify a single denied event, repeated attempts and a critical sequence.

When rule `100042` is generated for the dedicated lab account, Wazuh Active Response executes `p04-lock-test-account.sh` locally on the endpoint. The script checks the command, rule ID, Agent ID and `audit.auid`, then locks password authentication for the fixed allow-listed account `p04-labuser` only.

**Containment boundary:** `passwd -l` locks password authentication. It does not terminate an existing session and does not by itself guarantee that SSH public-key authentication is disabled. This is an account-specific password lockout, not full account disablement or host isolation.

## Lab topology

| Host | Role | Address |
|---|---|---|
| `my-server` | Wazuh Manager, Indexer and Dashboard | `192.168.122.178` |
| `my-agent` | Ubuntu endpoint, Wazuh Agent ID `001`, Auditd | `192.168.122.208` |
| Kali | Authorized SSH test source | `192.168.122.112` |
| Fedora | Administration workstation and repository checkout | `172.16.62.231` |

## Detection rules

Source: `wazuh/rules/linux_credential_access_rules.xml`  
Deployed Manager path: `/var/ossec/etc/rules/linux_credential_access_rules.xml`.

| Rule | Level | Detection |
|---|---:|---|
| `100040` | 7 | One denied event with `audit.key=shadow_access` and `audit.success=no`. |
| `100041` | 10 | Repeated denied events for the same `audit.auid`, frequency 3 / timeframe 90 seconds. |
| `100042` | 12 | Critical correlation for the same `audit.auid`, frequency 4 / timeframe 120 seconds. |

The `100042 frequency=4` value is the empirically validated configuration for this lab's Wazuh `4.14.10` rule tree. The supplied regression sequence and live event both produced the critical rule on the fifth denied attempt. Revalidate after changing the parent/child rule logic or Wazuh version; do not treat this tuning as universal for every ruleset.

## Auditd and collection

- Auditd watches `/etc/shadow` with key `shadow_access`.
- Events are collected from `/var/log/audit/audit.log` using one Agent `<localfile>` entry with `log_format=audit`.
- Exactly one active `shadow_access` rule and one Agent localfile reader were confirmed during implementation; a duplicate Auditd rule encountered during setup was removed.
- Reference fragments are in `wazuh/configs/audit.rules` and `wazuh/configs/agent-localfile.conf`. Check existing endpoint configuration before adding either; do not duplicate them.

## Active Response

- Command: `p04-lock-test-account`
- Executable: `p04-lock-test-account.sh`
- Execution: `location=local`
- Trigger: rule `100042` only
- Timeout: `timeout_allowed=no`; recovery is manual after evidence capture
- Target: fixed account `p04-labuser` (UID `1008` in the recorded lab run)

The response script accepts only `command=add`, rule ID `100042`, Agent ID `001`, and a numeric AUID equal to the current UID of `p04-labuser` (UID at least 1000). It proceeds only when `passwd -S` reports `P`, verifies the resulting state is `L`, and logs the action. It never accepts an arbitrary username from alert data and does not block source IPs.

The Manager fragment is `wazuh/configs/manager-active-response.xml`. It is a fragment for insertion into the existing Manager `/var/ossec/etc/ossec.conf`, not a replacement file. Its `<active-response>` block explicitly sets `<disabled>no</disabled>`.

## Validation results

| Validation | Result |
|---|---|
| Rule/config validation | `wazuh-analysisd -t`: exit 0 |
| Active Response config validation | `wazuh-execd -t`: exit 0 |
| Rule regression | **8/8 PASS, 0 FAIL** |
| Real SSH session | Kali to `my-agent` as `p04-labuser`; login UID `1008` |
| Live Manager alert | Rule `100042`, level 12, Agent `my-agent`, AUID `1008`, key `shadow_access`, success `no` |
| Active Response | Log recorded `LOCKED password authentication for p04-labuser; rule=100042 auid=1008` |
| Account state after response | `p04-labuser=L`; administrator `aralrez=P` |
| Recovery | `account-unlocked.png` captured; recovery evidence is included in the evidence register |

`wazuh-logtest` proves rule matching for synthetic input only. Live Auditd ingestion, Manager alert generation and Active Response are recorded separately above.

## Evidence

See [`evidence/README.md`](evidence/README.md). Screenshots include the 100040, 100041 and 100042 alerts, real SSH login UID, regression summary, Active Response action, locked account and recovered account.

## Safety notes

- Use only this isolated lab and systems you own or are authorized to test.
- Run live tests from a genuine SSH login as `p04-labuser`; do not use `sudo -u` because the login AUID may remain the administrator UID.
- Preserve Projects 01–03 rules and their `firewall-drop` response blocks.
- Do not add duplicate Auditd rules or duplicate `audit.log` localfile entries.
- Recovery affects only `p04-labuser`; verify both `p04-labuser=P` and `aralrez=P` after cleanup.
- Project 00 owns installation and enrollment documentation.
