# Project 01 — Test and Validation Results

**Documentation snapshot:** 2026-11-21\
**Platform baseline:** Wazuh `4.14.10-1`\
**Project status:** IN PROGRESS — current full regression suites and final evidence review are outstanding.

> This report consolidates the validation records already present in the project. The documentation update does not execute Wazuh tests or repeat live SSH/Active Response scenarios. Historical and operator-confirmed results are labelled as such; pending suites are not reported as passed.

## 1. Environment

| Component | Host | Version / Address |
|---|---|---|
| Wazuh Manager | `my-server` | `4.14.10-1` / `192.168.122.178` |
| Wazuh Indexer | `my-server` | `4.14.10-1` |
| Wazuh Dashboard | `my-server` | `4.14.10-1` |
| Filebeat | `my-server` | `7.10.2-2` |
| Wazuh Agent | `my-agent` | `4.14.10-1` / `192.168.122.208` |
| Authorized test source | Kali | `192.168.122.112` |
| Trusted source | Fedora / VM network | `192.168.122.1` as observed by the Agent |

Manager and Agent operating system: Ubuntu 24.04.5 LTS. Project 00 contains the current platform baseline and the 2026-11-21 service, version and connectivity checks.

The Project 00 SSH smoke test validates baseline event ingestion only. It does not validate Project 01 custom thresholds, correlation or Active Response.

## 2. Configuration validation previously recorded

| Check | Recorded result | Scope / limitation |
|---|---|---|
| Project rules XML parsing | PASS | Syntax check only |
| Active Response reference XML parsing | PASS | Does not prove response execution |
| `wazuh-analysisd -t` | PASS | Exit code 0 recorded after the final rule `100005` update |
| Manager restart | PASS | Manager returned `active` after the recorded configuration change |
| Active Response timeout for `100002` | 600 seconds | Deployed configuration record |
| Active Response timeout for `100005` | 600 seconds | Deployed configuration record |
| Manager / Agent connectivity | ACTIVE | Current platform baseline is maintained in Project 00 |

These results originate from the previous project validation record. They were not re-executed during this documentation revision.

## 3. Individual synthetic `wazuh-logtest` observations

The following scenarios were recorded as passing during prior rule validation. They are synthetic event tests, not live SSH or firewall tests.

| Scenario | Expected custom result | Recorded observation | Result |
|---|---|---|---|
| Three failed SSH passwords | `100001`, level 6 | Rule triggered on third event | PASS — historical individual test |
| Five failed SSH passwords | `100001` and `100002` | `100001` on attempt 3; `100002` on attempt 5 | PASS — historical individual test |
| Trusted-source failure | `100010`, level 3 | Trusted rule matched | PASS — historical individual test |
| Failed public-key authentication | `100003`, level 6 | Rule triggered | PASS — historical individual test |
| Five different usernames from one source | `100004`, level 10 | Rule triggered within the 300-second window | PASS — historical individual test |
| Three failures followed by success | `100001` and `100005` | Both rules triggered; `100005` on successful event | PASS — historical individual test |

### Five failures followed by successful login

Fixture: `tests/positive/brute-force-success-after-5fails.log`\
Recorded test date: 2026-11-12\
Tool: Wazuh Manager `wazuh-logtest`

| Event | Expected | Recorded observation | Result |
|---:|---|---|---|
| 1 | `5760`, level 5 | `5760`, level 5 | PASS |
| 2 | `5760`, level 5 | `5760`, level 5 | PASS |
| 3 | `100001`, level 6 | `100001`, level 6 | PASS |
| 4 | `5760`, level 5 | `5760`, level 5 | PASS |
| 5 | `100002`, level 10 | `100002`, level 10 | PASS |
| 6 | `100005`, level 14 | `100005`, level 14 | PASS |

The recorded result was 6/6 event-level matches. It does not demonstrate a real SSH compromise or Active Response execution.

## 4. Current regression-suite status

The current runner defines 17 fast cases and 6 slow cases. The current complete suites are **not recorded as completed** in this report.

| Suite | Defined cases | Execution status | Result |
|---|---:|---|---|
| Fast regression | 17 | PENDING | Not yet recorded for the current runner snapshot |
| Slow time-window cases | 6 | PENDING | Not yet recorded for the current runner snapshot |
| Full run with `--include-slow` | 23 total (17 fast + 6 slow) | PENDING | Must complete without interruption and be reviewed |

An earlier 16/16 result belongs to a historical version of the test suite. It is not the result of the current 17-case fast suite. Do not copy that historical total into a new summary.

The runner command without options executes 17 fast cases. The `--include-slow` option executes the 17 fast cases again and then the six delayed cases; it does not run only the slow cases.

## 5. Live SSH detection records

The prior lab handoff records the following live scenarios as successful. These are operator-reported live results, distinct from `wazuh-logtest` tests.

| Rule | Live scenario | Recorded status |
|---|---|---|
| `100001` | Three failed SSH passwords from Kali | PASS — operator-reported |
| `100002` | Confirmed SSH brute force from Kali | PASS — operator-reported |
| `100003` | Failed public-key authentication from Kali | PASS — operator-reported |
| `100004` | Password spraying from Kali using different accounts | PASS — operator-reported |
| `100005` | Failed attempts followed by successful Kali login | PASS — operator-reported final rule behavior |
| `100010` | Failed SSH authentication from trusted source | PASS — operator-reported |

For `100005`, the prior record states that the Agent observed an `Accepted password` event and the Manager generated a level-14 alert for the Kali source and test account. This documentation update does not repeat that live test.

## 6. Active Response and firewall records

Both response blocks are configured for `firewall-drop`, `location=local`, with `timeout=600` seconds.

| Check | Rule `100002` | Rule `100005` |
|---|---|---|
| Manager alert | PASS — recorded | PASS — recorded |
| Agent `add` event | PASS — recorded | PASS — operator-confirmed |
| Actual DROP rule for Kali source | PASS — recorded | PASS — operator-confirmed |
| New TCP/22 connection blocked from Kali | PASS — recorded | PASS — operator-confirmed |
| Automatic `delete` | PASS — recorded | PASS — operator-confirmed |
| New TCP/22 connection restored | PASS — recorded | PASS — operator-confirmed |
| Configured timeout | 600 seconds | 600 seconds |

These are prior live-test records, not new tests executed during this documentation update. The evidence register identifies the screenshots that must be reviewed to ensure that the Manager alert, Agent response log, firewall state and Kali-side result belong to the same cycle.

Historical note: the earlier Project 01 report records one initial test cycle using a 60-second timeout before the deployed timeout was changed to 600 seconds. The current reference configuration uses 600 seconds for both trigger rules. Do not use the older 60-second cycle as evidence of the final configuration.

## 7. Screenshot inventory and outstanding evidence

The project tree contains screenshot files for:

- six custom detection rules: `100001`, `100002`, `100003`, `100004`, `100005` and `100010`;
- Active Response execution log;
- firewall DROP state;
- Kali-side block / firewall evidence.

The exact filenames and evidence acceptance criteria are maintained in `evidence/README.md`.

`regression-summary.png` is not present in the current project tree. Capture it only after the current 17-case fast suite and six slow cases have completed successfully. The contents of existing screenshots still require a final visual check for rule ID, host, source IP, timestamp and correlation to the same live test cycle.

## 8. Acceptance checklist

| Requirement | Current state |
|---|---|
| Custom rule definitions `100001`–`100005`, `100010` | Present in the project XML |
| Individual synthetic rule observations | Historical PASS records present |
| Current 17-case fast regression | PENDING |
| Current six delayed cases | PENDING |
| Live detection scenarios | Previously reported PASS; not repeated in this revision |
| Live Active Response for `100002` and `100005` | Previously reported PASS; evidence review outstanding |
| Automatic timeout and recovery | Previously reported PASS; final screenshot/log correlation outstanding |
| Existing detection and response screenshots | Present; visual-content review outstanding |
| Regression summary screenshot | Not present; create only after passing full suites |
| Final selective Git diff review | PENDING |

## 9. Overall assessment

Detection rules and selected live response scenarios have been implemented and demonstrated in the lab. However, the current 17-case fast regression and six delayed cases have not yet been recorded as complete, and the evidence set requires final review.

**Project status: IN PROGRESS.** Mark the project complete only after the current regression suites pass, actual outputs are recorded, screenshot contents are checked and the final Git diff contains only the intended Project 01 changes.
