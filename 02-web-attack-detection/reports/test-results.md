# Project 02 — Test Results

**Report date:** 2026-11-13  
**Project status:** LAB VALIDATION COMPLETED — repository evidence reconciliation in progress  
**Wazuh baseline:** 4.14.10-1 (see Project 00 for installation and package baseline)

## 1. Environment

| Component | Host | Role | Address |
|---|---|---|---|
| Wazuh Manager | `my-server` | Central analysis / alerts | `192.168.122.178` |
| Wazuh Agent + Apache2 | `my-agent` | Monitored web endpoint | `192.168.122.208` |
| Test source | Kali | HTTP attack simulation | `192.168.122.112` |
| Trusted source | Fedora | Administration / trusted HTTP traffic | `192.168.122.1` as observed by Apache |

Project 00 documents installation, package versions, enrollment and baseline connectivity. This report records only Project 02 web-detection and response validation.

## 2. Configuration validation

| Check | Observed result | Notes |
|---|---|---|
| Manager `wazuh-analysisd -t` | PASS | Exit code 0 was recorded after the Project 02 rule update. |
| Manager `wazuh-execd -t` | PASS | Exit code 0. |
| Agent `wazuh-execd -t` | PASS | Exit code 0. |
| Agent service | PASS | `wazuh-agent` reported `active`. |
| Agent-to-Manager state | PASS | Agent state reported `connected`; Manager listed Agent ID `001` as Active. |
| Manager service after restart | PASS | `wazuh-manager` returned `active`; `wazuh-execd` and `wazuh-analysisd` were running. |
| Manager backup | PASS | `ossec.conf` backup and active file had identical SHA256 at capture time. |

The backup was created at:

```text
/var/ossec/backups/project-02/ossec.conf.pre-project02-live-ar-20261113.xml
```

## 3. Custom detection results

The operator confirmed the live scenarios below as completed. The table records the final operator-reported state; individual raw alert records should be retained in the evidence directory where available.

| Rule ID | Detection | Level | Result | Notes |
|---|---|---:|---|---|
| `100020` | Scanner User-Agent | 6 | PASS | Scanner detection scenario confirmed by operator. |
| `100021` | SQL Injection | 10 | PASS | Live HTTP request from Kali generated the custom alert. |
| `100022` | XSS | 10 | PASS | Live HTTP request from Kali generated the custom alert. |
| `100023` | Path Traversal / LFI | 10 | PASS | Live HTTP request from Kali generated the custom alert. |
| `100024` | Command Injection pattern | 12 | PASS | Live URI pattern `?cmd=%3Bid` generated the custom alert. |
| `100025` | Repeated scanner correlation | 9 | PASS | Repeated scanner scenario confirmed by operator. |
| `100026` | Multiple web attacks | 12 | PASS | Live correlation from Kali generated the alert. |
| `100027` | Scanner followed by attack | 13 | PASS | Layered correlation scenario confirmed by operator. |
| `100028` | Trusted source | 3 | PASS | Fedora request from `192.168.122.1` generated the low-severity trusted-source alert. |
| `100029` | Suspicious URI | 5 | PASS | Live PHP-wrapper URI pattern generated the custom alert. |

### Observed live alert examples

The following live custom alerts were visible in the Manager `alerts.json` output on 2026-11-13:

- `100021` from `192.168.122.112` for a SQL injection-pattern request;
- `100022` from `192.168.122.112` for an XSS-pattern request;
- `100026` from `192.168.122.112` for multiple web attacks within 180 seconds;
- `100023` from `192.168.122.112` for a path traversal-pattern request;
- `100024` from `192.168.122.112` for `/?cmd=%3Bid`;
- `100029` from `192.168.122.112` for a `php://filter` URI pattern;
- `100028` from `192.168.122.1` for trusted-source HTTP traffic.

These detections identify request patterns in Apache telemetry. They do not establish that the server executed the requested command, evaluated the XSS payload, or disclosed the requested file.

### Trusted-source interpretation

The custom Project 02 rules exclude the trusted Fedora source where configured, and the benign Fedora request generated `100028` at level 3. Native Wazuh web rules are not globally suppressed by this project-level trusted-source logic. During the supplied trusted-source attack-pattern tests, native alerts such as `31508` and `31106` were also observed. Those are built-in Wazuh detections, not custom Project 02 rule IDs.

## 4. Regression results

The Project 02 handoff records the fast regression runner result:

```text
Scenarios: 16
PASS:      16
FAIL:      0
RESULT:    PASS
```

The 16 scenarios cover:

1. Scanner User-Agent detection (`100020`).
2. SQL Injection (`100021`).
3. XSS (`100022`).
4. Path Traversal (`100023`).
5. Command Injection (`100024`).
6. Trusted benign request (`100028`).
7. Suspicious URI (`100029`).
8. Four scanner events below the `100025` correlation threshold.
9. Five scanner events reaching `100025`.
10. Two high-severity web attack events below the `100026` correlation threshold.
11. Three different high-severity attack events reaching `100026`.
12. Three SQLi events also reaching `100026` (the rule does not require unique techniques).
13. One scanner event followed by exploit-pattern event, without `100027`.
14. Two scanner events followed by exploit-pattern event, with `100027`.
15. Scanner and exploit-pattern events from different source IPs, without `100027`.
16. Scanner activity without a subsequent exploit-pattern event, without `100027`.

The fast runner uses `wazuh-logtest` in separate scenarios. It validates rule matching, not actual elapsed-time behavior in a running Manager daemon, Apache connectivity or firewall enforcement. The handoff explicitly identifies real-time window-expiry tests and broader trusted-source negative cases as separate test coverage; do not describe the 16-case run as proof of those additional tests.

## 5. Active Response and firewall results

The deployed Project 02 Active Response policy is limited to rules `100026` and `100027`:

| Trigger | Command | Location | Timeout |
|---|---|---|---:|
| `100026` | `firewall-drop` | `local` | 600 seconds |
| `100027` | `firewall-drop` | `local` | 600 seconds |

The operator confirmed completion of the live Active Response scenarios for both correlation rules, including the block/timeout/restore sequence.

### Rule 100026 — visible Manager evidence

The supplied Manager output recorded:

- alert `100026`, level 12, source `192.168.122.112`;
- Active Response `add` at `2026-11-13 21:43:17`;
- alert `651` — `Host Blocked by firewall-drop Active Response`;
- Active Response `delete` at `2026-11-13 21:53:18`;
- alert `652` — `Host Unblocked by firewall-drop Active Response`.

The observed `add` to `delete` interval was approximately 600 seconds. The operator also confirmed the live HTTP block and restored HTTP access.

### Rule 100027

The operator confirmed the corresponding live Active Response scenario for `100027`. The committed evidence should link the Manager correlation alert, Agent `add`/`delete` records, actual firewall state, blocked HTTP attempt and restored HTTP access from the same test cycle.

### Scope and safety

`location=local` means the response is applied on `my-agent`, the endpoint associated with the alert. Single-event rules `100021–100024` do not independently cause the Project 02 firewall block. No broad firewall flush or manual deletion of the Wazuh-managed DROP rule is part of the test procedure.

## 6. Evidence status

The local directory tree supplied for review showed `evidence/README.md` but did not list the Project 02 PNG files. The evidence register therefore lists the required filenames, but binary screenshot presence must be checked before commit.

Do not claim that a screenshot is committed merely because the corresponding test was completed. See `evidence/README.md`.

## 7. Overall assessment

- Custom web detections `100020–100029`: operator-confirmed PASS.
- Fast `wazuh-logtest` regression: 16/16 PASS according to the Project 02 handoff.
- Active Response for `100026` and `100027`: operator-confirmed live PASS.
- Rule `100026` Manager records: `add`, alert `651`, `delete` and alert `652` were visible in the supplied logs.
- Timeout: configured for 600 seconds; the `100026` log interval was approximately 600 seconds.
- Evidence packaging: screenshot files still need to be checked against the evidence register and committed.

**Project 02 lab validation: completed according to the operator's confirmation.** Repository evidence and file synchronization remain the final documentation tasks.
