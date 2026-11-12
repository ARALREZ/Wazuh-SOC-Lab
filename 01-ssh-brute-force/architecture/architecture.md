# Architecture — SSH Brute Force Detection & Active Response

## 1. Purpose

Project 01 implements an SSH authentication detection and response scenario using Wazuh. It monitors SSH authentication activity on a Linux endpoint, evaluates events with default and custom Wazuh rules, and applies automated IP containment for selected high-severity detections.

The design separates event collection, central analysis, alert generation, response execution and validation.

## 2. Lab Topology

| System | Role | Operating system | Address |
|---|---|---|---|
| Kali | Authorized attacker / test host | Kali Linux | `192.168.122.112` |
| `my-agent` | Monitored endpoint / Wazuh Agent | Ubuntu 24.04.5 LTS | `192.168.122.208` |
| `my-server` | Wazuh Manager | Ubuntu 24.04.5 LTS | `192.168.122.178` |
| Fedora | Administration / trusted source | Fedora | `192.168.122.1` as observed by Agent |

The Fedora address shown above is the source address observed by the Agent for Fedora-originated SSH traffic. Do not replace it with another Fedora interface address unless the actual network path has been rechecked.

Wazuh Manager and Agent package versions in the validated lab baseline are `4.14.10-1`.

## 3. Component Architecture

```text
+-----------------------+
| Kali test host        |
| 192.168.122.112       |
+-----------+-----------+
            |
            | SSH authentication attempts
            v
+-----------------------+
| my-agent              |
| 192.168.122.208       |
| Ubuntu / Wazuh Agent  |
| journald / SSH        |
+-----------+-----------+
            |
            | Wazuh event forwarding
            | TCP/1514
            v
+-----------------------+
| my-server             |
| 192.168.122.178       |
| Wazuh Manager         |
| Default + custom rules|
+-----------+-----------+
            |
            | Alerts
            v
+-----------------------+
| Wazuh Dashboard       |
| Detection visibility  |
+-----------------------+

For rule 100002 or 100005:

Wazuh Manager -- Active Response --> my-agent firewall
```
## 4. Event Collection

SSH authentication events are collected from journald on my-agent by the Wazuh Agent and forwarded to my-server over TCP port 1514.

The current deployment already collects the relevant SSH events through journald. Do not add /var/log/auth.log as a second input without first checking whether it would duplicate the same events.

## 5. Detection Layer

The project rules are maintained in:
```text
wazuh/rules/ssh_brute_force_rules.xml
```
The deployed Manager copy is:
```text
/var/ossec/etc/rules/ssh_brute_force_rules.xml
```
The Manager loads the project rules through its configured etc/rules directory. The project file is kept separate from local_rules.xml.

| Rule ID | Detection | Level | High-level condition |
|---|---|---:|---|
| `100010` | Trusted source | 3 | Failed SSH authentication from `192.168.122.1` |
| `100001` | SSH soft detection | 6 | 3 matching failed-password events from the same source IP within 120 seconds |
| `100002` | SSH brute force | 10 | `frequency=4`, `timeframe=120`, same source IP and same username |
| `100003` | Failed public-key authentication | 6 | Parent rule `5716` and `Failed publickey` match |
| `100004` | Password spraying | 10 | 5 failed events from the same source IP using different usernames within 300 seconds |
| `100005` | Successful login after correlated failures | 14 | Successful authentication correlated with the `authentication_failed` group, same source IP and username, within 300 seconds |

Rule 100005 uses group-based failed-authentication correlation. It is not configured as a direct if_matched_sid=100001 dependency.
Threshold behavior of rules 100001 and 100002
Rule 100001 uses frequency=3 and timeframe=120.

Rule 100002 uses frequency=4 and timeframe=120, with same_srcip and same_user constraints. In the validated five-attempt sequence, the observed results were:

| Attempt | Result |
|---:|---|
| 1 | Default rule `5760` |
| 2 | Default rule `5760` |
| 3 | Custom rule `100001`, level 6 |
| 4 | Default rule `5760` |
| 5 | Custom rule `100002`, level 10 |

This observed sequence is the reason the project documentation describes the custom brute-force alert on the fifth attempt. Do not change the threshold without repeating the relevant tests.

## 6. Response Layer

The Manager has two separate Active Response blocks in the project configuration reference:
```text
wazuh/configs/active-response.xml
```

| Trigger rule | Command | Location | Timeout |
|---|---|---|---:|
| `100002` | `firewall-drop` | `local` | 600 seconds |
| `100005` | `firewall-drop` | `local` | 600 seconds |

Both response blocks use a timeout of 600 seconds. local means that the response is executed on the endpoint associated with the triggering alert.

Rules 100001, 100003, 100004 and 100010 do not trigger firewall-drop.

The trusted source 192.168.122.1 is excluded from the relevant brute-force and password-spraying correlation and is listed in the Manager Active Response whitelist. The project file wazuh/configs/global-whitelist.xml is only a fragment to be merged into the existing <global> configuration section; it is not a replacement for that section.
Live validation status
- Rule 100002: live detection and firewall-drop BLOCK/DELETE have been demonstrated in the lab.
- Rule 100005: the operator confirmed the live level-14 alert, firewall BLOCK, automatic DELETE after the configured 600-second timeout, and restored SSH access from Kali.
The evidence register lists the screenshots associated with these scenarios. The complete automated regression suite is a separate validation requirement and must not be marked as passed until it has actually completed.

## 7. Validation Architecture

The project uses multiple validation layers:
1. XML parsing and Wazuh Manager configuration validation.
2. Individual synthetic event tests with wazuh-logtest.
3. Fast positive, negative and boundary regression cases (17 cases).
4. Slow time-window regression cases (6 cases).
5. Live SSH tests from the Kali test host.
6. Active Response and firewall-state verification on my-agent.
wazuh-logtest verifies rule matching against supplied events. It does not establish a live SSH connection, execute Active Response or prove a firewall block.

## 8. Related Project Files

Detection rules: `wazuh/rules/ssh_brute_force_rules.xml`
Active Response reference: `wazuh/configs/active-response.xml`
Whitelist fragment: `wazuh/configs/global-whitelist.xml`
Regression runner: `tests/regression/test_ssh_rules.py`
Expected results: `tests/regression/expected-results.md`
Test report: `reports/test-results.md`
Evidence register: `evidence/README.md`
