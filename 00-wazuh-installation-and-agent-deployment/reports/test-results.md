# Project 00 — Baseline Test Results

**Report date:** 2026-11-21  
**Repository revision observed before this validation:** `4cfac83161b2b07ddb8e9b7ab42a66db7ed1ea52`  
**Environment:** Wazuh 4.14.10-1; Ubuntu Server/Endpoint 24.04.5 LTS  
**Overall result:** PASS — baseline deployment validated

## 1. Environment and version verification

| Component | Host | Observed version | Result |
|---|---|---:|---|
| Wazuh Manager | my-server | 4.14.10-1 | PASS |
| Wazuh Indexer | my-server | 4.14.10-1 | PASS |
| Wazuh Dashboard | my-server | 4.14.10-1 | PASS |
| Filebeat | my-server | 7.10.2-2 | PASS |
| Wazuh Agent | my-agent | 4.14.10-1 | PASS |

The central Wazuh packages match exactly. The Agent version was explicitly checked against `EXPECTED_WAZUH_VERSION=4.14.10-1`.

The local `verify-wazuh-versions.sh` file SHA256 was:

```text
a46ed5ccc28d68b47330e242e57dba1789243fb7395e390219ef236c7ccdb874
```

Execution results:

- Manager role: PASS; central component versions match; Filebeat reported separately.
- Agent role: PASS; expected Wazuh version confirmed.

## 2. Service and connectivity validation

On `my-server`, `wazuh-manager`, `wazuh-indexer`, `wazuh-dashboard` and `filebeat` all returned `active` and `enabled`.

On `my-agent`, `wazuh-agent` returned `active` and `enabled`. Manager reported Agent `001` / `my-agent` as `Active`. The Agent's configured Manager endpoint was `192.168.122.178:1514/TCP`; `nc -zvw3` to that endpoint succeeded.

Observed Manager listeners were 443, 1514, 1515 and 55000. Indexer ports 9200 and 9300 were bound to loopback.

## 3. Package protection

`apt-mark showhold` confirmed:

- my-server: `filebeat`, `wazuh-dashboard`, `wazuh-indexer`, `wazuh-manager`.
- my-agent: `wazuh-agent`.

The Wazuh APT source was disabled on both VMs using the `WAZUH-SOC-LAB DISABLED` marker. This was an already-applied state and was verified in place. The hold-application script was reviewed but not rerun because the expected holds and disabled source were already active. The version-verification script was executed on both hosts.

Package holds protect the baseline from routine package operations; they are not an upgrade strategy. Any future upgrade must follow the coordinated procedure in [the version policy](../docs/05-version-pinning-and-upgrade-policy.md).

## 4. SSH event-ingestion smoke test

| Field | Result |
|---|---|
| Test run ID | `p00-ssh-ingestion-20261121T195001Z` |
| Source | Kali, 192.168.122.112 |
| Target | my-agent, 192.168.122.208 |
| Agent ID | 001 |
| Manager | my-server, 192.168.122.178 |
| Attempt | One authentication failure using nonexistent user `p00-smoke-invalid` |
| Agent log source | journald |
| Manager alerts | Built-in rule 5710 (two records) and 5503 (one record) |
| Result | PASS |

The Agent journal contained `Invalid user`, `authentication failure`, `Failed password` and connection-close messages. Corresponding events were found in Manager `alerts.json`, attributed to Agent 001 and source IP `192.168.122.112`.

Manager event timestamps were 2026-11-21 19:50:01.526 UTC (5710), 19:50:05.518 UTC (5503) and 19:50:07.520 UTC (5710). Agent journal timestamps were 20:50:01, 20:50:05, 20:50:07 and 20:50:08 at UTC+01:00.

Several log records came from one SSH connection. They are not separate password attempts.

Detailed sanitized record: [SSH event-ingestion evidence](../evidence/ssh-event-ingestion-2026-11-21.md).

## 5. FIM status

The historical 2026-11-10 report confirms Manager-side detection of file creation (554), modification (550) and deletion (553) in the then-used test directory. Dashboard visibility was explicitly not verified in that evidence.

On 2026-11-21, the Agent Syscheck process and real-time Whodata engine were observed running, and the current configured path `/opt/wazuh-fim-lab/watch` was listed with `whodata` and `report_changes`. No new file-operation test was run during this Project 00 closeout; no new FIM PASS is claimed.

Historical evidence: [FIM validation — 2026-11-10](../evidence/fim-validation-2026-11-10.md).

## 6. Acceptance summary

| Project 00 acceptance criterion | Result |
|---|---|
| Component versions verified on both VMs | PASS |
| Services active; Agent 001 Active | PASS |
| Package hold implemented and confirmed, or explicitly rejected | PASS — holds confirmed |
| Fresh baseline SSH/event-ingestion evidence | PASS |
| README and STATUS aligned to the same date and status | PASS |

**Conclusion:** Project 00 baseline deployment is COMPLETE — BASELINE DEPLOYMENT VALIDATED as of 2026-11-21. This conclusion is limited to infrastructure and baseline telemetry ingestion. It does not certify Projects 01–04 detection or Active Response functionality.
