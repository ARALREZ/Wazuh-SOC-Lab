# SSH Brute Force — Expected Regression Results

**Target Wazuh baseline:** `4.14.10-1`\
**Manager:** `192.168.122.178`\
**Agent:** `192.168.122.208`\
**Kali test source:** `192.168.122.112`\
**Trusted source:** `192.168.122.1`

This file defines expected behavior for the current fixtures and rule file. It is not evidence that a test has been executed. Record observed results, date and environment in `reports/test-results.md` only after reviewing the runner output.

## 1. Expected custom rule levels

| Rule ID | Level | Meaning |
|---|---:|---|
| `100001` | 6 | SSH soft detection |
| `100002` | 10 | SSH brute force |
| `100003` | 6 | Failed public-key authentication |
| `100004` | 10 | Password spraying |
| `100005` | 14 | Successful login correlated with failed authentication |
| `100010` | 3 | Trusted-source failure |

## 2. Positive scenarios

| Fixture | Expected custom behavior |
|---|---|
| `positive/brute-force-3fails.log` | `100001` on the third failed-password event |
| `positive/brute-force-5fails.log` | `100001` on event 3 and `100002` on event 5 |
| `positive/brute-force-10fails.log` | Both `100001` and `100002` appear; no unrelated custom rule |
| `positive/brute-force-success-after-3fails.log` | `100001` on event 3 and `100005` on the successful event |
| `positive/brute-force-success-after-5fails.log` | `100001`, `100002`, then `100005` on the successful event |
| `positive/brute-force-success-after-8fails.log` | `100001`, `100002`, then `100005` on the successful event |
| `positive/password-spray-5users.log` | `100004` on the fifth distinct-user event within the configured window |
| `positive/publickey-failure.log` | `100003` |

## 3. Negative and boundary scenarios

| Fixture | Expected custom behavior |
|---|---|
| `negative/normal-failed-login.log` | Two failed logins do not trigger a custom rule |
| `boundary/brute-force-2fails.log` | No custom rule |
| `boundary/brute-force-4fails.log` | `100001` only; no `100002` |
| `negative/normal-successful-login.log` | No custom rule |
| `negative/different-user-success.log` | Earlier soft detection may be present; `100005` must not trigger for a different username |
| `negative/different-source-success.log` | Earlier soft detection may be present; `100005` must not trigger for a different source IP |
| `negative/mixed-users-failed-login.log` | No password-spraying rule; only the explicitly allowed soft detection may appear |
| `negative/mixed-sources-failed-login.log` | No cross-source correlation |
| `negative/trusted-admin-failed-login.log` | `100010` only |
| `boundary/success-after-2-fails.log` | No `100005` |
| `boundary/five-fails-outside-120s.log` | No brute-force correlation `100002` |
| `boundary/password-spray-4users.log` | No `100004` |
| `boundary/password-spray-one-user.log` | No `100004` |
| `negative/slow-failed-login.log` | No `100001` when the events fall outside the 120-second window |
| `boundary/success-after-300s.log` | No `100005` after the correlation window expires |

## 4. Five-failure plus success sequence

For `positive/brute-force-success-after-5fails.log`, the expected per-event rule sequence is:

| Event | Expected rule | Level |
|---:|---|---:|
| 1 | Built-in `5760` | 5 |
| 2 | Built-in `5760` | 5 |
| 3 | Custom `100001` | 6 |
| 4 | Built-in `5760` | 5 |
| 5 | Custom `100002` | 10 |
| 6 | Custom `100005` on successful authentication | 14 |

Rule `100005` is configured with group-based correlation (`authentication_success` plus prior `authentication_failed` matches), not as a direct dependency on rule `100001`.

The exact event sequence is specific to the current rules and Wazuh baseline. A ruleset or version change requires a fresh regression run.

## 5. Test-suite inventory and execution

The current `tests/regression/test_ssh_rules.py` defines:

- **17 fast cases** — positive, negative and boundary scenarios;
- **6 slow cases** — cases that require real delays to validate correlation-window expiry or multi-user spraying behavior.

Run the fast cases:

```bash
python3 tests/regression/test_ssh_rules.py
```

Run all cases, including the six slow cases:

```bash
python3 tests/regression/test_ssh_rules.py --include-slow
```

Important: `--include-slow` runs the 17 fast cases again and appends the 6 slow cases. It executes 23 cases in total; the runner does not offer a slow-only mode. Do not remove the deliberate delays from the slow test definitions. Sending all fixture lines immediately would not validate real elapsed-time windows.

Run the tests on the Wazuh Manager where `/var/ossec/bin/wazuh-logtest` exists. The runner checks that path and exits if it is missing.

## 6. Active Response is validated separately

| Trigger rule | Expected response | Timeout |
|---|---|---:|
| `100002` | `firewall-drop` on the endpoint associated with the alert | 600 seconds |
| `100005` | `firewall-drop` on the endpoint associated with the alert | 600 seconds |

The regression runner validates rule matches only. It does not prove that the response ran or that the firewall blocked traffic.

For each live response test, correlate the Manager alert, Agent `add` log, actual firewall DROP, blocked new connection from Kali, automatic Agent `delete` log and successful new connection after the timeout.
