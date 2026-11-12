# Project 01 — SSH Brute Force Detection & Automated Response

**Status:** IN PROGRESS  
**Last updated:** 2026-11-12  
**Platform:** Wazuh 4.14.10

## 1. Project Objective

This project implements an SSH authentication threat-detection scenario
for a Linux endpoint monitored by Wazuh.

It demonstrates:

- SSH authentication event collection through journald.
- Custom Wazuh rule engineering.
- SSH brute-force detection.
- Public-key authentication failure detection.
- Password-spraying detection.
- Correlation of failed authentication and subsequent successful login.
- Trusted-source exclusion.
- Automated containment using Wazuh Active Response.
- Positive, negative, boundary and regression testing.

The project is focused on detection engineering and response validation.
It is not an installation guide for the Wazuh platform.

## 2. Scope and Infrastructure

| Host | Role | Address |
|---|---|---|
| Kali | Authorized attacker / test host | `192.168.122.112` |
| `my-agent` | Ubuntu 24.04.5 LTS / Wazuh Agent | `192.168.122.208` |
| `my-server` | Ubuntu 24.04.5 LTS / Wazuh Manager | `192.168.122.178` |
| Fedora | Administration / trusted source | `192.168.122.1` as observed by Agent |

Wazuh Manager and Agent package versions:
`4.14.10-1`.

Filebeat version on the Manager:
`7.10.2-2`.

The Fedora host address used by the trusted-source rule is the
source address actually observed by the Agent during SSH communication.
Do not substitute `172.16.62.231` without re-verifying the network path.

## 3. Prerequisites

Before running this scenario:

1. Complete the Wazuh platform deployment documented in
   [Project 00](../00-wazuh-installation-and-agent-deployment/README.md).
2. Confirm that `my-agent` is connected to `my-server`.
3. Confirm that SSH events are visible in the Agent's journald.
4. Confirm that the Manager receives events from the Agent over TCP/1514.
5. Use only dedicated, non-privileged lab test accounts.
6. Restrict attack simulation to the isolated lab network.

The Agent already collects SSH authentication events from journald.
Do not add `/var/log/auth.log` as another source without first checking
whether that would duplicate events.

## 4. Architecture

```text
Kali attacker
192.168.122.112
      |
      | SSH authentication attempts
      v
my-agent
192.168.122.208
      |
      | journald -> Wazuh Agent -> TCP/1514
      v
my-server
192.168.122.178
      |
      | Default SSH rules + Project 01 rules
      v
Wazuh alerts / Dashboard
      |
      +--> 100001: Soft Detection
      +--> 100002: Brute Force
      +--> 100003: Public Key Failure
      +--> 100004: Password Spraying
      +--> 100005: Successful Login After Brute Force
      +--> 100010: Trusted IP
      |
      +--> Active Response for 100002 / 100005
                    |
                    v
               my-agent firewall
```

Detailed documentation:

- [System architecture](architecture/architecture.md)
- [Detection flow](architecture/detection-flow.md)

## 5. Custom Detection Rules

Source file:

`wazuh/rules/ssh_brute_force_rules.xml`

Deployed Manager file:

`/var/ossec/etc/rules/ssh_brute_force_rules.xml`

The Manager loads the project rules through its configured
`etc/rules` rule directory. The project file is kept separate from
`local_rules.xml`.

| ID | Detection | Level | Logic |
|---|---|---:|---|
| 100001 | SSH Soft Detection | 6 | 3 matching failed-password events / 120 s |
| 100002 | SSH Brute Force | 10 | `frequency=4`, `timeframe=120`, same source IP |
| 100003 | Failed Public Key | 6 | Parent rule 5716 and `Failed publickey` |
| 100004 | Password Spraying | 10 | 5 different usernames, same source IP / 300 s |
| 100005 | Successful Login After Brute Force | 14 | Successful login correlated with earlier 100001 activity; same source IP and user / 300 s |
| 100010 | Trusted IP | 3 | Failed SSH authentication from `192.168.122.1` |

### Important threshold detail: 100002

Rule 100002 intentionally uses `frequency=4`, not 5.

Rule 100001 matches the third failed-password event. In the verified
five-attempt sequence, the custom 100001 alert is produced on attempt
3, and rule 100002 is produced on attempt 5.

The tested sequence is:

| Attempt | Result |
|---:|---|
| 1 | Default rule 5760 |
| 2 | Default rule 5760 |
| 3 | Custom rule 100001 |
| 4 | Default rule 5760 |
| 5 | Custom rule 100002 |

Do not change the threshold without repeating the regression tests.

## 6. Active Response Policy

The Manager has two separate Project 01 Active Response blocks:

| Trigger | Command | Location | Timeout |
|---|---|---|---:|
| 100002 | `firewall-drop` | `local` | 600 seconds |
| 100005 | `firewall-drop` | `local` | 600 seconds |

`local` means that the response is executed on the endpoint
associated with the triggering alert.

Rules 100001, 100003, 100004 and 100010 do not trigger
`firewall-drop`.

The trusted source `192.168.122.1` is excluded from brute-force
and password-spraying correlation and is included in the Manager's
Active Response whitelist.

**Verification status:** The configuration is deployed, but a
successful live firewall block has not yet been demonstrated.
Active Response must remain NOT VERIFIED until the Manager alert,
Agent execution log and actual firewall state are correlated.

The repository file `wazuh/configs/active-response.xml` documents
the two Project 01 blocks.

The file `wazuh/configs/global-whitelist.xml` is a configuration
fragment containing only the Project 01 whitelist addition.
Insert that entry into the existing whitelist-containing `<global>`
section. Do not replace the Manager's full configuration section.

## 7. Test Strategy

Tests are organized into four fixture categories:

- `tests/positive/` — scenarios expected to trigger custom rules.
- `tests/negative/` — scenarios expected not to trigger specified rules.
- `tests/boundary/` — event-count and time-window boundaries.
- `tests/regression/` — automated rule regression runner and expected results.

The regression runner must be executed on the Wazuh Manager because
it calls `/var/ossec/bin/wazuh-logtest`.

### Regression deployment

From Fedora, in the Project 01 directory:

```bash
tar -czf /tmp/wazuh-project01-tests.tar.gz tests

scp /tmp/wazuh-project01-tests.tar.gz \
  aralrez@192.168.122.178:/tmp/
```

On the Manager:

```bash
mkdir -p /tmp/wazuh-project01-tests

tar -xzf /tmp/wazuh-project01-tests.tar.gz \
  -C /tmp/wazuh-project01-tests

sudo python3 \
  /tmp/wazuh-project01-tests/tests/regression/test_ssh_rules.py
```

The fast suite is expected to contain 17 cases.

Run time-window tests separately:

```bash
sudo python3 \
  /tmp/wazuh-project01-tests/tests/regression/test_ssh_rules.py \
  --include-slow
```

The slow suite deliberately uses real delays to test correlation windows.
It can take more than 20 minutes. Do not interrupt it and subsequently
report the incomplete run as PASS.

### What the test layers prove

| Test type | What it proves |
|---|---|
| XML parsing | XML files are syntactically well formed |
| `wazuh-analysisd -t` | Manager analysis configuration passes validation |
| `wazuh-logtest` | Synthetic events match expected Wazuh rules |
| Regression runner | Configured positive, negative and boundary cases behave as expected |
| Live SSH test | Actual SSH activity is ingested by Wazuh |
| Active Response test | The configured response executes and changes actual firewall state |

`wazuh-logtest` does not execute Active Response, create an SSH
connection or prove firewall blocking.

## 8. Controlled Attack Simulation

The simulation script is intended only for the isolated lab.

Example preparation on Fedora:

```bash
export UBUNTU_AGENT_IP=192.168.122.208
export SSH_TEST_USER=<dedicated-existing-lab-user>

head -n 5 tests/wordlists/invalid-10.txt \
  > /tmp/wazuh-invalid-5.txt

./scripts/attack_simulation.sh /tmp/wazuh-invalid-5.txt
```

Use an existing dedicated non-privileged test account.
Do not store real passwords or credentials in this repository.

The script validates the target IP and restricts it to the expected
victim and configured lab subnet. It uses Hydra with one task at a time.

## 9. Firewall Inspection

`scripts/inspect_firewall.sh` is a read-only diagnostic helper.

Run it on `my-agent` after a controlled Active Response test:

```bash
sudo ./scripts/inspect_firewall.sh 192.168.122.112
```

It does not remove firewall rules.

Do not use broad firewall flush commands. Do not remove a rule until
the exact chain, rule and relationship to Wazuh `firewall-drop`
have been verified on the Agent.

## 10. Repository Structure

```text
01-ssh-brute-force/
├── .gitignore
├── README.md
├── architecture/
│   ├── architecture.md
│   └── detection-flow.md
├── evidence/
│   └── README.md
├── reports/
│   └── test-results.md
├── scripts/
│   ├── attack_simulation.sh
│   └── inspect_firewall.sh
├── tests/
│   ├── boundary/
│   ├── negative/
│   ├── positive/
│   ├── regression/
│   │   ├── expected-results.md
│   │   └── test_ssh_rules.py
│   └── wordlists/
│       └── invalid-10.txt
└── wazuh/
    ├── configs/
    │   ├── active-response.xml
    │   └── global-whitelist.xml
    └── rules/
        └── ssh_brute_force_rules.xml
```

## 11. Limitations and Current Status

- The trusted-source exclusion uses a static IP address.
- Rule thresholds and time windows are tuned for this lab topology.
- Active Response is configured for local execution on the Agent.
- Live firewall enforcement remains unverified.
- Time-window tests require real elapsed time.
- Old screenshots from previous deployments are not accepted as
  evidence of the current deployment.
- The project remains IN PROGRESS until live scenarios and
  Active Response are verified and documented.

## 12. Evidence

See [Evidence Register](evidence/README.md).

Only current, sanitized evidence from the Wazuh 4.14.10 deployment
should be committed.

## 13. Related Project

[Project 00 — Wazuh Installation and Agent Deployment](../00-wazuh-installation-and-agent-deployment/README.md)

Project 00 documents the platform. Project 01 documents the SSH
detection and response scenario.
