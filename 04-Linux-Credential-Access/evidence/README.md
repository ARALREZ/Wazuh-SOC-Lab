# Project 04 — Evidence Register

**Snapshot:** 2026-11-20 · Wazuh `4.14.10-1` · Agent `my-agent`, ID `001`.

| File | Evidence | Status |
|---|---|---|
| `100040-soft-detection.png` | Rule 100040 single denied Auditd event | Captured |
| `100041-medium-correlation.png` | Rule 100041 same-AUID correlation | Captured |
| `100042-critical-detection.png` | Live rule 100042, level 12, AUID 1008 | Captured |
| `live-ssh-loginuid.png` | Real SSH login and loginuid 1008 | Captured |
| `regression-summary.png` | Regression runner: 8/8 PASS | Captured |
| `active-response-add.png` | Agent response log: lock action for rule 100042/AUID 1008 | Captured |
| `account-locked.png` | `p04-labuser=L`, `aralrez=P` | Captured |
| `account-unlocked.png` | Recovery: test account returned to `P` | Captured |

## Correlated live event

Manager: rule `100042`, level `12`, Agent `my-agent`, AUID `1008`, key `shadow_access`, success `no`. Agent log: `LOCKED password authentication for p04-labuser; rule=100042 auid=1008`.

Do not commit passwords, hashes, private keys, `client.keys`, tokens or unredacted secrets. Keep `wazuh-logtest` evidence labelled synthetic and distinct from live Manager/Agent evidence.
