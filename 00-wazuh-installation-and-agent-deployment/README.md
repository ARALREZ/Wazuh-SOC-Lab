# 00 – Wazuh Installation and Agent Deployment

This project is the source of truth for the Wazuh SOC Lab baseline: deployment topology, component versions, agent enrollment, package protection, service health and initial telemetry ingestion. Attack-specific detection and Active Response validation belongs in the relevant scenario projects.

## Lab topology

| Host | Role | Operating system | IP address |
|---|---|---|---|
| `my-server` | Wazuh Manager, Indexer, Dashboard | Ubuntu 24.04.5 LTS | `192.168.122.178` |
| `my-agent` | Wazuh Agent; monitored endpoint | Ubuntu 24.04.5 LTS | `192.168.122.208` |
| `kali` | Authorized lab test client | Kali Linux | `192.168.122.112` |
| `fedora` | Administration workstation | Fedora | `172.16.62.231` (observed) |
| libvirt host-side/gateway address | Network-side source seen by lab VMs in selected tests | — | `192.168.122.1` |

Do not confuse the Fedora workstation address `172.16.62.231` with `192.168.122.1`, which is the source address observed from the VM network in selected lab scenarios.

The server also runs a separate Tracecat/Temporal Docker stack. It is outside the scope of this project and must not be removed or pruned as part of Wazuh maintenance.

## Deployed versions

| Component | Host | Verified version on 2026-11-21 |
|---|---|---:|
| Wazuh Manager | `my-server` | `4.14.10-1` |
| Wazuh Indexer | `my-server` | `4.14.10-1` |
| Wazuh Dashboard | `my-server` | `4.14.10-1` |
| Filebeat | `my-server` | `7.10.2-2` |
| Wazuh Agent | `my-agent` | `4.14.10-1` |

Filebeat uses a separate version scheme. The three central Wazuh components were verified to match exactly. The Manager and Agent were verified at the same release for this lab baseline.

## Baseline validation — 2026-11-21

The deployment baseline was rechecked on both VMs:

- Manager, Indexer, Dashboard and Filebeat services were `active` and `enabled`.
- Agent service was `active` and `enabled`.
- Manager reported Agent `001` (`my-agent`) as `Active`.
- Expected service ports were listening: 443, 1514, 1515 and 55000; Indexer ports 9200 and 9300 were bound to loopback.
- TCP connectivity from the Agent to Manager port 1514 succeeded.
- Package holds and the disabled Wazuh APT source were confirmed on both VMs.
- The version verification script passed on the Manager and Agent.
- A single controlled SSH authentication attempt from Kali was visible first in the Agent journal and then in Manager alert data. The observed built-in rules were 5710 and 5503.

The SSH smoke test validates telemetry ingestion only. It does not validate custom Project 01 detection thresholds, correlation or Active Response. See [STATUS.md](STATUS.md), [the test report](reports/test-results.md) and [the sanitized SSH evidence](evidence/ssh-event-ingestion-2026-11-21.md).

The historical FIM test from 2026-11-10 confirmed Manager-side alert generation only; Dashboard visibility was not verified in that evidence. On 2026-11-21, the current Syscheck and Whodata processes were observed running, but no new end-to-end FIM file-operation test was claimed. See [the historical FIM evidence](evidence/fim-validation-2026-11-10.md).

## Project contents

- `docs/` – deployment procedure, version policy, enrollment and validation guides.
- `config/` – safe configuration references and examples. Do not store credentials or private keys here.
- `scripts/` – repeatable package-hold and installed-version verification helpers.
- `tests/` – deployment, enrollment, SSH event-ingestion and baseline FIM procedures.
- `evidence/` – sanitized test evidence and evidence register.
- `reports/` – validation reports and test results.

## Safety notes

1. Keep all attack simulation inside this isolated lab and only against systems you own or are authorized to test.
2. Do not commit passwords, API keys, agent enrollment keys, private certificates, `client.keys`, or unredacted credential files.
3. Do not run broad Docker cleanup commands on `my-server`; the Tracecat stack and its volumes are intentionally preserved.
4. Keep the Wazuh central components on exactly the same release version. Keep the Agent at the same version as the Manager for this lab. Wazuh compatibility permits a Manager newer than an Agent, but not an older Manager.
5. Package holds and the disabled Wazuh APT source prevent routine package upgrades. They do not replace a planned, coordinated upgrade procedure.
6. Treat Project 00 as the infrastructure baseline. Custom detection logic and Active Response acceptance tests remain in their scenario projects.
