# Project 01 — Test Results

**Report date:** 2026-11-12  
**Project status:** IN PROGRESS

## 1. Environment

| Component | Host | Version / Address |
|---|---|---|
| Wazuh Manager | `my-server` | `4.14.10-1` / `192.168.122.178` |
| Wazuh Indexer | `my-server` | `4.14.10-1` |
| Wazuh Dashboard | `my-server` | `4.14.10-1` |
| Filebeat | `my-server` | `7.10.2-2` |
| Wazuh Agent | `my-agent` | `4.14.10-1` / `192.168.122.208` |
| Attacker test host | Kali | `192.168.122.112` |
| Trusted source | Fedora | `192.168.122.1` as observed by Agent |

Operating system on Manager and Agent: Ubuntu 24.04.5 LTS.

## 2. XML and Configuration Validation

| Check | Result | Notes |
|---|---|---|
| Rules XML syntax | PASS | Final rules file is stored in `wazuh/rules/ssh_brute_force_rules.xml` |
| Active Response XML syntax | PASS | Two separate response blocks |
| `wazuh-analysisd -t` | PASS | Exit code 0 after final rule 100005 update |
| Manager restart | PASS | `wazuh-manager` returned `active` after restart |
| Active Response timeout for 100002 | 600 seconds | Deployed Manager configuration |
| Active Response timeout for 100005 | 600 seconds | Deployed Manager configuration |
| Manager/Agent connectivity | ACTIVE | Previously confirmed in the lab |

Local XML parsing confirms syntax only. `wazuh-analysisd -t`
validates the Manager analysis configuration; it does not prove
Active Response execution.

## 3. Individual `wazuh-logtest` Results

The following synthetic-event tests were observed during Project 01
validation. These are rule-matching results, not live SSH tests.

| Scenario | Expected result | Observed result | Status |
|---|---|---|---|
| 3 failed SSH passwords | 100001 / level 6 | Rule triggered | PASS |
| 5 failed SSH passwords | 100001 and 100002 | 100001 on attempt 3; 100002 on attempt 5 | PASS |
| Trusted source failure | 100010 / level 3 | Trusted rule only | PASS |
| Failed public-key authentication | 100003 / level 6 | Rule triggered | PASS |
| 5 different usernames from one IP | 100004 / level 10 | Rule triggered within the 300-second window | PASS |
| 3 failures followed by successful login | 100001 and 100005 | Both rules triggered | PASS |

### Five failures followed by successful login

Fixture:

`tests/positive/brute-force-success-after-5fails.log`

Tested on the Wazuh Manager using `wazuh-logtest` on 2026-11-12.

| Event | Expected | Observed | Status |
|---:|---|---|---|
| 1 | 5760 / level 5 | 5760 / level 5 | PASS |
| 2 | 5760 / level 5 | 5760 / level 5 | PASS |
| 3 | 100001 / level 6 | 100001 / level 6 | PASS |
| 4 | 5760 / level 5 | 5760 / level 5 | PASS |
| 5 | 100002 / level 10 | 100002 / level 10 | PASS |
| 6 | 100005 / level 14 | 100005 / level 14 | PASS |

**Result:** 6/6 event-level results matched expectations.

This is a synthetic-event test. It does not demonstrate a live
SSH compromise or Active Response execution.

## 4. Regression Tests

| Suite | Defined cases | Execution status | Result |
|---|---:|---|---|
| Fast regression | 17 | PENDING | Must run after fixing and validating the runner |
| Slow time-window regression | 6 | PENDING | Previous slow run was interrupted; rerun to completion |

The earlier 16/16 result belongs to a historical version of the
runner. It is not the result of the current 17-case suite.

The test counts describe the current test definitions, not completed
execution. Do not report 17/17 or 6/6 until the corresponding runs
finish and the output is reviewed.

## 5. Live SSH Detection Tests

The following live scenarios have been reported as successful in the
lab. They are separate from `wazuh-logtest` results.

| Rule | Scenario | Live status |
|---|---|---|
| 100001 | Three failed SSH passwords from Kali | PASS |
| 100002 | Confirmed SSH brute force from Kali | PASS |
| 100003 | Failed public-key authentication from Kali | PASS |
| 100004 | Password spraying from Kali using different accounts | PASS |
| 100005 | Three failed passwords followed by successful login from Kali | PASS — final rule correction |
| 100010 | Failed SSH authentication from trusted Fedora source | PASS |

For rule 100005, the successful event was recorded by the Agent
as `Accepted password` and the Manager generated alert `100005`
at level 14 for the Kali source IP and the lab test user.

## 6. Active Response and Firewall

Both Manager response blocks use `firewall-drop`, `location=local`
and `timeout=600`.

| Check | Rule 100002 | Rule 100005 |
|---|---|---|
| Manager alert | PASS | PASS |
| Agent execution log `add` | PASS | PASS — operator-confirmed |
| Actual DROP for Kali source IP | PASS | PASS — operator-confirmed |
| New TCP/22 connection blocked from Kali | PASS | PASS — operator-confirmed |
| Automatic `delete` | PASS | PASS — operator-confirmed |
| TCP/22 reachable again | PASS | PASS — operator-confirmed |
| Configured timeout | 600 seconds | 600 seconds |

Historical note: one earlier 100002 cycle recorded approximately
600 seconds between `add` and `delete`; another earlier cycle used
60 seconds before the Active Response timeout was changed to 600.
The final Manager configuration for both rules is 600 seconds.

The final rule 100005 live test is reported as completing the
BLOCK / DELETE / SSH-restored cycle. Use the screenshots in the
evidence directory as the visual record; do not invent timestamps
that are not visible in the underlying logs.

## 7. Evidence

The evidence directory currently contains screenshot files for:

- all six custom detection rules,
- Active Response execution log,
- actual firewall DROP,
- blocked connection evidence from Kali.

`regression-summary.png` is still pending because the current
17-case and 6-case suites have not yet been completed.

See `evidence/README.md` for the file register and review status.

## 8. Current Overall Assessment

**Detection engineering:** six custom rules implemented and live-tested.  
**Rule 100005:** synthetic PASS and operator-confirmed LIVE PASS.  
**Active Response:** live BLOCK / DELETE confirmed for 100002 and 100005.  
**Timeout configuration:** 600 seconds for both response blocks.  
**Fast regression:** pending, 17 cases.  
**Slow regression:** pending, 6 cases.  
**Evidence:** detection and Active Response screenshot files are present; final content review and regression summary remain.  
**Project status:** IN PROGRESS.

Do not mark the project Completed until both regression suites pass,
the final report and evidence register are reconciled, and the Git diff
has been reviewed.
