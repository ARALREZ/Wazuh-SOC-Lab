# Project 04 — Test Results

**Snapshot:** 2026-11-20 · **Wazuh:** `4.14.10-1`

## Synthetic regression

The Manager regression runner completed **8/8 PASS, 0 FAIL**:

| Scenario | Expected | Observed | Result |
|---|---|---|---|
| One denied event | `100040` | `100040` | PASS |
| Two denied events, same AUID | `100040` | `100040` | PASS |
| Three denied events, same AUID | `100040`, `100041` | `100040`, `100041` | PASS |
| Four denied events, same AUID | `100040`, `100041` | `100040`, `100041` | PASS |
| Five denied events, same AUID | `100040`, `100041`, `100042` | `100040`, `100041`, `100042` | PASS |
| Five denied events, different AUIDs | `100040` only | `100040` | PASS |
| Successful access | No custom IDs | None | PASS |
| Unrelated Auditd key | No custom IDs | None | PASS |

The `100042 frequency=4 timeframe=120` tuning is empirically validated for this lab's current Wazuh 4.14.10 ruleset. Re-run after rule-tree or version changes.

## Live integration

Real SSH session from Kali (`192.168.122.112`) to `my-agent` (`192.168.122.208`) as `p04-labuser`; session UID/loginuid `1008`. Five denied reads of `/etc/shadow` were issued inside the correlation window.

Observed Manager alert:

```json
{
  "timestamp": "2026-11-20T22:23:15.802+0000",
  "rule_id": "100042",
  "level": 12,
  "agent": "my-agent",
  "auid": "1008",
  "key": "shadow_access",
  "success": "no"
}
```

Observed Agent response log:

```text
2026-11-20T23:23:15+01:00 [P04-ActiveResponse] LOCKED password authentication for p04-labuser; rule=100042 auid=1008
```

Account states immediately after response: `p04-labuser L`; `aralrez P`. The repository contains `account-unlocked.png` from recovery as well.

## Configuration checks

- `wazuh-analysisd -t`: exit 0.
- `wazuh-execd -t`: exit 0.
- Manager service after restart: `active`.
- Agent 001: `Active`.
- Auditd `shadow_access` rule: one active match after duplicate removal.
- Agent `audit.log` localfile reader: exactly one entry.

## Evidence

See `evidence/README.md` for the eight screenshots committed with this project. `wazuh-logtest` regression is synthetic evidence; the live Manager alert and Active Response log are recorded separately above.

## Limitation

`passwd -l` locks password authentication only. It does not terminate an existing session or prove SSH public-key authentication is disabled. Project 04 does not perform IP blocking or host isolation.
