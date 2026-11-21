# Deployment Status

Last updated: 2026-11-21

**Overall status: COMPLETE — BASELINE DEPLOYMENT VALIDATED**

Project 00 acceptance scope is the deployed platform, component versions, service health, Agent enrollment/connectivity, package protection and baseline SSH event ingestion. It does not certify the custom detections or Active Response scenarios in Projects 01–04.

## Milestones

| Step | Milestone | Status | Evidence |
|---:|---|---|---|
| 01 | Inventory and topology review | COMPLETE | Both VMs identified as Ubuntu 24.04.5 LTS; topology and IP addresses rechecked. |
| 02 | Remove the old Wazuh agent | COMPLETE | Historical reinstall record retained. |
| 03 | Remove the old Wazuh server stack | COMPLETE | Historical reinstall record retained. |
| 04 | Clean old Wazuh lab artifacts | COMPLETE | Historical cleanup record retained; Tracecat documentation preserved. |
| 05 | Verify the clean state | COMPLETE | Historical pre-install clean-state check retained. |
| 06 | Install the Wazuh all-in-one server | COMPLETE | Current package versions and all four services reverified on 2026-11-21. |
| 07 | Install the Wazuh agent | COMPLETE | Agent package version and service reverified on 2026-11-21. |
| 08 | Enroll and connect the agent | COMPLETE | Agent 001 (`my-agent`) reported `Active`; TCP/1514 connectivity passed. |
| 09 | SSH event-ingestion smoke test | COMPLETE — LIVE INGESTION | One controlled Kali-to-Agent authentication attempt was present in the Agent journal and Manager alerts. See [SSH evidence](evidence/ssh-event-ingestion-2026-11-21.md). |
| 10 | Real-time FIM validation | HISTORICAL — MANAGER SIDE | Manager-side create/modify/delete alert evidence is dated 2026-11-10. Dashboard verification was not captured. Current Syscheck/Whodata process state was observed on 2026-11-21; no new file-operation test was claimed. See [historical FIM evidence](evidence/fim-validation-2026-11-10.md). |

## Current version and package-hold baseline

| Package | Host | Installed version | Package hold |
|---|---|---:|---|
| `wazuh-manager` | `my-server` | `4.14.10-1` | CONFIRMED |
| `wazuh-indexer` | `my-server` | `4.14.10-1` | CONFIRMED |
| `wazuh-dashboard` | `my-server` | `4.14.10-1` | CONFIRMED |
| `filebeat` | `my-server` | `7.10.2-2` | CONFIRMED |
| `wazuh-agent` | `my-agent` | `4.14.10-1` | CONFIRMED |

Package holds were confirmed using `apt-mark showhold`:

- `my-server`: `filebeat`, `wazuh-dashboard`, `wazuh-indexer`, `wazuh-manager`.
- `my-agent`: `wazuh-agent`.

On both VMs, `/etc/apt/sources.list.d/wazuh.list` contains the Wazuh source disabled with the `WAZUH-SOC-LAB DISABLED` marker. These were pre-existing controls and were verified in place; the hold-application script was not rerun because the expected state was already active.

The version verification script was copied from the repository and executed on both hosts on 2026-11-21:

- Manager role: PASS; Manager, Indexer and Dashboard all `4.14.10-1`; Filebeat `7.10.2-2`.
- Agent role with `EXPECTED_WAZUH_VERSION=4.14.10-1`: PASS.
- Local script SHA256: `a46ed5ccc28d68b47330e242e57dba1789243fb7395e390219ef236c7ccdb874`.

This confirms the installed versions and present holds. It does not constitute an upgrade test.

## Service and network validation — 2026-11-21

On `my-server`, all of the following returned `active` and `enabled`:

- `wazuh-manager`
- `wazuh-indexer`
- `wazuh-dashboard`
- `filebeat`

Observed listeners:

| Port | Bind address | Purpose |
|---:|---|---|
| 443/TCP | `0.0.0.0` | Dashboard HTTPS |
| 1514/TCP | `0.0.0.0` | Agent event communication |
| 1515/TCP | `0.0.0.0` | Agent enrollment |
| 55000/TCP | `0.0.0.0` and `::` | Wazuh API |
| 9200/TCP | Loopback | Indexer API |
| 9300/TCP | Loopback | Indexer transport |

On `my-agent`, `wazuh-agent` returned `active` and `enabled`. Its configured Manager endpoint is `192.168.122.178:1514/TCP`; `nc -zvw3 192.168.122.178 1514` succeeded.

## Agent enrollment evidence

- Agent ID: `001`
- Agent name: `my-agent`
- Agent IP observed in the Manager enrollment log: `192.168.122.208`
- Manager agent list: `ID: 001, Name: my-agent, IP: any, Active`
- Agent configuration points to Manager `192.168.122.178`, TCP port `1514`.
- `/var/ossec/etc/client.keys` exists on the Agent. Never copy its contents into Git.

`IP: any` in the agent list is the displayed registration address in the captured output; the enrollment log separately confirms the requesting source IP. The important result is the `Active` status.

## Baseline SSH event-ingestion result

Test run: `p00-ssh-ingestion-20261121T195001Z`

- Source: Kali, `192.168.122.112`.
- Target: `my-agent`, `192.168.122.208`.
- Manager: `my-server`, `192.168.122.178`.
- Attempt: one SSH password-authentication attempt using the deliberately nonexistent user `p00-smoke-invalid`.
- Agent source: journald; the local journal recorded `Invalid user`, `authentication failure` and `Failed password`.
- Manager alert data: Agent 001 received the corresponding events. Built-in rule `5710` fired for the nonexistent user / failed password, and built-in rule `5503` recorded the PAM authentication failure.
- Result: PASS — the SSH event reached the Agent journal and was processed into Manager alert data.

The several log records are different messages from one SSH connection, not several independent password attempts. This smoke test does not validate Project 01 custom rules, correlation thresholds or firewall Active Response.

## Known observations and boundaries

- The Manager log contained Indexer `503` and missing-index `404` messages during the initial startup window. The captured output does not establish whether those warnings continued after startup. Re-check current Manager and Indexer health if they recur; do not mark them as an active fault based only on old startup messages.
- The current Agent configuration monitors `/opt/wazuh-fim-lab/watch` with Whodata and report-changes. The engine was observed running on 2026-11-21. No new FIM file-operation test was performed as part of this Project 00 closeout.
- The server also hosts Tracecat/Temporal containers and volumes. Preserve them.
- Project 00 does not validate attack-specific rules or Active Response from Projects 01–04.
