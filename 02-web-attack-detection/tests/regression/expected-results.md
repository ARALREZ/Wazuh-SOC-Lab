# Project 02 — Expected Regression Results

**Target platform:** Wazuh 4.14.10-1  
**Manager:** `192.168.122.178`  
**Agent / Apache2:** `192.168.122.208`  
**Attacker test source:** `192.168.122.112`  
**Trusted HTTP source:** `192.168.122.1`

This file describes expected behavior. It is not a substitute for the actual test output. Completed execution belongs in `reports/test-results.md`.

## 1. Expected custom rule levels

| Rule ID | Level | Description |
|---|---:|---|
| `100020` | 6 | Scanner User-Agent |
| `100021` | 10 | SQL Injection |
| `100022` | 10 | Cross-Site Scripting |
| `100023` | 10 | Path Traversal / LFI |
| `100024` | 12 | Command Injection |
| `100025` | 9 | Repeated scanner correlation |
| `100026` | 12 | Multiple high-severity web attacks |
| `100027` | 13 | Scanner followed by attack |
| `100028` | 3 | Trusted source |
| `100029` | 5 | Suspicious URI patterns |

## 2. Positive scenarios

| Scenario | Input / condition | Expected custom rule |
|---|---|---|
| Scanner User-Agent | Known scanner User-Agent such as `Nikto/2.1.6` | `100020` |
| SQL Injection | URL-encoded `UNION SELECT` pattern | `100021` |
| XSS | URL-encoded `<script>` / script pattern | `100022` |
| Path Traversal | URL-encoded `../` and sensitive-file path | `100023` |
| Command Injection | URL-encoded command separator and command token, e.g. `%3Bid` | `100024` |
| Repeated scanner | Five scanner events from the same source within 120 seconds | `100020`, then `100025` |
| Multiple web attacks | Three qualifying high-severity attack events from the same source within 180 seconds | `100026` |
| Repeated same technique | Three qualifying SQLi events from the same source within 180 seconds | `100026` |
| Scanner then attack | Two scanner events followed by a supported exploit-pattern event from the same source within 300 seconds | `100020`, `100027` (and the applicable single-event attack rule) |
| Trusted benign request | Normal HTTP request from `192.168.122.1` | `100028` |
| Suspicious URI | URI containing a pattern such as `php://`, `data://`, `expect://`, `base64_decode` or `eval(` | `100029` |

## 3. Negative and boundary scenarios

| Scenario | Expected behavior |
|---|---|
| Four scanner events from one source in 120 seconds | No `100025` correlation |
| Five scanner events split across different source IPs | No cross-source `100025` correlation |
| Two high-severity attack events from one source | No `100026` correlation |
| High-severity attacks from different source IPs | No cross-source `100026` correlation |
| One scanner event followed by an exploit-pattern event | No `100027` correlation |
| Two scanner events without a later exploit-pattern event | No `100027` correlation |
| Scanner events and exploit-pattern event from different source IPs | No `100027` correlation |
| Normal benign request from Fedora | `100028` low-severity trusted-source classification; no custom high-severity Project 02 rule |
| Attack-pattern requests from Fedora | No custom Project 02 attack/correlation rule where the trusted-source exclusion is configured; built-in Wazuh rules may still alert |
| Ordinary query parameters / ordinary 404 | No custom attack rule unless a defined pattern is actually present |

## 4. Correlation semantics and caveats

### Rule 100025

The intended threshold is five scanner detections within 120 seconds, correlated by source IP. Four events are below threshold. Events from different IPs must not be combined.

### Rule 100026

The semantic requirement is repeated qualifying events from the `web_attack_high` group for the same source IP within 180 seconds. It does not require distinct attack categories. The deployed lab configuration used `frequency=4`; observed tests showed the correlation alert on the third high-severity event. Preserve the observed behavior and do not simplify the threshold explanation to “three different techniques”.

### Rule 100027

The rule is order-sensitive: scanner activity must exist before the supported exploit-pattern event. The source IP must match. The lab tests distinguish one scanner plus exploit from two scanners plus exploit, and verify that different source IPs do not correlate.

### Trusted source

The custom trusted-source logic is scoped to Project 02 rules. It does not disable the built-in Wazuh web rules for Fedora. A native alert such as `31508` or `31106` is not a failure of the custom rule exclusion by itself; classify the rule origin correctly.

## 5. Active Response expectations

| Trigger | Command | Location | Timeout |
|---|---|---|---:|
| `100026` | `firewall-drop` | `local` | 600 seconds |
| `100027` | `firewall-drop` | `local` | 600 seconds |

Rules `100021–100024` do not independently trigger firewall blocking. A rule-matching test does not prove Active Response. Live validation must separately confirm the Agent execution log, firewall DROP, blocked HTTP attempt, automatic `delete` and restored HTTP access.

## 6. Regression inventory

The Project 02 handoff records 16 fast scenarios:

1. Scanner detection.
2. SQL Injection.
3. XSS.
4. Path Traversal.
5. Command Injection.
6. Trusted-source benign request.
7. Suspicious URI.
8. Four scanner events below threshold.
9. Five scanner events reaching `100025`.
10. Two high-severity events below `100026` threshold.
11. Three different high-severity events reaching `100026`.
12. Three SQLi events also reaching `100026`.
13. One scanner plus exploit without `100027`.
14. Two scanners plus exploit reaching `100027`.
15. Different source IPs do not satisfy `100027`.
16. Scanner-only activity does not satisfy `100027`.

The handoff records 16/16 PASS for that fast suite. Real elapsed-time window-expiry tests and extended trusted-source negative cases are separate coverage and must not be inferred from the fast run.
