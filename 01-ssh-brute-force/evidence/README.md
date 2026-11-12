# Project 01 — Evidence Register

**Project:** SSH Brute Force Detection & Active Response  
**Environment:** Wazuh 4.14.10-1  
**Last reviewed:** 2026-11-12

## Evidence policy

Only retain screenshots and sanitized logs captured from the
current lab deployment.

Synthetic `wazuh-logtest` results must be distinguished from
live SSH and firewall tests.

Never store passwords, private keys, `client.keys`, API tokens,
or other authentication secrets in this directory.

A file being present in Git does not by itself prove that its image
contents show the final test run. Before final publication, visually
review each screenshot and confirm that its host, timestamp, rule ID
and test scenario are correct.

## Detection evidence

| File | Required evidence | Repository status |
|---|---|---|
| `100001_soft.png` | Rule 100001, level 6 | PRESENT — review image contents |
| `100002_brute_force.png` | Rule 100002, level 10 | PRESENT — review image contents |
| `100003_publickey.png` | Rule 100003, level 6 | PRESENT — review image contents |
| `100004_password_spraying.png` | Rule 100004, level 10 | PRESENT — review image contents |
| `100005_critical.png` | Rule 100005, level 14, source Kali, test account | PRESENT — verify it is the final LIVE run |
| `100010_trusted_ip.png` | Rule 100010, level 3 | PRESENT — review image contents |

## Active Response evidence

| File | Required evidence | Repository status |
|---|---|---|
| `active_responses_log.png` | Agent log containing the relevant `add` and `delete` events | PRESENT — verify the final 100005 cycle is visible |
| `ar_blocked_ip.png` | Kali cannot establish a new SSH connection to `my-agent:22` during BLOCK | PRESENT — review image contents |
| `iptables_drop.png` | Actual DROP rule on `my-agent` for `192.168.122.112` | PRESENT — review image contents |
| `iptables_drop_kali.png` | Additional firewall screenshot | PRESENT — retain only if it adds distinct, correctly labelled evidence |

For rule 100005, the four principal screenshots should document the
same live test cycle: critical alert, firewall DROP, blocked SSH
connection, and Active Response `add` / `delete`.

The normal test must allow Wazuh to execute the automatic `delete`.
Do not manually remove the DROP rule to create evidence of unblocking.

## Regression evidence

| File | Required evidence | Repository status |
|---|---|---|
| `regression-summary.png` | Final totals from 17 fast and 6 slow regression cases | NOT PRESENT — capture after both suites pass |

Do not create a summary image showing PASS before the runner has
completed all tests. If any test fails or is interrupted, record
that result accurately.

## Evidence acceptance criteria

1. Record the current date and environment.
2. Show the relevant agent, rule ID, description and timestamp.
3. Sanitize unrelated usernames and sensitive information.
4. For Active Response, correlate the Manager alert with the Agent
   execution log and actual firewall state.
5. For rule 100005, verify `add`, actual DROP, blocked TCP/22,
   automatic `delete` after 600 seconds and restored TCP/22.
6. Do not mark Active Response PASS from configuration validation
   or `wazuh-logtest` alone.
7. Update this register immediately after capturing or replacing evidence.
