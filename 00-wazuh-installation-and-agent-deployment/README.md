# 00 – Wazuh Installation and Agent Deployment

This project documents the clean deployment of a Wazuh all-in-one server and a Linux agent for the Wazuh SOC Lab.

## Lab topology

| Host | Role | Operating system | IP address |
|---|---|---|---|
| `my-server` | Wazuh Manager, Indexer, Dashboard | Ubuntu 24.04.5 LTS | `192.168.122.178` |
| `my-agent` | Wazuh Agent | Ubuntu 24.04.5 LTS | `192.168.122.208` |
| `fedora` | Administration workstation | Fedora | `172.16.62.231` (observed) |

The server also runs a separate Tracecat/Temporal Docker stack. It is outside the scope of this project and must not be removed or pruned as part of Wazuh maintenance.

## Deployed versions

- Wazuh Manager: `4.14.10-1`
- Wazuh Indexer: `4.14.10-1`
- Wazuh Dashboard: `4.14.10-1`
- Wazuh Agent: `4.14.10-1`
- Filebeat: `7.10.2-2` (separate version scheme; compatible with Wazuh Indexer 4.14.10)

## Project contents

- `docs/` – deployment procedure, version policy, enrollment and validation guides.
- `config/` – safe configuration references and examples. Do not store credentials or private keys here.
- `scripts/` – repeatable package-hold and installed-version verification helpers.
- `tests/` – deployment and enrollment validation, SSH event-ingestion
  smoke tests, and baseline FIM checks. Custom detection and Active
  Response scenarios are documented in the relevant scenario projects,
  including [Project 01](../01-ssh-brute-force/README.md).
- `evidence/` – screenshots, sanitized logs and test results.

## Current status

See [STATUS.md](STATUS.md) for the completed deployment stages and the remaining SOC validation work.

## Safety notes

1. Keep all attack simulation inside this isolated lab and only against systems you own or are authorized to test.
2. Do not commit passwords, API keys, agent enrollment keys, private certificates, `client.keys`, or unredacted credential files.
3. Do not run broad Docker cleanup commands on `my-server`; the Tracecat stack and its volumes are intentionally preserved.
4. Keep the Wazuh central components on exactly the same release version. Keep the agent at the same version as the manager for this lab. Wazuh's compatibility rule permits the manager to be newer than an agent, but not older.
5. Package holds and the disabled Wazuh APT source prevent routine package upgrades. They do not replace a planned, coordinated upgrade procedure.
