# Overview and Lab Topology

## Objective

Build a clean Wazuh SOC lab consisting of one all-in-one Wazuh server and one monitored Ubuntu endpoint. Document installation, enrollment, version control, and initial detection validation.

## Topology

| Host | Role | OS | IP address |
|---|---|---|---|
| `my-server` | Wazuh Manager, Indexer, Dashboard | Ubuntu 24.04.5 LTS | `192.168.122.178` |
| `my-agent` | Wazuh Agent | Ubuntu 24.04.5 LTS | `192.168.122.208` |
| `fedora` | Workstation used for administration | Fedora | `172.16.62.231` (observed) |

The server has additional `172.x` addresses associated with Docker networks. Use `192.168.122.178` as the agent's Manager address in this lab; it is on the same `192.168.122.0/24` network as the agent.

## Network flows

| Port | Protocol | Purpose |
|---:|---|---|
| 1514 | TCP | Agent-to-Manager event communication |
| 1515 | TCP | Agent enrollment/authentication |
| 55000 | TCP | Wazuh API |
| 443 | TCP | Wazuh Dashboard HTTPS |
| 9200 | TCP, loopback on this deployment | Wazuh Indexer API |
| 9300 | TCP, loopback on this deployment | Indexer transport |

Confirm actual listeners and firewall rules on the deployed host before changing network policy.

## Deployment baseline

- Wazuh central components: `4.14.10-1`.
- Wazuh agent: `4.14.10-1`.
- Filebeat: `7.10.2-2`.
- Agent ID: `001`.
- Agent name: `my-agent`.

## Scope boundary

The `my-server` host also runs Tracecat/Temporal in Docker. This project does not manage that application stack. Do not use `docker system prune`, `docker volume prune`, or broad Docker removal commands as part of Wazuh cleanup.
