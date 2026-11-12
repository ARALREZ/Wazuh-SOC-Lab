# Project 01 — Evidence Register

**Project:** SSH Brute Force Detection & Active Response  
**Environment:** Wazuh 4.14.10-1  
**Last reviewed:** 2026-11-12

## Evidence policy

Only retain screenshots and sanitized logs captured from the
current lab deployment.

Old screenshots from earlier deployments have been archived outside
the repository. They must not be presented as evidence of the
current Wazuh 4.14.10 deployment.

Synthetic `wazuh-logtest` results must be distinguished from
live SSH and firewall tests.

Never store passwords, private keys, `client.keys`, API tokens,
or other authentication secrets in this directory.

## Required detection evidence

| File | Required evidence | Status |
|---|---|---|
| `100001_soft.png` | Rule 100001, level 6 | NOT CAPTURED |
| `100002_brute_force.png` | Rule 100002, level 10 | NOT CAPTURED |
| `100003_publickey.png` | Rule 100003, level 6 | NOT CAPTURED |
| `100004_password_spraying.png` | Rule 100004, level 10 | NOT CAPTURED |
| `100005_critical.png` | Rule 100005, level 14 | NOT CAPTURED |
| `100010_trusted_ip.png` | Rule 100010, level 3 | NOT CAPTURED |

## Required Active Response evidence

| File | Required evidence | Status |
|---|---|---|
| `active_responses_log.png` | Active Response execution on Agent | NOT CAPTURED |
| `ar_blocked_ip.png` | Evidence of the attacker IP block | NOT CAPTURED |
| `iptables_drop.png` | Exact firewall chain/rule responsible for block | NOT CAPTURED |

## Required test evidence

| File | Required evidence | Status |
|---|---|---|
| `regression-summary.png` | Final regression totals and results | NOT CAPTURED |

## Evidence acceptance criteria

1. Record the current date and environment.
2. Show the relevant agent, rule ID, description and timestamp.
3. Sanitize unrelated usernames and sensitive information.
4. For Active Response, correlate the Manager alert with the
   Agent execution log and actual firewall state.
5. Do not mark Active Response PASS from configuration validation
   or `wazuh-logtest` alone.
6. Update this register immediately after capturing new evidence.
