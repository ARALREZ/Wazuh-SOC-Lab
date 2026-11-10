# Deployment Status

Last updated: 2026-11-10

## Milestones

| Step | Milestone | Status | Evidence |
|---:|---|---|---|
| 01 | Inventory and topology review | COMPLETE | Ubuntu 24.04.5 LTS identified on both VMs; IP addresses recorded. |
| 02 | Remove the old Wazuh agent | COMPLETE | `wazuh-agent` purged; service, `/var/ossec`, and old repository files removed. |
| 03 | Remove the old Wazuh server stack | COMPLETE | Old Manager, Indexer, Dashboard, and Filebeat packages purged. |
| 04 | Clean old Wazuh lab artifacts | COMPLETE | Old Wazuh logs, caches, installer archive, SSH test files, and password file removed. Tracecat documentation was preserved. |
| 05 | Verify the clean state | COMPLETE | No old Wazuh packages, services, processes, listening ports, or old lab files remained before reinstall. |
| 06 | Install the Wazuh all-in-one server | COMPLETE | Manager, Indexer, and Dashboard `4.14.10-1`; Filebeat `7.10.2-2`; services active. |
| 07 | Install the Wazuh agent | COMPLETE | Agent `4.14.10-1`; `wazuh-agent.service` active and enabled. |
| 08 | Enroll and connect the agent | COMPLETE | Manager reports agent ID `001`, name `my-agent`, status `Active`; manager log records enrollment request from `192.168.122.208`. |
| 09 | SSH detection validation | IN PROGRESS | Current deployment SSH validation pending. |
| 10 | Real-time FIM validation | COMPLETE - Manager side | File added, modified and deleted alerts confirmed. |

## Current version baseline

| Package | Host | Installed version | Package hold |
|---|---|---:|---|
| `wazuh-manager` | `my-server` | `4.14.10-1` | PENDING |
| `wazuh-indexer` | `my-server` | `4.14.10-1` | PENDING |
| `wazuh-dashboard` | `my-server` | `4.14.10-1` | PENDING |
| `filebeat` | `my-server` | `7.10.2-2` | PENDING |
| `wazuh-agent` | `my-agent` | `4.14.10-1` | PENDING |

Run `scripts/hold-wazuh-packages.sh server` on `my-server` and `scripts/hold-wazuh-packages.sh agent` on `my-agent`. Then verify with `apt-mark showhold` and `scripts/verify-wazuh-versions.sh`.

## Agent enrollment evidence

- Agent ID: `001`
- Agent name: `my-agent`
- Agent IP observed in the manager enrollment log: `192.168.122.208`
- Manager enrollment log: `Received request for a new agent (my-agent) from: 192.168.122.208`
- Manager agent list: `ID: 001, Name: my-agent, IP: any, Active`
- Agent configuration points to manager `192.168.122.178`, TCP port `1514`.
- `/var/ossec/etc/client.keys` exists on the agent. Never copy its contents into Git.

`IP: any` in the agent list is the displayed registration address in the captured output; the enrollment log separately confirms the requesting source IP. The important result is the `Active` status.

## Known observations

- The Manager log contained Indexer `503` and missing-index `404` messages during the initial startup window. The supplied output does not establish whether these warnings continued after startup. Re-check current Manager and Indexer health if they recur; do not mark them as an active fault based only on old startup messages.
- The server also hosts Tracecat/Temporal containers and volumes. Preserve them.
