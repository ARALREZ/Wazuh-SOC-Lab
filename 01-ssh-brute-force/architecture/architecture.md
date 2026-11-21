# Architecture — SSH Authentication Detection & Active Response

## 1. Design objective

Project 01 monitors SSH authentication activity on one Ubuntu endpoint, evaluates the events centrally with Wazuh and temporarily blocks the source IP for two selected high-confidence detections.

The architecture separates telemetry collection, rule evaluation, alert generation, response execution and validation. A detection alert is not itself proof that the response executed.

## 2. Lab topology

| System | Role | Operating system | Address |
|---|---|---|---|
| Kali | Authorized test client | Kali Linux | `192.168.122.112` |
| `my-agent` | Monitored endpoint / Wazuh Agent | Ubuntu 24.04.5 LTS | `192.168.122.208` |
| `my-server` | Wazuh Manager, Indexer and Dashboard | Ubuntu 24.04.5 LTS | `192.168.122.178` |
| Fedora / trusted source | Administration and trusted-source traffic | Fedora | `192.168.122.1` as observed by the Agent |

Project 00 is the source of truth for platform installation and package versions. The baseline recorded there is Wazuh `4.14.10-1` on the Manager and Agent.

`192.168.122.1` is the source address observed by the Agent for the trusted Fedora-originated traffic. It is not interchangeable with the Fedora workstation's other interface address.

## 3. Component and event-flow architecture

```text
+-----------------------+
| Kali test client      |
| 192.168.122.112       |
+-----------+-----------+
            |
            | SSH authentication attempts
            v
+-----------------------+
| my-agent              |
| 192.168.122.208       |
| Ubuntu / sshd         |
| journald / Wazuh Agent|
+-----------+-----------+
            |
            | Wazuh event forwarding
            | TCP/1514
            v
+-----------------------+
| my-server             |
| 192.168.122.178       |
| Wazuh Manager         |
| built-in + custom rules
+-----------+-----------+
            |
            +------> alerts.json / Dashboard
            |
            +------> Active Response for 100002 or 100005
                              |
                              v
                    my-agent — firewall-drop
```

## 4. Event collection

SSH authentication messages are collected from `journald` on `my-agent` by the Wazuh Agent and forwarded to `my-server` over TCP/1514.

The lab already uses journald for the relevant SSH events. Do not add `/var/log/auth.log` as a second input unless the endpoint's current configuration has been checked and duplicate ingestion has been ruled out.

## 5. Detection layer

Project rules are maintained separately from `local_rules.xml`:

```text
Repository:    wazuh/rules/ssh_brute_force_rules.xml
Manager path:  /var/ossec/etc/rules/ssh_brute_force_rules.xml
```

The Manager loads the dedicated file through its configured rules directory.

| Rule ID | Level | Detection | Rule logic |
|---|---:|---|---|
| `100010` | 3 | Trusted-source failure | Child of `5760`; source IP equals `192.168.122.1` |
| `100001` | 6 | Soft brute-force signal | Three `5760` matches from the same source in 120 seconds; trusted source excluded |
| `100002` | 10 | Confirmed brute force | `if_matched_sid=5760`, `frequency=4`, `timeframe=120`, `same_srcip`, `same_user`; trusted source excluded |
| `100003` | 6 | Failed public-key authentication | Child of `5716` with `Failed publickey` message match |
| `100004` | 10 | Password spraying | `if_matched_sid=5760`, `frequency=4`, `timeframe=300`, `same_srcip`, `different_user`; trusted source excluded |
| `100005` | 14 | Successful login after correlated failures | Current event belongs to `authentication_success`; prior matches belong to `authentication_failed`; same source and username; 300-second correlation window; trusted source excluded |

### 5.1 Effective threshold behavior

The effective attempt number is determined by the complete loaded rule tree, not by reading a single `frequency` attribute in isolation.

For the current five-failure fixture, the observed sequence is:

| Attempt | Observed result |
|---:|---|
| 1 | Built-in rule `5760` |
| 2 | Built-in rule `5760` |
| 3 | Project rule `100001`, level 6 |
| 4 | Built-in rule `5760` |
| 5 | Project rule `100002`, level 10 |

Rule `100001` consumes the third event as the higher-level custom match in this observed rule evaluation. The current `100002` configuration therefore reaches its expected match on attempt 5 in this fixture. This behavior was tested on the lab's Wazuh `4.14.10-1` ruleset and must be revalidated after rule or version changes.

Rule `100004` is configured with `frequency=4` and `different_user`. The current positive fixture uses five usernames and expects the spray alert on event 5. The boundary fixtures test four usernames and a single repeated username.

Rule `100005` is deliberately group-based. Its XML does not use `if_matched_sid=100001`; it correlates a current successful-authentication event with prior failed-authentication group matches for the same source IP and username. The regression suite verifies that the level-14 alert occurs on the successful event.

## 6. Trusted-source handling

The source `192.168.122.1` is identified by rule `100010` and excluded explicitly from the brute-force and spraying rules. The same address is also represented in `wazuh/configs/global-whitelist.xml` for the Manager's global whitelist.

`global-whitelist.xml` is a fragment containing a single `<white_list>` entry. Insert it into the existing `<global>` section without replacing or deleting other whitelist entries. A project-specific rule exclusion and a global Active Response whitelist serve different purposes; verify both in the deployed configuration.

## 7. Response layer

The reference file `wazuh/configs/active-response.xml` contains two distinct Active Response blocks:

| Trigger | Command | Location | Timeout |
|---|---|---|---:|
| `100002` | `firewall-drop` | `local` | 600 seconds |
| `100005` | `firewall-drop` | `local` | 600 seconds |

In this configuration, `local` means the response runs on the endpoint associated with the triggering alert — `my-agent` in this scenario. Wazuh's `firewall-drop` handles the temporary block and its timeout-based delete operation.

No firewall response is configured for `100001`, `100003`, `100004` or `100010`.

The reference XML is a configuration fragment. Merge it into the existing Manager configuration and preserve unrelated response definitions. Do not replace the complete `/var/ossec/etc/ossec.conf` with a project fragment.

## 8. Validation architecture

Validation is divided into independent layers:

1. XML parsing and Manager configuration validation (`wazuh-analysisd -t`).
2. Active Response configuration validation (`wazuh-execd -t`, where applicable).
3. Individual synthetic event checks with `wazuh-logtest`.
4. The 17-case fast regression suite.
5. The 6 delayed time-window cases.
6. Live SSH authentication tests from Kali.
7. Manager alert, Agent `active-responses.log`, firewall state and client-side connectivity checks.

`wazuh-logtest` validates rule matching. It does not create a network connection, invoke Active Response or prove the firewall blocked traffic.

For Active Response, acceptance requires a correlated `add`, actual DROP rule, blocked new SSH connection, automatic `delete` and successful new connection after the timeout. A configuration test or a screenshot of the alert alone is insufficient.

## 9. Current validation state

The project report records prior live detection and Active Response demonstrations for rules `100002` and `100005`. It also records individual synthetic rule tests. The current 17-case fast suite and 6 delayed cases are still marked pending in `reports/test-results.md`; historical results from an older runner must not be reused as the current suite result.

The screenshot files are present in `evidence/`. Their presence does not replace final verification that timestamps, rule IDs, source addresses and firewall events belong to the same test cycle.

## 10. Related files

- Detection rules: `wazuh/rules/ssh_brute_force_rules.xml`
- Active Response fragment: `wazuh/configs/active-response.xml`
- Global whitelist fragment: `wazuh/configs/global-whitelist.xml`
- Regression runner: `tests/regression/test_ssh_rules.py`
- Expected outcomes: `tests/regression/expected-results.md`
- Actual test report: `reports/test-results.md`
- Evidence register: `evidence/README.md`
