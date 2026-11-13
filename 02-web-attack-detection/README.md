# Project 02 — Web Attack Detection and Active Response

**Status:** VALIDATED IN LAB — repository evidence reconciliation in progress  
**Last updated:** 2026-11-13  
**Platform:** Wazuh 4.14.10-1

## 1. Overview

Project 02 implements web-attack detection for an Apache2 endpoint monitored by Wazuh. It focuses on identifying suspicious scanner activity and common HTTP attack patterns, correlating related events from the same source IP, and applying automated containment only for the two configured high-confidence correlation rules.

The project is a detection-engineering scenario. A matching request in an Apache access log demonstrates that a pattern was detected; it does **not** prove that the application was vulnerable or that an exploit succeeded.

## 2. Scope

This project covers:

- Apache2 access/error log collection by the already-enrolled Wazuh Agent;
- custom Wazuh rules `100020–100029`;
- scanner, attack-pattern, trusted-source and correlation detections;
- regression tests using `wazuh-logtest`;
- live HTTP test traffic from Kali and the Fedora trusted source;
- Wazuh Active Response using `firewall-drop` for rules `100026` and `100027`;
- evidence, test reporting and scenario-specific architecture.

Wazuh installation, package/version management, server deployment, agent installation/enrollment and baseline agent connectivity are documented in **Project 00**. This project assumes that baseline is already deployed; it does not repeat those procedures.

See [Project 00 — Installation and Agent Deployment](../00-wazuh-installation-and-agent-deployment/README.md).

## 3. Lab topology

| Host | Role in this scenario | Address |
|---|---|---|
| `Kali` | Authorized HTTP test source | `192.168.122.112` |
| `my-agent` | Apache2 endpoint and Wazuh Agent | `192.168.122.208` |
| `my-server` | Wazuh Manager, analysis and alerting | `192.168.122.178` |
| `Fedora` | Administration / trusted HTTP source | `192.168.122.1` as observed by Apache |

The platform baseline and operating-system/package details are maintained in Project 00 to avoid duplicating installation documentation here.

## 4. Event path

```text
Kali / Fedora
     |
     | HTTP requests
     v
my-agent — Apache2
     |
     | /var/log/apache2/access.log
     | /var/log/apache2/error.log
     v
Wazuh Agent
     |
     | Wazuh event forwarding (TCP/1514)
     v
my-server — Wazuh Manager
     |
     +--> Default web decoders/rules
     +--> Custom rules 100020–100029
     +--> alerts.json / Dashboard
     |
     +--> Active Response for 100026 and 100027
              |
              v
       my-agent — firewall-drop
```

## 5. Custom detection rules

The scenario rules are stored in `wazuh/rules/web_attack_rules.xml`. The deployed Manager file used in the lab is `/var/ossec/etc/rules/web_attack_rules.xml`.

| Rule ID | Detection | Level | Purpose |
|---|---|---:|---|
| `100020` | Scanner User-Agent | 6 | Identifies known automated scanner User-Agent strings. |
| `100021` | SQL Injection pattern | 10 | Detects SQL injection indicators in the decoded HTTP request. |
| `100022` | Cross-Site Scripting pattern | 10 | Detects common XSS indicators in the request. |
| `100023` | Path Traversal / LFI | 10 | Detects traversal and sensitive-file path patterns. |
| `100024` | Command Injection pattern | 12 | Detects command-separator and command patterns in the request URI. |
| `100025` | Repeated scanner activity | 9 | Correlates five scanner detections from one source within 120 seconds. |
| `100026` | Multiple web attacks | 12 | Correlates high-severity web-attack events from one source within 180 seconds. |
| `100027` | Scanner followed by attack | 13 | Correlates previous scanner activity with a subsequent exploit-pattern event from the same source within 300 seconds. |
| `100028` | Trusted source | 3 | Labels HTTP activity from Fedora (`192.168.122.1`) as trusted/low severity. |
| `100029` | Suspicious URI patterns | 5 | Detects suspicious URI schemes or PHP-related patterns such as `php://`, `data://` and `expect://`. |

### Correlation semantics

- `100025` is a same-source scanner-volume correlation. The intended threshold is five scanner detections in 120 seconds.
- `100026` means repeated events from the `web_attack_high` group for the same source in 180 seconds. It does **not** require three distinct attack techniques; repeated events of one technique can contribute.
- `100027` requires prior scanner activity and a subsequent supported attack-pattern event from the same source within 300 seconds. The lab regression scenario uses two scanner events followed by an exploit-pattern request.
- `100028` is a project-level trusted-source classification/exclusion. It does not globally suppress every built-in Wazuh rule. Built-in rules can still alert on traffic from the trusted address; those alerts must be distinguished from this project's custom detections.

See [Architecture](architecture/architecture.md), [Detection Flow](architecture/detection-flow.md) and [Expected Regression Results](tests/regression/expected-results.md).

## 6. Active Response

The deployed Manager configuration uses the existing `firewall-drop` command and triggers it only for:

| Trigger | Command | Execution location | Timeout |
|---|---|---|---:|
| `100026` | `firewall-drop` | `local` (the Agent associated with the alert) | 600 seconds |
| `100027` | `firewall-drop` | `local` (the Agent associated with the alert) | 600 seconds |

Single-event detections `100021–100024` do not independently trigger firewall blocking. The reference fragment is `wazuh/configs/active-response.xml`. It documents the project-specific `<active-response>` block; it is **not** a replacement for the complete Manager `ossec.conf`, and the existing `firewall-drop` `<command>` definition must not be duplicated.

## 7. Validation summary

The project handoff records a 16/16 PASS fast `wazuh-logtest` regression run. Live tests for the custom detections and the Active Response scenarios were subsequently confirmed by the operator. The detailed record separates synthetic rule tests from live HTTP/Active Response tests.

`wazuh-logtest` validates rule matching. It does not by itself prove live Apache ingestion, firewall enforcement, or HTTP reachability during a block. Those are separate live-test outcomes recorded in [Test Results](reports/test-results.md).

## 8. Repository contents

```text
02-web-attack-detection/
├── architecture/
│   ├── architecture.md
│   └── detection-flow.md
├── evidence/
│   └── README.md
├── reports/
│   └── test-results.md
├── scripts/
│   ├── attack_simulation.sh
│   ├── cleanup_web.sh
│   └── inspect_firewall.sh
├── tests/
│   ├── boundary/
│   ├── negative/
│   ├── positive/
│   └── regression/
│       ├── expected-results.md
│       └── test_web_rules.py
└── wazuh/
    ├── configs/
    │   ├── active-response.xml
    │   └── agent-localfile.conf
    └── rules/
        └── web_attack_rules.xml
```

The tree above describes the scenario's tracked source layout. Runtime logs, temporary test outputs and screenshots should not be added unless they are sanitized and registered in `evidence/README.md`.

## 9. Limitations

- Detection is based on patterns visible in Apache logs; it is not proof of exploit success or application compromise.
- User-Agent matching can be evaded or spoofed and should not be treated as a standalone indicator of malicious intent.
- Correlation depends on the source IP and configured time window. NAT, proxies and shared egress can affect attribution.
- The trusted-source entry is a static lab address, not a dynamic identity or CIDR trust system.
- Active Response with `location=local` blocks at the monitored Agent. It does not create a perimeter-wide or centralized firewall policy.
- Built-in Wazuh web rules may still alert on trusted-source requests even when this project's custom detections exclude them.

## 10. Related documentation

- [Project 00 — Wazuh Installation and Agent Deployment](../00-wazuh-installation-and-agent-deployment/README.md)
- [Architecture](architecture/architecture.md)
- [Detection Flow](architecture/detection-flow.md)
- [Test Results](reports/test-results.md)
- [Evidence Register](evidence/README.md)
- [Expected Regression Results](tests/regression/expected-results.md)
