# Project 04 — Test Results

**Report date:** 2026-11-20  
**Project status:** IN PROGRESS  
**Wazuh baseline:** 4.14.10-1 (Project 00 is the installation baseline)

## 1. Environment

| Component | Host | Address | Role |
|---|---|---|---|
| Wazuh Manager | `my-server` | `192.168.122.178` | Rule analysis and alerts |
| Wazuh Agent 001 | `my-agent` | `192.168.122.208` | Auditd and log collection |
| Test source | Kali | `192.168.122.112` | Planned live SSH test source |

## 2. Configuration checks

| Check | Observed result | Status |
|---|---|---|
| Manager package version | `4.14.10-1` | PASS |
| Manager service before/after restart | `active` | PASS |
| Manager `wazuh-analysisd -t` after installing/updating P04 rules | Exit code 0 | PASS |
| P04 rule XML parsing and IDs | IDs `100040`, `100041`, `100042`; XML parse passed | PASS |
| Deployed P04 rule file permissions | `root:wazuh`, mode `0640` | PASS |
| Agent `wazuh-logcollector -t` | Exit code 0 | PASS |
| Agent `wazuh-agentd -t` | Exit code 0 | PASS |
| Agent service after restart | `active` | PASS |
| Agent 001 state after final restart | Not rechecked in the supplied output | PENDING |
| Agent localfile count for audit.log | Exactly 1 | PASS |
| Auditd rule | One active `shadow_access` match after duplicate removal and reload | PASS |

## 3. Synthetic single-event results

| Test | Input condition | Expected | Observed | Status |
|---|---|---|---|---|
| Positive | `key=shadow_access`, `success=no`, `auid=1000` | 100040 / level 7 | 100040 / level 7 | PASS |
| Negative | `key=shadow_access`, `success=yes` | No custom P04 rule | Base 80700 only | PASS |
| Negative | `key=other_key`, `success=no` | No custom P04 rule | Base 80700 only | PASS |

Phase 2 exposed `audit.key`, `audit.success` and `audit.auid`.

## 4. Synthetic correlation results

Initial configuration used `100042 frequency="5"`. The first five-event test did not generate 100042; `100041` classified the third event. After observing this, the rule was tuned to `frequency="4"`. The second run produced the critical rule on the fifth event.

| Case | Observed results | Status |
|---|---|---|
| One denied event | 100040 | PASS |
| Two denied events, same AUID | 100040; no 100041/100042 | PASS |
| Three denied events, same AUID | 100041 on third event | PASS |
| Four denied events, same AUID | 100041; no 100042 | PASS |
| Five denied events, same AUID | 100042 on fifth event; `frequency=4` | PASS |
| Different AUID values | Not executed yet | PENDING |

All results above are `wazuh-logtest` synthetic tests. The repository regression runner has not yet been executed from the checked-in file.

## 5. Live and Active Response results

| Test | Expected evidence | Status |
|---|---|---|
| Real SSH login from Kali as `p04-labuser` | `id`, `/proc/self/loginuid`, source and timestamp | NOT RUN |
| Real Auditd denied-read sequence | `key=shadow_access`, `success=no`, AUID 1008 | NOT RUN |
| Manager live alerts | Real 100040, 100041 and 100042 records | NOT RUN |
| Active Response add | `active-responses.log` P04 lock record | NOT RUN |
| Password state after response | `p04-labuser` is L; `aralrez` remains P | NOT RUN |
| Manual cleanup | `p04-labuser` returns to P; `aralrez` remains P | NOT RUN |

Do not mark live/Active Response rows PASS based on `wazuh-logtest` output.

## 6. Summary

- Configuration preflight and synthetic rule matching are partially complete.
- The 100042 correlation threshold was tuned from 5 to 4 based on observed Wazuh 4.14.10 behavior; the fifth-input-event test now produces the critical rule.
- Different-AUID regression, checked-in runner execution, live SSH/Auditd, Active Response, cleanup and evidence capture remain.
- Project status remains **IN PROGRESS**.
