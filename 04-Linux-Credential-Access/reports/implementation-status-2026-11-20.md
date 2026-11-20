# Project 04 — Implementation Status and Handoff

**Snapshot:** 2026-11-20  
**Plan basis:** `Projekt 04 — Linux Credential Access: Plan naprawczy krok po kroku + docelowa struktura repozytorium`, version 20.11.2026  
**Overall status:** IN PROGRESS  
**Estimated progress:** approximately 50–53% of the 16 numbered implementation steps (0–15). This is a step-weighted estimate, not a claim that the whole project is operational.

## 1. Environment confirmed

| Component | Observed value | Status |
|---|---|---|
| Manager | `my-server`, `192.168.122.178`, Wazuh `4.14.10-1` | Manager service active in the checks shown |
| Agent | `my-agent`, `192.168.122.208`, Agent ID `001`, Wazuh `4.14.10` | Agent config tests returned exit 0; service active after restart |
| Kali | `192.168.122.112` | ICMP reachability from Fedora was confirmed; live P04 SSH test not yet run |
| Fedora | Repository checkout `~/Projects/Wazuh-SOC-Lab` | Local project work in progress |

Project 00 remains the authoritative source for installation, versions and enrollment. Do not alter the platform baseline as part of Project 04.

## 2. Work completed

### Repository structure

- The old Project 04 contents were copied to a private backup outside the repository before clearing the project directory.
- The Project 04 directory was rebuilt using the planned `architecture/`, `evidence/`, `reports/`, `sample-logs/`, `scripts/`, `tests/` and `wazuh/` layout.
- No broad Git cleanup was used. Changes in Project 05, the root README and `architecture-backup-step2-20261117-122314/` were kept outside this Project 04 work.

### Manager and rules

- Manager version observed: `4.14.10-1`; service reported `active`.
- Existing rule files for Projects 01, 02 and 03 were present.
- No ID collision for `100040–100042` was found.
- Existing `firewall-drop` Active Response blocks for `100002`, `100005`, `100026` and `100027` were observed and left unchanged.
- Dedicated Project 04 rules were installed as `/var/ossec/etc/rules/linux_credential_access_rules.xml`, owner `root:wazuh`, mode `0640`.
- XML parsing and `wazuh-analysisd -t` succeeded after the rule installation and after the correlation tuning update.
- The deployed Manager file was backed up before changing `100042` to `frequency="4"`.

### Backups

- Manager preflight backup: `/var/ossec/backups/project04-preflight-20261120T165428Z`
- Agent preflight backup: `/var/ossec/backups/project04-preflight-20261120T163607Z`
- Manager rule backup before correlation tuning: `/var/ossec/etc/rules/linux_credential_access_rules.xml.pre-frequency4-20261120T180949Z`

Do not restore an entire `ossec.conf` blindly; future configuration changes may belong to other projects.

### Agent, account and Auditd

- `p04-labuser` already existed on `my-agent`; it was not recreated.
- Its UID is `1008`, its only group is its own group, and it is not in `sudo`.
- Its password state was changed from `L` to `P`; no password value is stored in this repository.
- Administrator `aralrez` was observed as password state `P`.
- The original Auditd rule `/etc/audit/rules.d/shadow_access.rules` already existed and was active.
- A duplicate rule introduced during setup was removed. After `augenrules --load`, `auditctl -l` showed one active `shadow_access` rule.
- Agent configuration already contained exactly one localfile entry for `/var/log/audit/audit.log` with `log_format=audit`.
- `wazuh-logcollector -t` and `wazuh-agentd -t` both returned exit code 0. Agent service reported `active`.

### Synthetic rule validation

The Manager's Auditd decoder exposed `audit.key`, `audit.success` and `audit.auid` in Phase 2.

The first run with `100042 frequency="5"` failed to emit 100042 on the fifth event. The observed sequence showed that `100041` classified the third event, so the critical rule did not see the expected number of base-rule matches. The rule was tuned to `frequency="4"` and rerun.

Observed results after the change:

| Synthetic case | Observed custom rule result | Status |
|---|---|---|
| One denied event | `100040` / level 7 | PASS |
| `success=yes` | No custom rule 100040–100042 | PASS |
| Different Auditd key | No custom rule 100040–100042 | PASS |
| Two denied events, same AUID | `100040`; no 100041/100042 | PASS |
| Three denied events, same AUID | `100041` appears on third event | PASS |
| Four denied events, same AUID | `100041`; no 100042 | PASS |
| Five denied events, same AUID | `100042` appears on fifth event | PASS |
| Five events with different AUIDs | Not run yet | PENDING |

These are synthetic `wazuh-logtest` results. They do not prove live Auditd forwarding or Active Response.

## 3. Progress against the PDF implementation steps

| PDF step | Required work | Status | Notes |
|---:|---|---|---|
| 0 | Work only in Project 04; inspect Git status | DONE | Project-specific work kept separate; other dirty files were not cleaned or stashed. |
| 1 | Inspect Manager rules, collisions and existing Active Response | DONE | 01–03 rule files present; no 100040–100042 collision; existing blocks preserved. |
| 2 | Back up Manager and Agent configuration | DONE | Both preflight backups and a rule-update backup recorded above. |
| 3 | Prepare low-privilege `p04-labuser` | DONE | Existing UID 1008, no sudo; current password status P. |
| 4 | Auditd rule for `/etc/shadow` | DONE | Existing original rule retained; duplicate removed; one active match. |
| 5 | Agent collection of `audit.log` | DONE | Exactly one localfile entry; both Agent config test commands returned 0. |
| 6 | Install rules 100040–100042 separately | DONE | Dedicated file installed; analysisd validation returned 0. |
| 7 | Restart Manager and Agent without Active Response | PARTIAL | Both services reported active after restart. Recheck `agent_control -i 001` after the restart before proceeding. |
| 8 | Rule matching and regression | IN PROGRESS | Positive, negative and 1–5 same-AUID synthetic sequences passed after tuning. Different-AUID case and checked-in regression runner remain. |
| 9 | Live Auditd test from real SSH session as `p04-labuser` | NOT STARTED | Use Kali `.112`; confirm `/proc/self/loginuid` equals UID 1008. No sudo-to-user substitution. |
| 10 | Install Active Response script on Agent | NOT STARTED | Script source is prepared; `jq` availability, ownership and mode 0750 still need checking. |
| 11 | Add only Project 04 Active Response fragment on Manager | NOT STARTED | Must be added inside existing `ossec_config`; preserve 01–03 blocks. |
| 12 | Restart and test Active Response | NOT STARTED | Require live alert 100042, active-responses log and account state L. |
| 13 | Cleanup and recovery | NOT STARTED | Unlock only `p04-labuser`; verify state P and administrator remains P. |
| 14 | Capture evidence and finalize test report | NOT STARTED | Seven named screenshots and raw logs required. |
| 15 | Final Git review and status update | NOT STARTED | `git diff --check`; verify no other project changes enter the P04 commit. |

## 4. Remaining work — in execution order

1. Reconfirm Agent ID `001` is Active after the Manager restart.
2. Add the different-AUID case to `tests/regression/test_credential_rules.py`; run the repository runner on Manager and save its raw output.
3. Recheck the `100042 frequency=4` sequence with that runner. Do not enable Active Response until all negative and boundary cases pass.
4. Run the live detection-only test: real SSH login as `p04-labuser`, verify `id` and `/proc/self/loginuid`, run five denied reads, and inspect Auditd plus Manager alert records.
5. Only after live detection passes, install `p04-lock-test-account.sh` on the Agent and add the separate Manager fragment for rule 100042 only.
6. Validate `wazuh-execd -t` on relevant hosts before restarting; then test the real lock and verify `p04-labuser=L`, `aralrez=P`.
7. Run the account-specific cleanup and verify `p04-labuser=P` and `aralrez=P`.
8. Capture evidence and reconcile README, test results, architecture and evidence register.
9. Final Git review. Do not commit unrelated Project 05, root README or backup directory changes.

## 5. Rule filename normalization request

A separate operator request asked to rename the deployed rule files to `01.xml`, `02.xml`, `03.xml` and `04.xml`. This is **not required by the PDF**, which explicitly names `linux_credential_access_rules.xml` and expects the Project 04 source path to remain descriptive. Keep the current deployed name while testing. If the numeric naming convention is still desired, perform it as a separate controlled migration after rule/live validation, updating repository references and recording the mapping. Do not rename files during the current detection-validation stage.

## 6. Current safe state

- Project 04 detection rules are installed; Active Response is not yet configured for Project 04.
- No Project 04 IP-blocking or iptables action has been introduced.
- `p04-labuser` is configured with a usable password (state P) and no sudo membership.
- Do not run the attack simulation as root or through `sudo -u p04-labuser`; the login AUID must originate from a real test-account login.
- Do not mark the project DONE until live detection, response, cleanup, evidence and final Git criteria all pass.
