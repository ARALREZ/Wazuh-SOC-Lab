# Architecture — SSH Brute Force Detection & Active Response

## 1. Objective

Detect SSH brute-force attacks, password spraying, failed public-key
authentication and successful authentication following brute-force
activity. Apply automated IP containment through Wazuh Active Response
for the configured critical detection rules.

## 2. Lab Topology

| Host | Role | IP address |
|---|---|---|
| Kali | Authorized attacker / test host | `192.168.122.112` |
| my-agent | Ubuntu 24.04.5 LTS, Wazuh Agent | `192.168.122.208` |
| my-server | Ubuntu 24.04.5 LTS, Wazuh Manager | `192.168.122.178` |
| Fedora | Administration / trusted source | `192.168.122.1` as seen by Agent |

The Fedora address in the table is the source IP observed by the
Agent during SSH communication. The Fedora host's other observed
address (`172.16.62.231`) must not be substituted into the rule
without a new network verification.

## 3. Event and Detection Flow

```text
Kali (192.168.122.112)
        |
        | SSH authentication attempts
        v
my-agent (192.168.122.208)
        |
        | systemd journal / SSH events
        | Wazuh Agent -> TCP 1514
        v
my-server (192.168.122.178)
        |
        | Default SSH rules
        | Custom Project 01 rules
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
        +--> Active Response for 100002 and 100005
                    |
                    v
              my-agent firewall
```

## 4. Log Collection

SSH events are collected from journald on `my-agent` and forwarded
to the Manager over TCP port 1514.

Do not configure `/var/log/auth.log` as a second source without
first checking whether it would duplicate journald events.

## 5. Rule Configuration

Source file in the repository:

`wazuh/rules/ssh_brute_force_rules.xml`

Deployed file on the Manager:

`/var/ossec/etc/rules/ssh_brute_force_rules.xml`

The Manager loads it through the configured `etc/rules` rule directory.
It is maintained separately from `local_rules.xml`.

## 6. Active Response

The Manager configuration contains separate Active Response
blocks for:

| Rule | Command | Location | Timeout |
|---|---|---|---:|
| 100002 | firewall-drop | Local Agent | 600 seconds |
| 100005 | firewall-drop | Local Agent | 600 seconds |

Rules 100001, 100003, 100004 and 100010 do not initiate
firewall-drop.

The trusted source `192.168.122.1` is excluded from the brute-force
and password-spraying detection and is included in the Manager's
Active Response whitelist.

Configuration validation does not prove that a live firewall block
has occurred. Live Active Response remains unverified until a
controlled test confirms the execution log and actual firewall state.

## 7. Validation Layers

1. XML syntax and Wazuh configuration validation.
2. Individual rule tests using `wazuh-logtest`.
3. Fast positive and negative regression tests.
4. Time-window boundary tests.
5. Controlled live SSH tests from Kali.
6. Active Response execution and firewall verification.

`wazuh-logtest` uses synthetic events. It does not simulate a live
SSH connection or prove actual firewall enforcement.
