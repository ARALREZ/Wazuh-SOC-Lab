# Project 04 — Evidence Register

**Scenario:** Linux Credential Access Detection and Account Password Lockout  
**Platform:** Wazuh 4.14.10-1; Manager `my-server`; Agent ID `001` on `my-agent`  
**Evidence snapshot:** 2026-11-20

## Evidence policy

Keep evidence from one identifiable test cycle. Record timestamp, host, rule ID, test account and source ID where applicable. Never commit passwords, password hashes, private keys, `client.keys`, API tokens or unredacted secrets. A screenshot filename alone is not evidence; open and review each image before marking it present.

Synthetic `wazuh-logtest` output must be labelled synthetic. It must not be presented as live Auditd ingestion or Active Response proof.

## Expected screenshots

| File | Required content | Status at snapshot |
|---|---|---|
| `100040-soft-detection.png` | Manager alert for one denied Auditd event, rule 100040 level 7, AUID 1008 | Pending capture/review |
| `100041-medium-correlation.png` | Manager alert 100041 level 10 for same AUID | Pending live capture |
| `100042-critical-detection.png` | Manager alert 100042 level 12 on the fifth live denied attempt | Pending live capture |
| `active-response-add.png` | Agent `active-responses.log` entry showing P04 add/LOCKED action for 100042 | Pending |
| `account-locked.png` | `passwd -S p04-labuser` showing `L`, plus administrator still `P` | Pending |
| `account-unlocked.png` | Cleanup result and `passwd -S p04-labuser` showing `P`; administrator unchanged | Pending |
| `regression-summary.png` | Final repository runner output including positive, negative, boundary and different-AUID cases | Pending |

## Raw evidence to retain

- sanitized relevant Manager records from `/var/ossec/logs/alerts/alerts.json`;
- relevant Agent records from `/var/ossec/logs/active-responses.log`;
- the corresponding Auditd records containing `key=shadow_access`, `success=no` and `auid`;
- the regression runner log and summary;
- screenshots from the same test cycle as the raw records.

## Acceptance criteria

1. Rule ID, level, host and AUID are legible.
2. Live test proves a real SSH session with `p04-labuser` and matching `/proc/self/loginuid`.
3. Active Response evidence shows rule 100042 and the allow-listed account UID match.
4. `account-locked.png` and `account-unlocked.png` show the actual password state before/after cleanup.
5. `aralrez` remains in password state `P` throughout.
6. Synthetic rule tests are not labelled live evidence.
