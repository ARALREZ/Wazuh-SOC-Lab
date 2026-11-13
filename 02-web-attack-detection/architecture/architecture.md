# Architecture — Project 02: Web Attack Detection and Active Response

## 1. Purpose and boundary

Project 02 adds scenario-specific web-attack detection to the Wazuh deployment documented in Project 00. It collects Apache2 logs from `my-agent`, analyzes HTTP request patterns on `my-server`, correlates selected events from the same source IP, and applies local firewall containment for the two configured correlation rules.

Project 00 remains the source of truth for Wazuh installation, package versions, enrollment, baseline connectivity and initial platform validation. This document covers only the web-monitoring scenario.

## 2. Lab topology

| Host | Role | Address |
|---|---|---|
| Kali | Authorized HTTP test source | `192.168.122.112` |
| `my-agent` | Apache2 + Wazuh Agent | `192.168.122.208` |
| `my-server` | Wazuh Manager | `192.168.122.178` |
| Fedora | Administration / trusted HTTP source | `192.168.122.1` as observed by Apache |

## 3. Component architecture

```text
+---------------------------+
| Kali                      |
| 192.168.122.112            |
| HTTP test requests         |
+-------------+-------------+
              |
              | HTTP / TCP 80
              v
+---------------------------+
| my-agent                  |
| 192.168.122.208            |
| Apache2                   |
| access.log / error.log    |
| Wazuh Agent               |
+-------------+-------------+
              |
              | Wazuh event forwarding / TCP 1514
              v
+---------------------------+
| my-server                 |
| 192.168.122.178            |
| Wazuh Manager             |
| Default web rules         |
| Custom rules 100020–100029|
| alerts.json               |
+-------------+-------------+
              |
              +-----------------------> Wazuh Dashboard
              |
              | Active Response: 100026 / 100027
              v
+---------------------------+
| my-agent firewall         |
| firewall-drop             |
| 600-second timeout        |
+---------------------------+

Fedora 192.168.122.1 ---- HTTP ----> Apache2 on my-agent
```

## 4. Log collection

Apache2 runs on `my-agent` and writes HTTP events to:

- `/var/log/apache2/access.log`
- `/var/log/apache2/error.log`

The Wazuh Agent monitors these files using the Apache log format, as represented by `wazuh/configs/agent-localfile.conf`. The Agent forwards decoded events to the Manager. The baseline Agent installation/enrollment and event-forwarding setup are documented in Project 00 and are not repeated here.

The Manager-side custom rules are stored in the lab at:

```text
/var/ossec/etc/rules/web_attack_rules.xml
```

The repository reference is:

```text
wazuh/rules/web_attack_rules.xml
```

The Manager loads the custom rule directory through its existing `ossec.conf` ruleset configuration. Do not replace the complete `ossec.conf` with a project fragment.

## 5. Detection layer

The custom rule range is `100020–100029`.

| Rule | Level | Function | Correlation / matching summary |
|---|---:|---|---|
| `100020` | 6 | Automated scanner User-Agent | Detects recognized scanner names in web request telemetry. |
| `100021` | 10 | SQL Injection | Uses the applicable Wazuh web SQL-injection event as a parent and excludes the trusted source. |
| `100022` | 10 | XSS | Uses the applicable Wazuh XSS event as a parent and excludes the trusted source. |
| `100023` | 10 | Path Traversal / LFI | Uses a web-access event plus URI/path patterns and excludes the trusted source. |
| `100024` | 12 | Command Injection | Detects command/separator patterns in the request URI and excludes the trusted source. |
| `100025` | 9 | Repeated scanner activity | Five scanner matches from one source IP in 120 seconds. |
| `100026` | 12 | Multiple web attacks | Repeated `web_attack_high` events from the same source in 180 seconds. |
| `100027` | 13 | Scanner followed by exploit-pattern request | Prior scanner activity and a subsequent supported attack event from the same source within 300 seconds. |
| `100028` | 3 | Trusted source | Identifies HTTP requests from `192.168.122.1` as trusted / low severity. |
| `100029` | 5 | Suspicious URI | Detects URI schemes and PHP-related request patterns such as `php://`, `data://`, `expect://`, `base64_decode` and `eval(`. |

### Correlation design notes

**100025 — scanner volume**  
The rule is intended to alert after five scanner detections from the same source within 120 seconds. Events from different source IPs must not be combined.

**100026 — repeated high-severity web attacks**  
The correlation is based on the `web_attack_high` group and a shared source IP. It does not prove that the events represent distinct attack techniques. Repeated SQL injection events can satisfy the correlation as well.

The deployed lab configuration used `frequency=4` with `timeframe=180`; the handoff records an observed correlation on the third high-severity event. Preserve this observed behavior in documentation rather than interpreting the `frequency` attribute as a simple user-facing event count.

**100027 — scanner then attack**  
The rule requires a previous scanner match and a current supported attack event from the same source in the configured 300-second window. The documented regression cases distinguish one scan plus exploit from two scans plus exploit, and check that different source IPs do not correlate.

**100028 — trusted source semantics**  
The custom rule is a project-level low-severity classification and the custom attack rules exclude the trusted Fedora IP where configured. This is not a global Wazuh whitelist: native Wazuh rules may still generate alerts for requests from `192.168.122.1`. For example, a built-in scanner User-Agent rule or a built-in HTTP attack-response rule can still alert. Such events must be identified as native rules, not misreported as custom Project 02 detections.

## 6. Active Response layer

The Manager's existing `firewall-drop` command is reused. Project 02 adds a dedicated Active Response block for rules `100026` and `100027` only.

| Trigger | Command | Location | Timeout |
|---|---|---|---:|
| `100026` | `firewall-drop` | `local` | 600 seconds |
| `100027` | `firewall-drop` | `local` | 600 seconds |

`local` means that the response is executed on the endpoint associated with the triggering alert — in this scenario, `my-agent`.

The individual detections `100021–100024` do not independently trigger a firewall block. This reduces the risk of blocking a source based on one isolated pattern match.

The file `wazuh/configs/active-response.xml` is a project configuration fragment. It documents the two Project 02 `<active-response>` blocks; it is not a complete replacement for `/var/ossec/etc/ossec.conf`. The `firewall-drop` command is already defined in the Manager configuration and must not be duplicated.

## 7. Validation layers

1. Manager rule syntax validation (`wazuh-analysisd -t`).
2. Active Response configuration validation (`wazuh-execd -t`) on Manager and Agent.
3. Synthetic event matching with `wazuh-logtest`.
4. Fast regression cases for positive, negative and correlation behavior.
5. Live HTTP requests from Kali and Fedora.
6. Manager alert verification in `alerts.json`.
7. Agent Active Response execution log and firewall inspection.
8. HTTP connectivity verification during a block and after automatic timeout expiry.

A `wazuh-logtest` PASS is not evidence of live Apache ingestion or firewall enforcement. The test report distinguishes these layers.

## 8. Related files

- Rules: `wazuh/rules/web_attack_rules.xml`
- Agent log collection reference: `wazuh/configs/agent-localfile.conf`
- Active Response reference: `wazuh/configs/active-response.xml`
- Regression runner: `tests/regression/test_web_rules.py`
- Expected outcomes: `tests/regression/expected-results.md`
- Actual results: `reports/test-results.md`
- Evidence register: `evidence/README.md`
