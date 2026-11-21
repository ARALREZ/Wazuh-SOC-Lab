# Detection Flow — SSH Authentication Attacks

## 1. Collection path

The monitored endpoint is `my-agent` (`192.168.122.208`). SSH authentication events are collected from `journald` by the Wazuh Agent and forwarded to `my-server` (`192.168.122.178`) over TCP/1514.

The current lab uses journald for the relevant SSH events. Do not add `/var/log/auth.log` as a second input until the live Agent configuration has been checked for duplicate collection.

## 2. Relevant built-in rules

| Rule ID | Role in this project |
|---|---|
| `5715` | Successful SSH authentication event family used by the current Wazuh ruleset |
| `5716` | SSH authentication failure parent used for public-key failure matching |
| `5760` | Failed password / keyboard-interactive authentication parent used by the password-failure correlations |

Verify the decoded event and parent rule for any new SSH message with `wazuh-logtest`. Not all authentication failures necessarily follow the same decoder path.

## 3. Custom rule evaluation

| Custom ID | Level | Detection | Conditions in the project XML |
|---|---:|---|---|
| `100010` | 3 | Trusted-source failure | Parent `5760`; source `192.168.122.1` |
| `100001` | 6 | Soft brute-force signal | Three matches of `5760` from the same source within 120 seconds; excludes `192.168.122.1` |
| `100002` | 10 | Brute force | Four matched `5760` events within 120 seconds, same source IP and same username; excludes trusted source |
| `100003` | 6 | Failed public-key authentication | Parent `5716` and `Failed publickey` message match |
| `100004` | 10 | Password spraying | Four matched `5760` events within 300 seconds, same source IP and different usernames; excludes trusted source |
| `100005` | 14 | Successful login after failed authentication | Current event is in `authentication_success`; prior event matches are in `authentication_failed`; same source IP and username within 300 seconds; excludes trusted source |

### 3.1 Observed brute-force threshold

With the current loaded rule tree and the five-failure positive fixture, the observed sequence is:

| Attempt | Expected custom result |
|---:|---|
| 1 | None |
| 2 | None |
| 3 | `100001` |
| 4 | None |
| 5 | `100002` |

This observed fifth-attempt behavior results from the interaction between the soft-detection rule and the base `5760` events. It is specific to the tested ruleset and must be rechecked after a Wazuh upgrade or rule change.

### 3.2 Rule 100005 correlation semantics

Rule `100005` is not configured as a direct child of `100001`. It uses:

- `if_group=authentication_success` for the event being evaluated;
- `if_matched_group=authentication_failed` for prior authentication failures;
- `same_srcip` and `same_user` to constrain the correlation;
- `frequency=3` and `timeframe=300`;
- an exclusion for the trusted source.

The positive regression fixtures expect `100005` to trigger on the successful authentication event. A failed-login alert alone does not prove account compromise.

## 4. Trusted source

The trusted source is `192.168.122.1`, the address observed by the Agent for Fedora-originated SSH traffic in this network. Rule `100010` labels matching parent `5760` events at level 3. The attack-correlation rules also explicitly exclude this address.

`wazuh/configs/global-whitelist.xml` contains a fragment for the existing Manager `<global>` whitelist. Merge the element into the existing section; do not replace that section.

## 5. Active Response

The Manager reference configuration invokes Wazuh's built-in `firewall-drop` command for:

| Trigger rule | Location | Timeout |
|---|---|---:|
| `100002` | `local` | 600 seconds |
| `100005` | `local` | 600 seconds |

`local` means the endpoint associated with the alert. In this scenario the expected enforcement point is `my-agent`.

Rules `100001`, `100003`, `100004` and `100010` do not trigger firewall blocking.

## 6. Validation sequence

1. Parse the project XML and validate the Manager rule configuration.
2. Validate the Active Response configuration using the appropriate Wazuh validation command.
3. Use `wazuh-logtest` for individual fixtures and regression cases.
4. Run the fast suite (17 cases).
5. Run the full suite with the delayed cases included (17 fast + 6 slow).
6. Run live SSH tests from Kali against the dedicated lab endpoint.
7. Correlate the Manager alert, Agent Active Response log, firewall state and Kali connection result.
8. Wait for the configured timeout and verify the automatic delete and restored SSH connectivity.

The runner's commands are:

```bash
python3 tests/regression/test_ssh_rules.py
python3 tests/regression/test_ssh_rules.py --include-slow
```

The second command runs all 23 cases, including the fast cases again. The runner does not expose a slow-only option.

`wazuh-logtest` is a rule-matching tool. It does not test real SSH, Active Response execution or firewall behavior.

## 7. Related files

- Rules: `wazuh/rules/ssh_brute_force_rules.xml`
- Active Response: `wazuh/configs/active-response.xml`
- Whitelist fragment: `wazuh/configs/global-whitelist.xml`
- Regression runner: `tests/regression/test_ssh_rules.py`
- Expected outcomes: `tests/regression/expected-results.md`
- Recorded results: `reports/test-results.md`
- Screenshot register: `evidence/README.md`
