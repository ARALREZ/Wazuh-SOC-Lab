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
| Local XML parsing: rules file | PASS | Python XML parser |
| Local XML parsing: Active Response fragment | PASS | Python XML parser |
| Local XML parsing: whitelist fragment | PASS | Python XML parser |
| `wazuh-analysisd -t` | PASS — previous validation | Repeat after final deployment |
| `wazuh-execd -t` | PASS — previous validation | Repeat after final deployment |
| Manager/Agent connectivity | ACTIVE — previously confirmed | Re-check before live tests |

Local XML parsing confirms syntax only. It does not replace validation
by the Wazuh Manager configuration tools.

## 3. Individual `wazuh-logtest` Results

Previously completed positive synthetic-event tests:

| Scenario | Expected result | Observed result | Status |
|---|---|---|---|
| 3 failed SSH passwords | 100001 / level 6 | Rule triggered | PASS |
| 5 failed SSH passwords | 100001 and 100002 | 100001 on attempt 3; 100002 on attempt 5 | PASS |
| Trusted source failure | 100010 / level 3 | Trusted rule only | PASS |
| Failed public-key authentication | 100003 / level 6 | Rule triggered | PASS |
| 5 different usernames from one IP | 100004 / level 10 | Triggered with 61-second spacing | PASS |
| 3 failures followed by successful login | 100001 and 100005 | Both rules triggered | PASS |

### New fixture: 5 failures followed by successful login

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

This is a synthetic-event test. It does not demonstrate a live SSH
compromise or Active Response execution.

## 4. Regression Tests

| Run | Result | Interpretation |
|---|---|---|
| Earlier standard runner | 16/16 PASS | Historical baseline before the new sixth-event fixture was added |
| Updated standard runner | NOT RUN | Must be executed on Manager |
| Slow regression (`--include-slow`) | INTERRUPTED | Previous run was manually stopped; no complete result |
| Updated slow regression | NOT RUN | Must be completed on Manager |

The updated fast runner now contains 17 cases. The slow suite contains
6 time-window cases. These counts describe the test definitions,
not completed test results.

## 5. Live Attack Tests

| Scenario | Status |
|---|---|
| Live public-key failure from Kali | NOT VERIFIED |
| Live password spraying from Kali | NOT VERIFIED |
| Live successful login after brute force | NOT VERIFIED |
| Live SSH brute-force sequence from Kali | NOT VERIFIED |
| Trusted Fedora source live test | NOT VERIFIED |

A `wazuh-logtest` result must not be reported as a live attack test.

## 6. Active Response and Firewall

| Check | Status |
|---|---|
| Separate Manager response block for 100002 | CONFIGURED |
| Separate Manager response block for 100005 | CONFIGURED |
| Execution location | `local` |
| Timeout | 600 seconds |
| Agent `firewall-drop` script exists | PREVIOUSLY CONFIRMED |
| Agent Active Response execution log | NOT VERIFIED |
| Actual firewall rule created for Kali | NOT VERIFIED |
| Actual SSH traffic from Kali blocked | NOT VERIFIED |
| Timeout expiration / unblocking | NOT VERIFIED |

Configuration validation and synthetic rule matching do not prove
that Active Response executed.

Active Response may only be marked PASS after confirming:

1. The triggering alert on the Manager.
2. The corresponding execution entry on the Agent.
3. The exact firewall chain/rule created for the attacker IP.
4. A controlled connection attempt demonstrating the block.
5. The timeout behavior or correct removal of the matching rule.

## 7. Current Overall Assessment

**Detection engineering:** Core synthetic-event scenarios validated.

**Regression:** Updated full suite pending.

**Time-window validation:** Incomplete.

**Live SSH scenarios:** Not verified.

**Active Response enforcement:** Not verified.

**Project status:** IN PROGRESS.

No final completion claim should be made until the missing tests are
completed and current evidence has been collected.
