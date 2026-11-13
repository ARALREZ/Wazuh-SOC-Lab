# Project 02 — Evidence Register

**Scenario:** Web Attack Detection and Active Response  
**Environment:** Wazuh 4.14.10-1  
**Evidence date:** 2026-11-13

## 1. Evidence policy

This directory stores screenshots and sanitized text evidence specific to Project 02. Project 00 contains the platform installation, enrollment and baseline deployment evidence; do not duplicate those screenshots here.

A test result and a screenshot are different things. A scenario may have been completed while its image is still absent from the repository. Mark a file as present only after checking that the PNG exists and shows the correct host, timestamp, rule ID and event.

Do not commit passwords, private keys, `client.keys`, API tokens, certificates containing private keys, or unredacted secrets.

## 2. Detection evidence

| File | Required content | Repository status |
|---|---|---|
| `100020-scanner-detection.png` | Custom scanner alert `100020`, source and User-Agent | Verify / add PNG |
| `100021-sqli-detection.png` | SQL Injection alert `100021` | Verify / add PNG |
| `100022-xss-detection.png` | XSS alert `100022` | Verify / add PNG |
| `100023-path-traversal-detection.png` | Path Traversal alert `100023` | Verify / add PNG |
| `100024-command-injection.png` | Command Injection alert `100024` | Verify / add PNG |
| `100025-repeated-scanner-correlation.png` | Repeated scanner correlation `100025` | Verify / add PNG |
| `100026-multiple-web-attacks.png` | Multiple web attacks correlation `100026` | Verify / add PNG |
| `100027-scanner-then-exploit.png` | Scanner followed by attack correlation `100027` | Verify / add PNG |
| `100028-trusted-source.png` | Trusted-source alert `100028`, source `192.168.122.1` | Verify / add PNG |
| `100029-suspicious-uri.png` | Suspicious URI alert `100029` | Verify / add PNG |
| `trusted-source-negative-tests.png` | Fedora test requests and proof that Project 02 custom attack rules did not fire for the trusted source; distinguish native Wazuh alerts | Verify / add PNG |

## 3. Active Response and firewall evidence

Use these filenames to keep the Project 02 evidence convention consistent with Project 01.

| File | Required content | Repository status |
|---|---|---|
| `active_responses_log.png` | Agent `/var/ossec/logs/active-responses.log` with Project 02 `add` and `delete` records; identify the triggering rule ID | Verify / add PNG |
| `ar_blocked_ip.png` | Manager alert `651` (`Host Blocked`) tied to a Project 02 correlation alert | Verify / add PNG |
| `iptables_drop.png` | Actual DROP rule for Kali source `192.168.122.112` on `my-agent` during the block | Verify / add PNG |
| `iptables_drop_kali.png` | Kali terminal showing failed HTTP connection during the same block window | Verify / add PNG |
| `http_restored_after_timeout.png` | Kali HTTP request succeeding after automatic timeout/delete | Verify / add PNG |

The Active Response log and firewall screenshots should identify whether the cycle belongs to `100026` or `100027`. If one image cannot clearly show both cycles, keep separate rule-specific images, for example `100026-active-response.png` and `100027-active-response.png`.

## 4. Source logs and reproducibility

Where practical, retain sanitized text excerpts alongside screenshots:

- relevant records from `/var/ossec/logs/alerts/alerts.json`;
- relevant records from `/var/ossec/logs/active-responses.log` on `my-agent`;
- the matching Apache access-log entries;
- the exact request command and source host used for the test.

Keep the raw event timestamps consistent across the Manager alert, Agent response log, firewall state and client-side connectivity result. Do not fabricate or infer a timestamp that is not visible in the source output.

## 5. Acceptance criteria

1. The screenshot is present in this directory and opens correctly.
2. The test host and target host are identifiable.
3. The relevant rule ID or Active Response command is visible.
4. The screenshot is from the final lab run, not an obsolete configuration.
5. The evidence distinguishes custom Project 02 rules from built-in Wazuh rules.
6. For Active Response, correlate the Manager alert, Agent `add`, actual DROP, blocked HTTP request, Agent `delete` and restored HTTP request.
7. A `wazuh-logtest` screenshot is labelled as synthetic rule testing, not live Active Response.

## 6. Current repository inventory note

The `tree` output supplied during the documentation review showed only this `README.md` under `02-web-attack-detection/evidence/`. Therefore the PNG rows above are an evidence checklist, not a claim that those image files are already committed. Update the status column after copying and reviewing each actual PNG.
