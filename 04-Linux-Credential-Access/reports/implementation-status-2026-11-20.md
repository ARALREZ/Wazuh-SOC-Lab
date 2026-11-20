# Project 04 — Implementation Status

**Snapshot:** 2026-11-20  
**Status:** COMPLETE — LIVE LAB VALIDATED  
**Wazuh:** `4.14.10-1`

## Confirmed environment

- Manager: `my-server`, `192.168.122.178`, service active after restart.
- Agent: `my-agent`, `192.168.122.208`, ID `001`, status Active.
- Test client: Kali, `192.168.122.112`.
- Dedicated account: `p04-labuser`, UID/loginuid `1008`, no sudo membership in recorded checks.

## Completed implementation and validation

- Dedicated Manager rule file installed separately: `/var/ossec/etc/rules/linux_credential_access_rules.xml`.
- Rules `100040`, `100041`, `100042` loaded; `wazuh-analysisd -t` returned exit 0.
- Auditd watched `/etc/shadow` with key `shadow_access`; one active rule remained after duplicate removal.
- Agent collected `/var/log/audit/audit.log` using one `log_format=audit` localfile entry.
- Synthetic regression: **8/8 PASS, 0 FAIL**, including different-AUID separation, successful access and unrelated Auditd key.
- Manager `wazuh-execd -t`: exit 0; Manager restarted and reported active.
- Real SSH session from Kali produced five denied `/etc/shadow` accesses with loginuid `1008`.
- Manager emitted live rule `100042`, level 12, Agent `my-agent`, AUID `1008`, key `shadow_access`, success `no`.
- Agent Active Response logged the account lock for `p04-labuser`, rule `100042`, AUID `1008`.
- Account state after response: `p04-labuser=L`; administrator `aralrez=P`.
- Evidence screenshots for detection, login identity, regression, lock, and recovery are present under `evidence/`.

## Rule tuning

`100042` uses `frequency=4 timeframe=120`. This tuning was selected from observed Wazuh 4.14.10 behavior and passed the supplied 8-case regression and live fifth-attempt test. It is specific to this rule tree and must be retested after relevant changes.

## Acceptance matrix

| Requirement | Result |
|---|---|
| Rule syntax and analysisd | PASS |
| Active Response config and execd | PASS |
| Synthetic rule regression | PASS — 8/8 |
| Different-AUID separation | PASS |
| Real SSH identity | PASS — loginuid 1008 |
| Live alert 100042 | PASS |
| Active Response invocation | PASS |
| Target-only password lock | PASS — `p04-labuser=L`, `aralrez=P` |
| Recovery evidence | Captured — `account-unlocked.png` |

## Limits

`passwd -l` locks password authentication; it does not terminate an existing session or necessarily disable public-key SSH authentication. There is no IP blocking or host isolation in this project. Project 00 remains authoritative for platform installation and enrollment.
