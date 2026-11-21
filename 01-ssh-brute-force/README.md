# Project 01 — SSH Authentication Attack Detection & Active Response

**Status:** IN PROGRESS — live detection and response have been demonstrated; the current full regression suites and final evidence review remain pending.\
**Last documentation review:** 2026-11-21\
**Platform baseline:** Wazuh `4.14.10-1` (see [Project 00](../00-wazuh-installation-and-agent-deployment/README.md))

## 1. Purpose

This project detects suspicious SSH authentication activity on a monitored Ubuntu endpoint and applies temporary IP containment for selected high-confidence detections. It covers repeated password failures, password spraying, failed public-key authentication, and a successful login correlated with earlier failed authentication attempts.

The project separates four activities that must not be conflated:

1. **Telemetry collection** — SSH events are collected by the Wazuh Agent.
2. **Detection engineering** — the Manager evaluates built-in and project-specific rules.
3. **Containment** — Wazuh Active Response invokes `firewall-drop` for two selected rules.
4. **Validation** — synthetic `wazuh-logtest` cases and live network/firewall tests provide different kinds of evidence.

Platform installation, agent enrollment, package versions and baseline connectivity are maintained in Project 00. Project 01 assumes that baseline is already deployed.

## 2. Lab environment

| System | Role | Address |
|---|---|---|
| Kali | Authorized SSH test source | `192.168.122.112` |
| `my-agent` | Ubuntu endpoint, Wazuh Agent | `192.168.122.208` |
| `my-server` | Wazuh Manager, Indexer and Dashboard | `192.168.122.178` |
| Fedora / trusted network source | Administration and trusted-source test traffic | `192.168.122.1` as observed by the Agent |

The Fedora workstation also has a host-side interface address. The value used by these rules is specifically `192.168.122.1`, the source address observed by the Agent for the trusted traffic in this virtual network. Do not substitute another Fedora interface address without rechecking the actual packet path.

Manager and Agent package versions are maintained in Project 00. The baseline was rechecked there on 2026-11-21.

## 3. Event collection and processing

SSH authentication events are collected from `journald` on `my-agent` and forwarded to `my-server` over Wazuh TCP/1514.

```text
Kali / trusted source
        |
        | SSH authentication attempts
        v
my-agent — sshd / journald / Wazuh Agent
        |
        | Wazuh event forwarding (TCP/1514)
        v
my-server — Wazuh Manager
        |
        +--> built-in SSH rules
        +--> Project 01 rules 100001–100005, 100010
        +--> alerts.json / Wazuh Dashboard
        |
        +--> Active Response for 100002 and 100005
                    |
                    v
              my-agent — firewall-drop
```

The current endpoint uses `journald` for the relevant SSH events. Do not add `/var/log/auth.log` as another input without first verifying that it will not duplicate events.

## 4. Detection rules

Source file: `wazuh/rules/ssh_brute_force_rules.xml`\
Deployed Manager file: `/var/ossec/etc/rules/ssh_brute_force_rules.xml`

| Rule ID | Level | Detection | Implemented condition |
|---|---:|---|---|
| `100010` | 3 | Trusted-source SSH failure | Parent rule `5760`, source `192.168.122.1` |
| `100001` | 6 | SSH soft detection | Three matched `5760` failures from the same source within 120 seconds; trusted source excluded |
| `100002` | 10 | SSH brute force | `frequency=4`, `timeframe=120`, same source IP and same username; trusted source excluded |
| `100003` | 6 | Failed public-key authentication | Parent rule `5716` and message match `Failed publickey` |
| `100004` | 10 | Password spraying | `frequency=4`, `timeframe=300`, same source IP and different usernames; trusted source excluded |
| `100005` | 14 | Successful login after correlated failures | Successful-authentication event correlated with the `authentication_failed` group, same source IP and username, within 300 seconds; trusted source excluded |

### Threshold interpretation

The thresholds above describe the **current rule configuration and the observed behavior of this lab's Wazuh rule tree**. They should not be treated as universal Wazuh defaults.

In the tested five-attempt sequence, rule `100001` replaces the ordinary parent-rule result on attempt 3. Rule `100002` then matches on attempt 5. This is why the effective observed brute-force alert appears on the fifth attempt even though `100002` is configured with `frequency=4`.

Rule `100004` was tested with five different usernames from one source within its 300-second window. Its effective observed alert was on the fifth event. Re-run the relevant boundary tests after changing the rule tree or Wazuh version.

Rule `100005` is **not** a direct child of rule `100001`. Its XML uses `if_group=authentication_success` and `if_matched_group=authentication_failed`, with `same_srcip`, `same_user`, `frequency=3` and `timeframe=300`. The regression fixtures expect the critical alert on the successful-authentication event, not on an earlier failure.

## 5. Active Response

Reference configuration: `wazuh/configs/active-response.xml`\
Command: Wazuh built-in `firewall-drop`\
Execution location: `local` — the endpoint associated with the triggering alert.

| Trigger rule | Action | Timeout |
|---|---|---:|
| `100002` | Temporary block of the alert source IP | 600 seconds |
| `100005` | Temporary block of the alert source IP | 600 seconds |

Rules `100001`, `100003`, `100004` and `100010` do not trigger this response.

The trusted-source fragment is `wazuh/configs/global-whitelist.xml`. It contains one `<white_list>` entry intended to be inserted into the **existing** Manager `<global>` section. It is not a complete replacement for `ossec.conf` or for the existing `<global>` section.

### Active Response acceptance evidence

A successful response test must connect the following observations to the same test cycle:

1. Manager alert for rule `100002` or `100005`.
2. Agent `/var/ossec/logs/active-responses.log` `add` event.
3. Actual firewall DROP rule for the Kali source IP on `my-agent`.
4. A new SSH connection attempt from Kali failing during the block.
5. Agent `delete` event after the configured timeout.
6. A new SSH connection succeeding after the automatic unblock.

Configuration validation and `wazuh-logtest` alone do not prove firewall enforcement.

## 6. Regression and live validation

The regression runner is `tests/regression/test_ssh_rules.py`. It uses `/var/ossec/bin/wazuh-logtest` and must be executed on the Wazuh Manager with the project files available.

Run the 17 fast cases:

```bash
python3 tests/regression/test_ssh_rules.py
```

Run all 23 cases, including the 6 slow time-window cases with real delays:

```bash
python3 tests/regression/test_ssh_rules.py --include-slow
```

`--include-slow` runs the fast suite again and then the slow cases; it is not a slow-only mode. The current runner does not provide a separate slow-only option. Review the complete output before updating `reports/test-results.md`.

`wazuh-logtest` validates rule matching against supplied synthetic events. It does not create a real SSH session, invoke Active Response or modify firewall state. Those are separate live tests.

## 7. Repository map

| Path | Purpose |
|---|---|
| `architecture/architecture.md` | Components, topology, rule design and response architecture |
| `architecture/detection-flow.md` | Event-by-event detection and validation flow |
| `wazuh/rules/ssh_brute_force_rules.xml` | Project-specific Wazuh rules |
| `wazuh/configs/active-response.xml` | Active Response reference fragment |
| `wazuh/configs/global-whitelist.xml` | Trusted-source whitelist fragment |
| `tests/positive/` | Expected detection fixtures |
| `tests/negative/` | Benign and non-correlation fixtures |
| `tests/boundary/` | Threshold and time-window fixtures |
| `tests/regression/test_ssh_rules.py` | 17 fast and 6 delayed regression cases |
| `tests/regression/expected-results.md` | Expected per-scenario behavior |
| `reports/test-results.md` | Recorded validation state and outstanding work |
| `evidence/README.md` | Screenshot register and acceptance criteria |

## 8. Current project status

Live detection and Active Response scenarios for rules `100002` and `100005` have been reported as demonstrated in the lab. The repository contains screenshots for all six custom rules and for the Active Response/firewall workflow.

The project remains **IN PROGRESS** because the current 17-case fast regression suite and 6 slow time-window cases are not recorded as completed in the test report. The screenshots are present, but their contents and cross-correlation should receive a final visual review. There is no committed `regression-summary.png` for a completed 17-fast / 6-slow run.

Do not change the status to `COMPLETE` until the current regression runs pass, their output is recorded, evidence is reviewed and the final Git diff is checked.

## 9. Safety and operational notes

- Run simulations only against systems in the isolated lab or systems for which explicit authorization exists.
- Use a dedicated test account. Do not run password-guessing simulations against an administrator account.
- Keep test wordlists and credentials non-sensitive; never commit real passwords, private keys, `client.keys`, API tokens or certificates containing private keys.
- Confirm the target IP before running `scripts/attack_simulation.sh`. The script is intentionally restricted to the configured lab victim address and lab CIDR.
- `scripts/inspect_firewall.sh` is read-only. Do not use broad firewall flush commands to create or clean up evidence.
- Do not add a second SSH log input without checking for duplicate ingestion.
- Revalidate response timeout and automatic recovery after changing Active Response configuration.
