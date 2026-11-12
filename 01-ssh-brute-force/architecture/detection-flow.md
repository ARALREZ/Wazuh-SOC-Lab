# Detection Flow — SSH Brute Force

## 1. Event Collection

The monitored endpoint is `my-agent` (`192.168.122.208`).

SSH authentication events are collected from `journald` by the
Wazuh Agent and forwarded to `my-server` (`192.168.122.178`)
over TCP/1514.

The deployment already collects SSH events through journald.
Do not add `/var/log/auth.log` as a duplicate input without
first verifying the actual collection configuration.

## 2. Default Wazuh SSH Rules

| Rule ID | Event type |
|---|---|
| 5715 | Successful SSH authentication |
| 5716 | SSH authentication failure / public-key failure parent |
| 5760 | Failed password / keyboard-interactive authentication |

The exact decoded fields must be checked against the event in
`wazuh-logtest`; do not assume every SSH failure has the same decoder
or base rule.

## 3. Custom Rule Evaluation

| Custom ID | Description | Level | Detection logic |
|---|---|---:|---|
| 100010 | Trusted IP | 3 | Base rule 5760 from `192.168.122.1` |
| 100001 | SSH Soft Detection | 6 | 3 matched 5760 failures from same source within 120 s |
| 100002 | SSH Brute Force | 10 | `frequency=4`, `timeframe=120`, same source IP |
| 100003 | Failed Public Key | 6 | Parent 5716 and `Failed publickey` match |
| 100004 | Password Spraying | 10 | 5 failed events, same source IP, different usernames within 300 s |
| 100005 | Successful Login After Brute Force | 14 | Successful login correlated with 100001 activity; same source IP and username within 300 s |

### Rule 100002 threshold behavior

The third failed-password event triggers 100001. In the verified
five-attempt sequence, the third event is no longer emitted as 5760
for subsequent custom-rule correlation.

Therefore, `100002` currently uses `frequency=4` and triggers on
the fifth attempt in the tested sequence.

### Trusted source handling

The trusted source address is `192.168.122.1`, the address observed
by the Agent for Fedora-originated SSH traffic.

Rule 100010 is evaluated for that source. It is excluded from
the brute-force and password-spraying rules.

## 4. Active Response

Manager configuration contains two separate response blocks:

| Trigger | Command | Location | Timeout |
|---|---|---|---:|
| 100002 | `firewall-drop` | `local` | 600 seconds |
| 100005 | `firewall-drop` | `local` | 600 seconds |

The response is intended to execute on the Agent associated with
the triggering alert.

No response is configured for 100001, 100003, 100004 or 100010.

Live enforcement remains unverified until the Agent execution log,
firewall state and a controlled connection attempt demonstrate
that the attacker IP was blocked.

## 5. Validation Layers

1. Parse XML files locally.
2. Validate the Manager rules and Active Response configuration.
3. Use `wazuh-logtest` for individual synthetic events.
4. Run the 17-case fast regression suite.
5. Run all 6 slow time-window tests with real delays.
6. Perform controlled SSH scenarios from Kali.
7. Verify Active Response and actual firewall behavior on the Agent.

`wazuh-logtest` validates rule matching only. It does not perform
network authentication, execute the response or change firewall state.

## 6. Related Files

- Rules: `wazuh/rules/ssh_brute_force_rules.xml`
- Active Response reference: `wazuh/configs/active-response.xml`
- Whitelist fragment: `wazuh/configs/global-whitelist.xml`
- Regression runner: `tests/regression/test_ssh_rules.py`
- Expected results: `tests/regression/expected-results.md`
- Actual results: `reports/test-results.md`
- Evidence register: `evidence/README.md`

