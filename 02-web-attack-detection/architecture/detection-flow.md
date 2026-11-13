# Detection Flow — Project 02: Web Attack Detection

## 1. Event source

The monitored web endpoint is `my-agent` (`192.168.122.208`). Apache2 receives HTTP requests from the authorized test host Kali (`192.168.122.112`) and the administration/trusted source Fedora (`192.168.122.1`).

Apache writes request telemetry to `/var/log/apache2/access.log` and error events to `/var/log/apache2/error.log`.

## 2. Collection and forwarding

The Wazuh Agent on `my-agent` monitors the Apache logs using the Apache log format and forwards the events to `my-server` (`192.168.122.178`) over the existing Wazuh transport (TCP/1514).

Agent installation, enrollment and baseline connectivity are covered by Project 00. Project 02 does not reinstall or re-enroll the Agent.

## 3. Decoding and default Wazuh rules

The Manager decodes Apache access-log records and evaluates the applicable built-in web rules. The custom Project 02 rules use these decoded events and, where appropriate, native Wazuh web detections as parent matches.

A request returning HTTP 200 is still only a logged request. An alert for an attack pattern does not mean the application executed the supplied content or that data was accessed.

## 4. Custom rule evaluation

| Rule ID | Function | Expected role |
|---|---|---|
| `100020` | Scanner User-Agent | Detect a known scanner name in the request User-Agent. |
| `100021` | SQL Injection | Detect a SQLi pattern in the request. |
| `100022` | XSS | Detect an XSS pattern in the request. |
| `100023` | Path Traversal / LFI | Detect traversal or sensitive-file path patterns. |
| `100024` | Command Injection | Detect command-separator / command patterns in the request URI. |
| `100025` | Repeated scanner | Correlate five scanner detections from the same source in 120 seconds. |
| `100026` | Multiple web attacks | Correlate high-severity web attack events from the same source in 180 seconds. |
| `100027` | Scanner followed by exploit | Correlate previous scanner activity with a subsequent supported attack event from the same source in 300 seconds. |
| `100028` | Trusted source | Mark Fedora HTTP traffic from `192.168.122.1` as low severity. |
| `100029` | Suspicious URI | Identify suspicious URI schemes and PHP-related patterns. |

### Important interpretation

- `100026` correlates repeated events in the `web_attack_high` group; it does not require unique attack categories.
- `100027` is same-source and order-sensitive: scanner event(s) must precede the supported attack event.
- `100028` applies to the custom Project 02 logic. It does not disable all native Wazuh web rules for the trusted source.

## 5. Active Response decision

Only the two correlation rules are configured for automated containment:

```text
100026 ─┐
       ├──> firewall-drop on my-agent, timeout 600 seconds
100027 ─┘
```

Single attack-pattern alerts `100021–100024` do not independently execute `firewall-drop`.

The response is expected to generate an `add` event on the Agent, create the source-IP DROP rule, and issue a `delete` event when the 600-second timeout expires. Live HTTP reachability must be checked separately during the block and after expiry.

## 6. Validation path

1. Confirm the HTTP request appears in Apache's access log.
2. Confirm the Agent forwards the event and the Manager decodes it as web access telemetry.
3. Confirm the expected custom rule ID and level in `alerts.json`.
4. For `100025–100027`, verify the correlation conditions (source IP and event order/window).
5. For `100026` or `100027`, verify Active Response `add` on the Agent.
6. Verify the actual firewall DROP rule and failed HTTP request from Kali during the block.
7. Verify Active Response `delete` after timeout and restored HTTP connectivity.

`wazuh-logtest` is used for rule-matching and regression validation only. It does not execute Active Response or prove network blocking.
