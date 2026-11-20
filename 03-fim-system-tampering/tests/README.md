# Project 03 — Test Strategy

Project 03 separates FIM detection validation from quarantine utility validation.

## Test layers

| Layer | Location | Host | Purpose |
|---|---|---|---|
| Rule source/config validation | `wazuh/rules/fim_system_tampering_rules.xml` | Fedora / Manager | XML syntax and `wazuh-analysisd -t` |
| Live FIM/Who-data integration | `tests/integration/check-fim-alerts.py` | `my-server` | Verify Manager alerts for a specific test ID |
| Quarantine regression | `tests/regression/run-quarantine-regression.sh` | `my-agent` | Test manual quarantine/restore and its security properties |
| Evidence capture | `scripts/evidence/` | `my-agent` | Capture outstanding quarantine screenshots |

## Safety

- Use only the isolated lab and authorized hosts.
- Quarantine fixtures must be created by the test run and directly inside `/opt/wazuh-fim-lab/watch`.
- Cleanup must remove only fixtures with its own unique TEST_ID.
- Never remove unrelated quarantine items, `baseline.txt`, existing evidence or another run's fixtures.
- Do not use `git clean`, `git reset --hard`, `git add -A` or global stash as part of testing.
- Do not connect quarantine to Active Response.

## Interpretation

A `wazuh-logtest` PASS means the supplied event matched a rule. It does not prove live syscheck telemetry, Who-data collection, file quarantine, restore or network containment. Record each validation layer separately.
