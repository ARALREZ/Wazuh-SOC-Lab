# Project 01 — SSH Brute Force Detection

**Status:** IN PROGRESS  
**Platform:** Wazuh 4.14.10  
**Last updated:** 2026-11-12

## Overview

This project demonstrates SSH authentication threat detection and automated response using Wazuh.

The lab focuses on detecting repeated failed SSH logins, brute-force activity, password spraying, failed public-key authentication and successful authentication following suspicious failed-login activity. Selected high-severity detections can trigger automated IP blocking through Wazuh Active Response.

The project is an applied detection-engineering scenario. Wazuh platform installation and initial agent deployment are documented separately in Project 00.

## Scope

The implementation includes:

- SSH authentication event collection from the monitored Linux endpoint.
- Custom Wazuh detection rules.
- Correlation of authentication events.
- Trusted-source exclusion.
- Active Response using `firewall-drop`.
- Positive, negative, boundary and regression tests.
- Live validation of detection and firewall response.

## Lab

| System | Role | Address |
|---|---|---|
| Kali | Authorized test host | `192.168.122.112` |
| `my-agent` | Monitored Ubuntu endpoint | `192.168.122.208` |
| `my-server` | Wazuh Manager | `192.168.122.178` |
| Fedora | Administration / trusted source | `192.168.122.1` as observed by the Agent |

Wazuh Manager and Agent use package version `4.14.10-1`.

## Detection and Response

The project contains the following custom rules:

| Rule ID | Purpose |
|---|---|
| `100001` | SSH soft detection |
| `100002` | SSH brute-force detection |
| `100003` | Failed public-key authentication |
| `100004` | SSH password spraying |
| `100005` | Successful login following correlated failed authentication |
| `100010` | Trusted-source identification |

Active Response is configured for rules `100002` and `100005`. Both response blocks use `firewall-drop` with a 600-second timeout.

Detailed rule conditions, thresholds and event correlation are documented in the architecture files. The repository XML files are the configuration references for this project.

## Documentation

- [System architecture](architecture/architecture.md)
- [Detection flow](architecture/detection-flow.md)
- [Test results](reports/test-results.md)
- [Evidence register](evidence/README.md)
- [Expected regression results](tests/regression/expected-results.md)

## Tests

The regression runner is `tests/regression/test_ssh_rules.py`.

It contains 17 fast cases and 6 slow time-window cases. The runner uses the local Wazuh `wazuh-logtest` utility and must be executed on the Wazuh Manager. Run results must be recorded in `reports/test-results.md` only after the corresponding test run has actually completed.

Synthetic `wazuh-logtest` results do not prove live SSH connectivity or firewall enforcement. Those require separate live tests and evidence.

## Current Status

Live detection and Active Response scenarios have been demonstrated for the configured critical rules. The project remains **IN PROGRESS** until the complete 17-case fast suite and 6-case slow suite pass, the evidence register is reviewed, and the final repository diff is checked.

See [Test Results](reports/test-results.md) and [Evidence Register](evidence/README.md) for the current validation record.

## Related Project

[Project 00 — Wazuh Installation and Agent Deployment](../00-wazuh-installation-and-agent-deployment/README.md)
